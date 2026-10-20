# GramHealth Frontend Rebuild — 04 / Offline Chatbot — Replicate Bit-for-Bit

> **Build this last, after the fresh UI and backend wiring are done. When finished, offline answers must be identical to the existing build for the same query.**
> Every value below is taken from the current codebase (`lib/config/offline_ai_config.dart`, `lib/services/*offline*`, `lib/services/local_*`, `lib/models/*`, `lib/repositories/offline_medical_repository.dart`, `lib/android/ GramhealthLlmPlugin.kt`, `assets/offline_medical/`) read on 2026-10-16.

---

## 1. What the feature is (and isn't)

*GramHealth stays clinically useful when there is no signal.* The on-device stack answers health questions **without ever calling the network**, by routing every query through a **deterministic emergency detector → curated medical lexicon → optional local small LLM**, with hard post-generation sanitising and a single branded disclaimer. The LLM is a **progressive fallback, not the primary safety mechanism** — emergencies never reach it.

**Hard invariants to preserve:**
- No network call in offline path. No Gemini/GRAG leak. `gramhealth/offline_llm` channel only.
- Every medical output ends with `ClinicalResponse.standardDisclaimer`. Never omit it.
- `OfflineSafetyService` is authoritative; the LLM prompt explicitly forbids overriding it.
- Language: symptom matching is multilingual (en + hi/mr transliterations), response body is currently English (patient-facing future is locale-aware via translation table — keep English default for rebuild).

---

## 2. Pipeline Overview

```
User query (any screen: ChatBot OR SymptomChecker Analyze)
                │
                ▼
   Off-line vs on-line decision lives in AiService.query (see doc 03 §5)
   Online attempt first: POST {liveBackendUrl}/api/ai/query (120s)
      401/403 ──► throw, never fallback
      200       ──► AiResponse from Python RAG (done)
      502/503/504 or Socket/Timeout ──► isNetworkOrBackendUnavailable=true ──► offline branch
                                              │
                                              ▼
                               OfflineAiService.instance.initialise()    (idempotent)
                               OfflineAiService.queryOffline(query)  OR
                               OfflineAiService.isEmergency(query) + buildEmergencyResponse(query)
                                              │
                                              ▼
                               ┌──────────────────────────────┐
                               │        OfflineAiRouter        │  router.route(query) → OfflineRoutingResult
                               │                               │
                  LEVEL 2      │  OfflineSafetyService         │──► if emergencyTerms non-empty
                               │     matchedEmergencyTerms()    │    return Stream.value(emergency Text)
                               │     buildEmergencyResponse()  │    agent=offline_ai_router, offlineText, urgency=emergency
                               │                               │
                  LEVEL 3      │  OfflineMedicalLookupService  │──► search(query) → up to 3 entries
                               │     + LocalModelManager/      │    if entries + isModelReady(loaded/generating)
                               │       LocalLlmService ready?  │    then context=_buildContext(entries)
                               │                               │         prompt = 'USER QUERY:\n$query\n\nOFFLINE MEDICAL CONTEXT:\n$context'
                               │                               │         stream = llmService.generate(prompt, systemPrompt:_kSystemPrompt)
                               │                               │                 .map(sanitiseGeneratedText)
                               │                               │    decision=medicalLexiconPlusLlm, isStreaming=true
                               │                               │
                  LEVEL 4      │  lexiconOnly                  │──► entries non-empty but LLM not ready
                               │     _buildLexiconOnlyResult() │    sb = header 'This is NOT a diagnosis...' + per entry:
                               │                               │         '--- {condition} ---'
                               │                               │         'Warning signs: {3} ...'
                               │                               │         entry.generalInformation
                               │                               │         'When to seek care: {whenToSeekCare}'
                               │                               │    Stream.value(sb.trim())
                               │                               │    decision=lexiconOnly
                               │                               │
                  LEVEL 5      │  unsupported/unavailable      │──► no entries:
                               │                               │    if modelStatus==unavailable  → OfflineResponse.unavailable()
                               │                               │        'Offline AI is not available on this device. Please use GramHealth online for medical questions.'
                               │                               │    else                        → OfflineResponse.noInformation()
                               │                               │        'The offline assistant does not have specific information about this topic. For medical questions, please consult...'
                               │                               │    each carries ClinicalResponse.offlineUnknown(query) as structuredResponse
                               └──────────────────────────────┘
                                              │
                                              ▼
                               AiService wraps offlineText as AiResponse(
                                 query, intent: emergency?emergency:offline_medical, agent: offline_ai_router,
                                 answer: offlineText, grounded:true, confidence:medium,
                                 urgency: emergency?emergency:routine, requiresProfessionalReview:true,
                                 routingMethod: offline_ai_safety_and_lexicon)
                               ChatBot prefixes: '🚨 EMERGENCY 🚨\n' if urgency==emergency else '⚠️ Please consult a professional.\n' if requiresProfessionalReview
                                              │
                                              ▼
                               Rendered:
                                 ChatBot: Message(sender:ai, text=responseText, isOffline=agent==offline_ai_router||routingMethod.contains(offline))
                                 SymptomChecker: either emergency SymptomResult / StructuredClinicalResponseCard mismatch
```

`OfflineAiRouter._kSystemPrompt` is the exact string the new build must reuse (verbatim) — see §7.

---

## 3. Model — Qwen2.5-0.5B-Instruct via LiteRT-LM (MediaPipe tasks-genai)

### 3.1 Registry (`lib/config/offline_ai_config.dart:6-41`)

```dart
static const String modelRepoId   = 'litert-community/Qwen2.5-0.5B-Instruct';
static const String modelFilename = 'Qwen2.5-0.5B-Instruct_seq128_q8_ekv1280.tflite'; // actual file on HuggingFace + on-disk name
static const String modelDownloadUrl =
    'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_seq128_q8_ekv1280.tflite';
static const int    modelExpectedSizeBytes = 513219800;    // ~489 MB (~513,219,800 bytes); size gate ±10% before SHA check
static const String modelSha256  = '49b3b9ca95c46b185995edeb7314dec06c23f65d7a8c7b24ee97d5313e6032ac';
static const String modelVersion = '1.0.0';
static const String modelLicense = 'Apache-2.0';
static const String offlineModelId = 'qwen2.5-0.5b-litert-q8';  // used when persisting metadata (local_model_manager:469)
```

Placeholders note in file header: verify `filename, size, sha256` against the HuggingFace model card before release via `docs/verify_model.sh` (hook enforced but not shipped). For rebuild, keep these values; if you update to a newer quantized LiteRT build, recompute sha and size and bump `modelVersion`.

### 3.2 Storage & Lifecycle

```
download target:  ${getApplicationDocumentsDirectory()}/$modelFilename
tmp during download:  $target.tmp   (range-append mode; atomic rename on complete)
verify: size ±10% of expected then sha256 via crypto (package:crypto + convert) — computeSha256(filePath) streams the file
metadata persisted (SharedPreferences + sqflite not, prefs only):
  OfflineModelMetadata(
    modelId:   qwen2.5-0.5b-litert-q8
    version:  modelVersion
    filename: modelFilename
    sha256:   modelSha256
    sizeBytes: modelExpectedSizeBytes
    downloadUrl, license
    downloadedAt: now.toIso8601 on verification
    verified: true
  ).toJsonString() stored under  key gramhealth_offline_model_meta
  also mirrored: prefsModelVersion, prefsModelSha256, prefsModelPath, prefsExpectedSizeBytes,
                 prefsDownloadedBytes (int), prefsDownloadProgress (double 0..1),
                 prefsLastSuccessfulVerification (ISO8601), prefsLastDownloadAttempt (ISO8601)
```

State machine (`lib/models/local_model_status.dart:7-50` + `lib/services/local_model_manager.dart:22`):

```
unavailable → checking → {pending|downloading} → verifying → ready → loading → loaded ↔ generating
                                                      ↓
                                                   lexiconOnly (hard-safe or incompatible)
                                                      ↓ (any path) → error → pending
```

Aliases used in UI: `lexiconOnly` = “Offline AI • Knowledge mode”; `generating` = “Offline AI • Thinking” (`local_model_status:88-90`).

On-disk file, once `verified==true` and `version==modelVersion`, is considered ready without re-hashing on every cold start (`local_model_manager:104`).

### 3.3 Runtime Flags (`offline_ai_config:62-112`)

```dart
static const bool   enableLocalLlmRuntime = false;   // *** HARD SAFE MODE — currently FALSE in shipped build ***
static const bool   runNativeSmokeTest    = false;
static const String preferredBackend      = 'cpu';     // Qwen dynamic_int8 targets CPU — never GPU
static const String tasksGenaiVersion     = '0.10.14';

static const int    minFreeStorageBytes   = 700_000_000;   // 700 MB (model + 20% headroom)
static const int    minAvailableRamBytes  = 1_500_000_000; // 1.5 GB
static const int    minAndroidApiLevel    = 26;            // Android 8.0

// Generation (when runtime is enabled)
static const int    maxNewTokens    = 400;
static const double temperature     = 0.2;   // deliberately conservative for medical
static const double topP            = 0.9;
static const int    topK            = 40;
static const int    offlineContextMaxCharacters = 1500;
static const int    offlineMaxEntries           = 3;
static const int    offlineMaxPromptTokens      = 1024;    // well under Qwen 32k window
static const int    shardCacheMaxSize           = 4;       // LRU of decompressed shard JSON

// Download / network
static const bool   autoDownloadOfflineModel  = true;
static const bool   allowMobileDataDownload   = false;     // must be Wi-Fi/Ethernet
static const Duration downloadChunkTimeout    = Duration(seconds:30);
static const int    downloadChunkBytes        = 4*1024*1024;
static const int    maxDownloadRetries        = 3;
static const Duration onlineRequestTimeout    = Duration(seconds:15); // unused direct, 120s is real
static const bool   enableDiagnostics         = true;      // print([Offline*]) logs; never log PII

// Lexicon assets
static const String lexiconAssetBase     = 'assets/offline_medical';
static const String lexiconManifestPath  = '$lexiconAssetBase/manifest.json';
static const String lexiconMetadataPath  = '$lexiconAssetBase/metadata.json';
static const String lexiconShardsPath    = '$lexiconAssetBase/shards';

// SharedPreferences namespacing (all keys prefixed gramhealth_offline_...)
prefsModelMetadata, prefsDownloadProgress, prefsDownloadedBytes, prefsLastDownloadAttempt,
prefsLastSuccessfulVerification, prefsModelPath, prefsModelSha256, prefsModelVersion, prefsExpectedSizeBytes
```

**Hard safe mode consequence:** because `enableLocalLlmRuntime == false` in the inspected build, **every startup that would transition `ready → loaded` is intercepted**:

- `LocalModelManager.checkModelOnStartup` when it finds a verified model on disk → directly sets `lexiconOnly` (“Offline AI • Knowledge mode”) instead of `ready` (`local_model_manager:110,131-135,271-275`).
- `LocalModelManager.loadModel` early-returns as `lexiconOnly` and never calls `llmService.initialize` (`330-340`).
- `OfflineAiRouter.route` computes `isModelReady = enableLocalLlmRuntime && status in {loaded,generating}` (`59`); therefore `false` always, so **LEVEL 3 (Lexicon+LLM) is never entered** — all non-emergency medical queries fall to **LEVEL 4 lexiconOnly**.
- `OfflineAiService.ensureModelLoaded` also early-returns (`113`).

Rebuild implication: if you reproduce with `enableLocalLlmRuntime = false`, you reproduce exactly today's behaviour (offline answers are deterministic lexicon cards, no generation). If you flip it to `true` you enter the LLM path — do so only after smoke-testing the `.tflite` on a low-end device (Samsung M12 is the reference target in comments).

---

## 4. Download Service (`lib/services/local_model_download_service.dart`)

```dart
LocalModelDownloadService.download({required url, required destinationPath, required expectedSizeBytes, ProgressCallback? onProgress})
  tmp = File('$destinationPath.tmp')
  startByte = tmp.exists ? tmp.length : 0
    if startByte >= expectedSizeBytes: delete tmp, reset to 0
    else log 'Resuming from byte $startByte'

  retry loop up to maxDownloadRetries:
    http.Client.send(http.Request GET url, headers {Range: 'bytes=$startByte-'} if startByte>0) .timeout(downloadChunkTimeout)
    on 416 (Range Not Satisfiable): delete tmp, throw DownloadHttpException('HTTP 416 ...')
    on 200|206 only else throw
    isRange = status==206; total = isRange ? (contentLength ?? 0)+startByte : (contentLength ?? expectedTotal)
    received = isRange ? startByte : 0
    openWrite(tmpFile, mode: isRange? append : write)
    for chunk in response.stream:
      if _cancelled → close sink, throw DownloadCancelledException
      sink.add(chunk); received+=chunk.length; onProgress(received, total>0? total: expectedTotal)
    finally flush+close

  if _cancelled → throw
  await tmpFile.rename(destinationPath)   // atomic — no two-phase commit

  getDownloadedBytes(destinationPath) → tmp exists? tmp.length : final exists? final.length : 0
  cancel()                         → _cancelled=true; active sink/stream will abort on next chunk
  computeSha256(filePath)          → AccumulatorSink<Digest>(sha256.startChunkedConversion) over file.openRead() → hex
```

Resumed via HTTP `Range`. Retries on `SocketException`/`HttpException` with `delay 2*retry seconds` and refreshed `startByte = tmp.length`. `progress` is persisted to prefs as both `downloadedBytes` and `downloadProgress` (`0..1`) on every chunk via `LocalModelManager._persistProgress`. Progress `Stream<LocalModelStatus>` is nudged with `statusController.add(_status)` per chunk so `OfflineSetupCard` animates.

### Auto-download Gating (`LocalModelManager.checkModelOnStartup & checkNetworkAndTriggerDownload`)

```
checkModelOnStartup({autoDownload=true}):
  set status=checking, statusReason='Checking offline AI status...'
  1. compatibility = await llmService.checkCompatibility()  // native check (Kotlin)
     if !canDownload (supported && abi && storage): set unavailable + error 'Device not eligible...' → return
  2. load persisted OfflineModelMetadata; expectedPath = docsDir/modelFilename
     downloadedBytes = getDownloadedBytes(expectedPath) from tmp; progress = downloadedBytes/expectedSize
  3. if final file exists && metadata.version==modelVersion && verified:
       if !enableLocalLlmRuntime → status=lexiconOnly, reason 'Offline AI • Knowledge mode' → return
       else → status=ready → return
     else if file exists but needs verification:
       status=verifying; ok=await _verifyFile(file) // size±10% + sha256 if configured
       if ok → persist metadata verified:true; if !enable flag → lexiconOnly else ready
       else → delete corrupted file
  4. if not autoDownload or !autoDownloadOfflineModel → unavailable; return
     await checkNetworkAndTriggerDownload()

checkNetworkAndTriggerDownload():
  guard status not in {downloading,ready,loaded,generating}
  if !Connectivity.isOnline → status=pending 'Download pending — waiting for connection' + listenForConnectivityChanges() → return
  if !isWifiOrEthernet() && isMobileData() && !allowMobileDataDownload → pending 'Offline AI download waiting for Wi-Fi' + listen → return
  else → startDownload()

startDownload():
  gate canDownload via compatibility
  status=downloading; lastError=null
  prefs.lastDownloadAttempt=now
  await download(url:modelDownloadUrl, destinationPath:expectedPath, expectedSizeBytes, onProgress: update _downloadedBytes/_expectedBytes/_downloadProgress, persistProgress, nudge statusController)
  status=verifying 'Verifying model integrity...'  + verify file (size±10% + sha)
  if fail: delete file → status=error + error 'Checksum verification failed...' → _handleDownloadFailure(verification)
  else: metadata=OfflineModelMetadata(qwen..., verified:true) persisted; if !flag → lexiconOnly else ready
  on DownloadCancelledException → status=pending 'Download paused'
  on other error → _handleDownloadFailure(error)
  _handleDownloadFailure: retryCount < maxDownloadRetries → pending 'Retry pending (attempt n/3 in 2n s)...' + Timer(2*n s) → checkNetworkAndTriggerDownload(); else error 'Download paused after n attempts.' statusReason '... Will retry when connection refreshes' + listen
  listenForConnectivityChanges: subscribe to Connectivity.statusStream; on online while status in {pending,error}: reset retryCount=0 + unawaited(checkNetworkAndTriggerDownload)
```

`loadModel()` (lazy, invoked by ChatBot `ensureModelLoaded()` and SymptomChecker fallback path only when runtime enabled):

```
loadModel():
  if !enableLocalLlmRuntime → lexiconOnly + return
  re-check compatibility; if !canLoad (adds memory+nativeRuntime checks): error 'Device memory insufficient...' → lexiconOnly
  if status != ready → log + return
  status=loading → await llmService.initialize(modelPath: _modelPath!)  // MethodChannel gramhealth/offline_llm initialize
  on success → status=loaded
  on failure → status=lexiconOnly + lastError + reason 'Offline AI • Knowledge mode (Native engine unavailable)'
```

---

## 5. Native Runtime — `GramhealthLlmPlugin.kt` (Android only)

**Channels:** `MethodChannel('gramhealth/offline_llm')`, `EventChannel('gramhealth/offline_llm_tokens')`.

**Dependency:** `com.google.mediapipe:tasks-genai:0.10.14` (MediaPipe `LlmInference`, loaded via reflection `Class.forName("com.google.mediapipe.tasks.genai.llminference.LlmInference")` so absence yields `LLM_DEPENDENCY_MISSING` instead of crash).

**Compatibility report (`checkCompatibility` result keys → Dart `LocalModelCompatibility.fromMap`):**

```kotlin
handleCompatibility(): success map {
  supported:               apiSupported && abi==arm64-v8a   // apiLevel ≥ 26
  enoughStorage:           availableBlocks*blockSize >= 700 MB (StatFs on filesDir)
  enoughMemory:            ActivityManager.MemoryInfo.availMem >= 1.5 GB
  supportedAbi:            Build.SUPPORTED_ABIS contains arm64-v8a
  nativeRuntimeSupported:  Class.forName(LlmInference) succeeds
  modelFormatSupported:    true
  runtimeVersionSupported: true
  backendSupported:        true
  smokeTestPassed:         false
  manufacturer, deviceModel, apiLevel, abi (first), availableRam, totalRam, availableStorage, runtimeVersion "0.10.14",
  selectedBackend "cpu",
  reason: first failure in {apiSupported; supportedAbi; enoughStorage; enoughMemory; nativeRuntimeSupported} else null
}
```
Dart computes:
```dart
canDownload        => supported && supportedAbi && enoughStorage
canLoad            => supported && enoughStorage && enoughMemory && supportedAbi && nativeRuntimeSupported && modelFormatSupported && runtimeVersionSupported && backendSupported
isReadyForGeneration => canLoad && smokeTestPassed
```

**Initialize (`initialize` call, Dart `LiteRtLmService.initialize`):**
```kotlin
args: modelPath: String, maxTokens: Int=400, temperature: Double=0.2, topK: Int=40
  checks Platform.isAndroid else throw UnsupportedError
  logs device: MANUFACTURER MODEL SDK ABI, RAM avail/total, modelPath size
  reflect LlmInference + LlmInferenceOptions + Builder
  Builder().setModelPath(modelPath).setMaxTokens(maxTokens).setTemperature(temp as Float).setTopK(topK)
  try setPreferredBackend(CPU) via LlmInference.Backend.CPU (reflection, non-fatal)
  LlmInference.createFromOptions(context, options) → store llmInference: Any
  on ClassNotFoundException → error LLM_DEPENDENCY_MISSING
  on Exception → LLM_INIT_FAILED
```

**Generate (`generate` call, streamed):**
```kotlin
args: systemPrompt: String, prompt: String
  assert llmInference != null else NOT_INITIALIZED
  fullPrompt = buildQwenPrompt(systemPrompt, prompt) = "<|im_start|>system\n$system<|im_end|>\n<|im_start|>user\n$user<|im_end|>\n<|im_start|>assistant\n"
  success(null) ack immediately  // tokens arrive via EventChannel
  proxy LlmInferenceResultListener { run(partial:String, done:Boolean) { eventSink.success(partial); if done eventSink.success("__EOS__") } }
  llm.generateAsync(fullPrompt, proxy)   // generation runs off Main, coroutine scope IO+SupervisorJob
Dart consumes via _tokenChannel.receiveBroadcastStream().listen:
  on "String": if "__EOS__" → close controller + cancel sub; else controller.add(event)
  onError → LocalLlmException + close; cancelOnError:true
```

**Smoke test (`runSmokeTest`):**
Dedicated path with `maxTokens=32`, same CPU enforcement, creates isolated testLlm via `createFromOptions`, calls synchronous `generate(testPrompt)` → string response, closes instance, returns `{success:bool, response?, error?, backend:"cpu", device:"MANUFACTURER MODEL"}`. Disabled upstream (`runNativeSmokeTest==false`) — not auto-run.

**Cancel (`cancel`) / Dispose (`dispose`):** `cancel` cancels `generationJob`, emits `__EOS__`. `disposeLlm` via reflection `close()`, nullifies.

**Top-level safety:** every reflection path is try/caught; `scope = CoroutineScope(Dispatchers.IO + SupervisorJob())`, callbacks marshal to `Dispatchers.Main` before `result.success/error`.

---

## 6. Medical Lexicon — Bundled Assets (`assets/offline_medical/`)

Registered in `pubspec.yaml: assets: - assets/images/ - assets/offline_medical/manifest.json - assets/offline_medical/metadata.json - assets/offline_medical/shards/` (shards are `gzip`'d JSON; must be explicitly listed per asset).

**`metadata.json`** (read verbatim):
```json
{ "version":"1.0.0", "generatedAt":"2025-09-09", "totalConditions":19, "totalShards":12,
  "shards":["a","c","d","f","h","j","m","o","p","s","t","u"],
  "sources": [
    "WHO - Diabetes Fact Sheet", "WHO - Dengue and Severe Dengue Fact Sheet", "WHO - Typhoid Fact Sheet",
    "WHO - Tuberculosis Fact Sheet / India NTEP", "WHO - Cholera Fact Sheet", "WHO - Hypertension Fact Sheet",
    "WHO - Diarrhoeal Disease Fact Sheet", "WHO - Headache Disorders Fact Sheet", "WHO - Pneumonia Fact Sheet",
    "WHO - Snakebite Envenoming Fact Sheet", "WHO / NHM India - Anaemia Mukt Bharat", "NHS UK - Fever in Adults",
    "CDC - Common Cold", "NHS UK - Jaundice in Adults", "WHO - Malaria Fact Sheet", "WHO - Oral Rehydration Salts",
    "CDC - Conjunctivitis (Pink Eye)", "NHS UK - UTI Overview", "NHS UK - Appendicitis Overview"
  ],
  "license":"Original structured data by GramHealth; underlying facts from WHO/CDC/NHS/NHM public health resources"
}
```

**`manifest.json`** — map `term (lowercase, sometimes Hindi phrase)` → `shard letter (a-z, b exists but listed shards in metadata miss 'b' — asset still present; use actual files on disk as authoritative)`. ~200 keys, sample:
```
"anemia":"a", "anaemia":"a", "khoon ki kami":"a", "fatigue":"f", "skin":"s",
"appendicitis":"a", "common cold":"c", "cholera":"c", "dengue":"d", "diabetes":"d",
"fever":"f", "bukhar":"f", "tez bukhar":"f", "headache":"h", "sir dard":"h",
"hypertension":"h", "jaundice":"j", "malaria":"m", "pneumonia":"p", "snake bite":"s",
"tuberculosis":"t", "typhoid":"t", "uti":"u", "uti (with transliterations)":"u"
```
(See full file dumped in §assets inventory above.)

**Shards** — 13 gzip JSON files under `assets/offline_medical/shards/`: `a,b,c,d,f,h,j,m,o,p,s,t,u.json.gz`. Each decompressed payload is a JSON `List<MedicalLexiconEntry>` (see §7 model). E.g. `a.json.gz` contains anaemia/appendicitis etc.; `f.json.gz` contains fever etc. Keep all `*.json.gz` — the LRU loader expects whichever letter the manifest maps to.

**Entry model (`lib/models/medical_lexicon_entry.dart`):**
```dart
MedicalLexiconEntry {
  String  condition;                 // primary English condition name used as key
  List<String> aliases;              // alternative names
  List<String> symptoms;             // symptom strings for findBySymptoms
  List<String> warningSigns;         // up to 3 shown in lexiconOnly header, up to 4 in LLM context snippet
  String  generalInformation;        // paragraph(s) — the only "advice" in lexiconOnly, shown verbatim
  String  whenToSeekCare;            // triage line, shown after warnings
  bool    isEmergencyFlag;           // hint, not authoritative — emergency decision lives in safety layer
  String  source;                    // e.g. "WHO - Diabetes Fact Sheet"
  String  sourceUrl;
  String  license;
  String? lastReviewed;
}
```
Helpers:
```dart
searchableText → '${condition} ${aliases.join(" ")} ${symptoms.join(" ")}'.toLowerCase()
toContextSnippet({maxChars:800 default}) → "Condition: $condition\nWarning signs: {4}\nGeneral info: $generalInformation\nWhen to seek care: $whenToSeekCare" truncated at maxChars + "..."
```

### Lookup Service (`lib/services/offline_medical_lookup_service.dart`)

```dart
OfflineMedicalLookupService.instance  // singleton
LRU _shardCache maxSize=OfflineAiConfig.shardCacheMaxSize(4)  // key: letter → List<MedicalLexiconEntry>

initialise():
  rootBundle.loadString(lexiconManifestPath) → jsonDecode → Map<String,String> _manifest
  // no shard pre-load — lazy

search(String query) async {
  await _ensureReady()
  terms = _extractMedicalTerms(query)   // normalised tokens
  if terms.isEmpty → []
  letters = _shardsForTerms(terms)      // letters = {_manifest[term]} union { partial: any manifest key contains term or vice versa }
  results = Set<MedicalLexiconEntry>{}
  for letter in letters:
    entries = await _loadShard(letter)  // cached LRU else rootBundle.load(path='shards/$letter.json.gz') → GZipDecoder.decodeBytes → utf8.decode → jsonDecode list → map MedicalLexiconEntry.fromJson → cache
    for entry in entries:
      for term in terms: if entry.searchableText.contains(term): results.add(entry); break
  return results.take(offlineMaxEntries=3).toList()
}

findCondition(String condition) → normalised key lookup via _manifest → load shard → find where condition==key or aliases match

findBySymptoms(List<String> symptoms) → normalised symptoms → letters via _shardsForTerms → scored map entry→count where entry.symptoms.contains(normalised) substring; sort descending; take 3

_extractMedicalTerms(String query):
  text = _normalise(query) = lower + non-word→space + collapse spaces
  // apply Hindi/Marathi map (~60 entries) long phrases first
  for each _hindiSymptomMap { text = text.replaceAll(hindi, english) }
    includes: sir dard→headache, pet dard→abdominal pain, seena dard→chest pain, tez bukhar→high fever, bukhar→fever, khasi→cough,
              sardi→cold, ulti→vomiting, dast→diarrhea, saans→breathing, chakkkar→dizziness, sujan→swelling, dard→pain etc.
    Marathi: pot khupp dukht→abdominal pain, doke dukht→headache, shwas lagto→difficulty breathing etc.
  for each _spellingVariants { text = replaceAll }
    diarhea→diarrhea, haedache→headache, malaira→malaria, dengu fever→dengue, anaemia→anemia, uti→urinary tract infection, hypertension→high blood pressure etc.
  words = text.split(\s+).where(len>=3); filter stopWords { the,and,for,what,how, meri,mujhe,kya,hai, kar,bahut, me,aaj,majha,aahe,mala,nahi,kay ...~40 }
  return remaining words as terms

_normalise(String input) → same lower→sanitize pipeline
_shardsForTerms(terms) → as above
_loadShard(letter) → as above
```

---

## 7. Safety Layer (`lib/services/offline_safety_service.dart`) — Deterministic Red Flags

**Runs before any LLM; intrusive edits are forbidden.** The LLM system prompt itself embeds “Do not contradict emergency safety instructions.”

```dart
OfflineSafetyService.instance
  11 keyword sets (all lowercase, multilingual):
    breathingEmergency  13  ["difficulty breathing","can't breathe","saans nahi aa raha","shwas ghyayla tras","choking"...
    chestPainEmergency   9  ["chest pain","heart attack","seena dard","chaati madhe dukhat","crushing chest"...
    strokeEmergency      9  ["stroke","face drooping","arm weakness","speech difficulty","pakshaghat","lakwa"...
    unconsciousEmergency 7 ["unconscious","unresponsive","passed out","behosh","gir gaya","beshuddh"...
    seizureEmergency     7  ["seizure","convulsion","fits","dauraa","mirgi","aanchki"...
    bleedingEmergency    9  ["severe bleeding","coughing blood","khoon aa raha","raktasrav"... ]
    allergyEmergency     3  ["anaphylaxis","throat swelling","hives with breathing"]
    mentalHealthEmergency 7 ["suicidal","self-harm","want to die","khatam karna chahta"...]
    snakeBiteEmergency   5  ["snake bite","saanp ne kaata","saanp chaavla","scorpion sting"...]
    poisoningEmergency   4  ["poisoning","swallowed poison","zehr khaya","vishbaadha"...]
    paediatricEmergency  4  ["baby not breathing","infant seizure","newborn unconscious","febrile seizure"]

  isEmergency(String query) => _normalise(query) then for each set, each kw: if normalised.contains(kw) return true
  matchedEmergencyTerms(query) → list of every matched kw (ordered by set iteration)
  buildEmergencyResponse(List<String> matchedTerms, {String? query}) → OfflineResponse.emergency(...)

  sanitiseGeneratedText(String text): for each _unsafePatterns regex =>
    [
      r'you have (?:been diagnosed with|definitive|confirmed)',
      r'the diagnosis is (?:definitely|certainly|confirmed)',
      r'take (?:\d+\s*mg|\d+ tablet|\d+ pill)',
      r'dosage[:\s]+\d+',
    ]  // case-insensitive replaceAll with '[Information removed for safety]'
    then trim

  _normalise: lower → [^\w\s]→space → \s+→space → trim
```

Every offline query is checked via `isEmergency` (ChatBot prefix uses it to set urgency; SymptomChecker gates early; Router fans to LEVEL 2). There is **no confidence threshold** — any single match is an emergency.

---

## 8. Deterministic Emergency Response (no LLM)

When `matchedEmergencyTerms` is non-empty, the router returns:

```dart
OfflineRoutingResult(
  response: OfflineResponse(
    text: ClinicalResponse.emergency(query: query, matchedTerms: terms).toFormattedText(),
    decision: OfflineResponseDecision.emergency,
    isEmergency: true,
    matchedTerms: terms,
    structuredResponse: ClinicalResponse.emergency(...)
  ),
  stream: Stream.value(that same text),
)
```

`ClinicalResponse.emergency(query, matchedTerms)` (`lib/models/clinical_response.dart:278`) shape (9 sections, deterministic strings):

```dart
ClinicalResponse(
  symptomSummary: 'Reported symptoms with emergency indicators: $query'
  assessment: Assessment(
    summary: 'Emergency indicators or critical red-flag symptoms have been identified. Immediate medical attention may be required.',
    evidenceBasis: 'Deterministic Safety Rule',
    uncertainty: 'Acute medical emergencies cannot be evaluated or managed remotely.',
  )
  possibleConditions: []   // none shown
  riskLevel: RiskLevel.emergency  // triggers toFormattedText 🚨 header
  whatYouCanDoNow: [
    'Call local emergency services immediately (108 / 112).',
    'Go to the nearest hospital emergency room right now.',
    'Do not wait or attempt to treat severe symptoms at home.',
    'Ensure someone stays with the patient while seeking immediate medical help.',
  ]
  warningSigns: [
    'Severe chest pain, pressure, or tightness',
    'Severe shortness of breath or difficulty breathing',
    'Loss of consciousness or fainting',
    'Sudden weakness, numbness, or difficulty speaking',
    'Severe uncontrolled bleeding',
  ]
  whenToSeeDoctor: 'Seek emergency medical attention IMMEDIATELY. Call 108 / 112 or visit the nearest emergency department.'
  evidence: [
    EvidenceItem(
      title: 'Emergency Safety Protocol',
      sourceType: 'Deterministic Safety Rule',
      source: 'GramHealth Emergency Protocol',
      citation: 'EMERGENCY-01',
      relevance: 'Deterministic safety triage triggered by reported red flags.'
    )
  ]
  medicalDisclaimer: 'This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.'
  sourceMode: 'Deterministic Safety Rule'
  requiresProfessionalReview: true
  emergency: true
)
```

`toFormattedText()` (`:411`) for this branch emits:

```
🚨 EMERGENCY
These symptoms may require urgent medical attention.

SYMPTOM SUMMARY:
Reported symptoms with emergency indicators: ...

ASSESSMENT:
Emergency indicators ... have been identified. Immediate medical attention may be required.
Evidence basis: Deterministic Safety Rule
Uncertainty: Acute medical emergencies cannot be evaluated or managed remotely.

RISK LEVEL: EMERGENCY

WHAT YOU CAN DO NOW:
• Call local emergency services immediately (108 / 112).
• Go to the nearest hospital ...

WARNING SIGNS:
⚠ Severe chest pain, pressure, or tightness
...

WHEN TO SEE A DOCTOR:
Seek emergency medical attention IMMEDIATELY. ...

EVIDENCE / SOURCE:
• Emergency Safety Protocol (Deterministic Safety Rule - GramHealth Emergency Protocol) [EMERGENCY-01]

MEDICAL DISCLAIMER:
This information is for general health guidance and is not a medical diagnosis. ...
```

`OfflineResponse.emergency` which wraps this also carries `matchedTerms`.

ChatBot layer then wraps once more: `responseText = "🚨 EMERGENCY 🚨\n" + responseText` when `urgency=='emergency'` — so final bubble contains **two** emergency banners (deterministic body header plus ChatBot prefix). This is intentional legacy — replicate it.

### `RiskLevel` enum (`clinical_response:5`):

```
RiskLevel { emergency(0xD32F2F, Icons.emergency), high(0xF57C00, warning_rounded),
            moderate(0xFFA000, info_outline_rounded), low(0x388E3C, check_circle...),
            insufficientInformation(0x757575, help_outline) }
fromString Insufficient for unknown/empty/invalid variants.
```

---

## 9. Lexicon-Only Response (LEVEL 4 — Today's Production Path for Non-Emergencies)

Because `enableLocalLlmRuntime==false`, every non-emergency medical match lands here. The app never generates — it formats the matched entries and returns a full `ClinicalResponse` offscreen while streaming plain text.

**Builder (`OfflineAiRouter._buildLexiconOnlyResult(entries)`, router:121):**

```dart
StringBuffer sb
sb.writeln('The offline assistant found the following general information. This is NOT a diagnosis. Please consult a qualified healthcare provider for personal medical advice.\n')
for entry in entries:
  sb.writeln('--- ${entry.condition} ---')
  if entry.warningSigns.isNotEmpty:
    sb.writeln('Warning signs: ${entry.warningSigns.take(3).join(", ")}')
  sb.writeln(entry.generalInformation)
  sb.writeln('When to seek care: ${entry.whenToSeekCare}')
  sb.writeln()  // blank line between
text = sb.toString().trim()
matchedTerms = entries.map((e)=>e.condition).toList()
return OfflineRoutingResult(
  response: OfflineResponse(text, decision:lexiconOnly, matchedTerms),
  stream: Stream.value(text),
)
```

This is the exact `offlineText` string the ChatBot and SymptomChecker receive via the `AiService` wrapper when offline. It already carries its own header+NAD via prefix, so no extra disclaimer is prepended beyond the builder's first paragraph. The structured companion `ClinicalResponse.offlineLexicon(...)` is created inside `OfflineResponse` factories but **is not surfaced in the ChatBot bubble** — bubble shows only `offlineText` plus the ChatBot prefix `⚠️ Please consult...` (because `requiresProfessionalReview:true`). For the SymptomChecker's `StructuredClinicalResponseCard` case, `OfflineMedicalRepository` instead builds a dedicated `buildSymptomCheckerContext` when offline.

**SymptomChecker offline fallback text (`OfflineMedicalRepository.buildSymptomCheckerContext`):**

```dart
buildSymptomCheckerContext(List<String> symptoms):
  entries = await findBySymptoms(symptoms)
  if entries.isEmpty:
    return 'The offline assistant does not have specific information about this combination of symptoms. Please consult a healthcare provider or use GramHealth online when connectivity is available.'
  sb='These symptoms can occur with several conditions. The offline assistant cannot determine the exact cause. Below is general information only — this is NOT a diagnosis.\n\n'
  for entry in entries.take(2):
    sb+='• ${entry.condition}\n'
    if warningSigns non-empty: sb+='  Warning signs: ${warningSigns.take(2).join(", ")}\n'
    sb+='  ${entry.whenToSeekCare}\n'
  sb+='\nPlease seek professional medical evaluation for a proper diagnosis.'
  return sb
```
(`repositories/offline_medical_repository.dart`)

SymptomChecker's offline path chooses: `finalAdvice = offlineText.isNotEmpty ? offlineText : fallbackContext` — so the streamed routed text takes precedence over `buildSymptomCheckerContext`.

---

## 10. Lexicon + LLM Response (LEVEL 3 — Only When `enableLocalLlmRuntime==true`)

**Trigger:** `entries.isNotEmpty && isModelReady` where `isModelReady = enableLocalLlmRuntime && status ∈ {loaded,generating}` (`router:59`).

**Context assembly (`router:154 _buildContext`):**
```dart
_buildContext(List<MedicalLexiconEntry> entries):
  total=0; parts=[]
  per entry: snippet = entry.toContextSnippet(maxChars: offlineContextMaxCharacters ~/ entries.length) // ≈ 1500/2..3 = 500..750 per entry
  if total+snippet.length > offlineContextMaxCharacters(1500): break
  parts.add(snippet); total+=snippet.length
  return parts.join('\n---\n')
  // toContextSnippet per entry: 'Condition: ...\nWarning signs: {4}\nGeneral info: ...\nWhen to seek care: ...' truncated to maxChars
```

**Prompt (`router:171 _buildPrompt`):**
```
USER QUERY:
$query

OFFLINE MEDICAL CONTEXT:
$context
```

**System prompt — exact, do not paraphrase (`router:190 _kSystemPrompt`):**

```
You are GramHealth Offline Assistant.

You are an offline health-information assistant, not a doctor.

Use only the supplied OFFLINE MEDICAL CONTEXT as factual medical knowledge. Do not invent facts outside that context.

Do not diagnose a disease with certainty.
Do not prescribe medications or dosages.
Do not contradict emergency safety instructions.
When the context is insufficient, say that the available offline information is limited.

For every medical question provide:
1. What the symptom/topic generally means
2. Important warning signs
3. Safe next step
4. When professional medical evaluation is recommended

Always end with a reminder to seek professional care for personalised medical advice.
```

**Generation call (`router:72`):**
```dart
tokenStream = llmService.generate(prompt: prompt, systemPrompt: _kSystemPrompt)
  // LiteRtLmService.generate throws if !_ready or _generating already true
  // Passes maxTokens=400, temperature=0.2, topP=0.9, topK=40 via initialise options (Kotlin side)
  // Triggers llmInference.generateAsync(buildQwenPrompt(systemPrompt,prompt), listener)
safeStream = tokenStream.map((token) => safetyService.sanitiseGeneratedText(token))
return OfflineRoutingResult(
  response: OfflineResponse(text:'', decision:medicalLexiconPlusLlm, matchedTerms: entries.map(condition)),
  stream: safeStream, // progressive tokens
)
```

The first response `text` is empty — callers must consume `stream` (AiService buffers via `await for token in stream: buffer.write(token)` then `buffer.trim()`).

**Determinism knobs:** `temperature=0.2, topP=0.9, topK=40, maxNewTokens=400` are what ship — do not raise temperature in rebuild or outputs will drift; preference is reproducibility over creativity in offline medical.

---

## 11. Unsupported / Unavailable (LEVEL 5 — No Entries)

```dart
// router:103-114
if (!isModelReady && status==LocalModelStatus.unavailable):
  return OfflineResponse.unavailable() // decision=unavailable
    text:'Offline AI is not available on this device. Please use GramHealth online for medical questions.'
    structuredResponse: ClinicalResponse.offlineUnknown(query ?? 'Query')
      symptomSummary: query
      assessment.summary: 'No specific medical conclusion can be made from the available offline information.'
      assessment.evidenceBasis: 'None'
      assessment.uncertainty: 'The offline assistant does not have verified offline reference data for this specific topic.'
      riskLevel: insufficientInformation
      whatYouCanDoNow: ['Monitor...','Connect to the internet...','Consult a qualified healthcare professional...']
      warningSigns: ['No specific warning signs...']
      whenToSeeDoctor: 'Seek medical care if you feel unwell...'
      evidence: ['No retrieved evidence' (None/None)]
else:
  return OfflineResponse.noInformation() // decision=unsupported
    text:'The offline assistant does not have specific information about this topic. For medical questions, please consult a qualified healthcare provider or use GramHealth online when connectivity is available.'
    structuredResponse: ClinicalResponse.offlineUnknown(query ?? 'Medical question')
```

These are what remain when neither safety nor lexicon hit — they still carry a full `ClinicalResponse.offlineUnknown` + disclaimer, so `StructuredClinicalResponseCard` can render them though the ChatBot bubble only shows short text.

---

## 12. Wrapper Models — What Callers See

### 12.1 `OfflineResponse` (`lib/models/offline_response.dart`)

```dart
enum OfflineResponseDecision { emergency, medicalLexiconPlusLlm, lexiconOnly, unsupported, unavailable }

class OfflineResponse {
  String text;                           // final streamed or static text
  OfflineResponseDecision decision;
  bool isStreaming;                      // unused flag currently false
  bool isEmergency;                      // true only for emergency
  List<String> matchedTerms;             // matched lexicon/emergency words
  String? diagnosticsJson;               // unused currently
  ClinicalResponse? structuredResponse;  // paired 9-section clinical model
  // factories:
  factory OfflineResponse.emergency({String? query, String? customText, List<String> matchedTerms})
    => structured = ClinicalResponse.emergency(query ?? matchedTerms.join(',')); text=customText ?? structured.toFormattedText()
  factory OfflineResponse.unavailable({String? query}) => text:'Offline AI is not available ...' + structured=ClinicalResponse.offlineUnknown
  factory OfflineResponse.noInformation({String? query}) => text:'The offline assistant does not have specific information...' + structured=ClinicalResponse.offlineUnknown
}
```

### 12.2 `ClinicalResponse` (`lib/models/clinical_response.dart`) — 9 Sections

Full definition shown in doc 01 §`ClinicalResponse`. Disposable shape for rebuild:

```dart
ClinicalResponse(
  String symptomSummary,
  Assessment assessment,                  // {summary, evidenceBasis, uncertainty}
  List<PossibleCondition> possibleConditions, // up to 3, each {name, reason, evidenceStatus}
  RiskLevel riskLevel,
  List<String> whatYouCanDoNow,
  List<String> warningSigns,
  String whenToSeeDoctor,
  List<EvidenceItem> evidence,            // {title, sourceType, source, citation, relevance}
  String medicalDisclaimer = standardDisclaimer,
  String sourceMode,                       // Medical RAG | Offline Medical Lexicon | Deterministic Safety Rule | None
  bool requiresProfessionalReview = true,
  bool emergency = false,
)
// helpers:
ClinicalResponse.emergency({required String query, List<String> matchedTerms=[]})
ClinicalResponse.offlineLexicon({required String query, required String conditionName, required String generalInfo, required List<String> warningSigns, required String whenToSeekCare, required String source, required String citation})
ClinicalResponse.offlineUnknown({required String query})
static const String standardDisclaimer =
  'This information is for general health guidance and is not a medical diagnosis. '
  'Please consult a qualified healthcare professional for personal medical advice.';
toFormattedText(): renders all 9 with 🚨 EMERGENCY banner & headers when emergency.
```

### 12.3 `AiResponse` (`lib/models/ai_response.dart`) — What ChatBot Actually Holds

Fields passed from Python online or `AiService` offline wrapper:

```dart
AiResponse(
  String query,
  String? intent, String? agent, String? answer,
  bool? grounded, String? confidence, String? urgency,
  bool? requiresProfessionalReview, Map? evidence,
  List<String>? sources, String? routingMethod,
  List<String>? graphPath, dynamic structuredResponse
)
fromJson: mapper from decoded {query,intent,agent,answer,grounded,confidence,urgency,requiresProfessionalReview,evidence,sources,routing_method,graph_path, ...}
Offline branch is synthesised in AiService.query fallback:
  AiResponse(query, intent:isEmergency?emergency:offline_medical, agent:offline_ai_router, answer:offlineText,
             grounded:true, confidence:medium, urgency:isEmergency?emergency:routine,
             requiresProfessionalReview:true, routingMethod:offline_ai_safety_and_lexicon)
```

ChatBot consumes `answer`, `urgency`, `requiresProfessionalReview`, `agent`, `routingMethod` only — replicate that mapping.

### 12.4 LexiconEntry companion (`lib/models/medical_lexicon_entry.dart`) — see §6.
### 12.5 Local model status & compat (`lib/models/offline_model_metadata.dart`, `lib/models/local_model_status.dart`):

`LocalModelStatus` values & UI labels (`local_model_status:62-93`): `unavailable`→'Not downloaded', `checking`, `pending`→'Download pending', `downloading`, `verifying`, `verified`, `compatible`, `loadable`, `ready`, `loading`→'Starting', `loaded`→'AI • Offline', `generating`→'Thinking', `lexiconOnly`→'Knowledge mode', `error`→'Retry pending'.

`OfflineModelMetadata` persistence shape + `LocalModelCompatibility.canDownload/canLoad/isReadyForGeneration/deviceDiagnostics` as above.

---

## 13. Top-Level Coordinator (`lib/services/offline_ai_service.dart`) — What Screens Instantiate

```dart
class OfflineAiService.instance  // singleton

initialise():
  if _initialised return
  downloadService = LocalModelDownloadService()
  llmService = LiteRtLmService() // abstract wrapper over MethodChannel gramhealth/offline_llm
  _modelManager = LocalModelManager(downloadService, llmService)
  _lookupService = OfflineMedicalLookupService.instance
  _router = OfflineAiRouter(safetyService:OfflineSafetyService.instance, lookupService, modelManager, llmService)
  try: await _lookupService.initialise() catch non-fatal log
  _initialised=true

checkModelOnStartup({autoDownload:true}) → _modelManager.checkModelOnStartup(autoDownload)
startDownload()                          → _modelManager.startDownload()
cancelDownload()                         → _modelManager.downloadService.cancel()
ensureModelLoaded()                      → if !enableLocalLlmRuntime return (log lexiconOnly); if status==ready → loadModel()
runSmokeTest({prompt:'Say OK'})          → _modelManager.runNativeSmokeTest(prompt)
unloadModel()                            → _modelManager.unloadModel()
queryOffline(String query) async*       → _router.route(query) yields stream tokens; on catch yields noInformation().text
isEmergency(String query)                → OfflineSafetyService.isEmergency(query)
buildEmergencyResponse(String query)     → OfflineSafetyService matchedEmergencyTerms + buildEmergencyResponse
diagnostics() → { ai_mode: isModelUsable?'offline_llm': (lexiconOnly?'offline_lexicon':'unavailable'), enable_local_llm_runtime, offline_model:status.name, lexicon:bundled, model_version, model_size, download_progress:'n%', device_diagnostics: compatibility?.deviceDiagnostics, last_error }
getters: modelStatus, downloadProgress (0..1), downloadedBytes, expectedBytes, lastError, statusReason, modelMetadata, compatibility, statusStream
```

**Lifecycle expectations from screens:**

- `HomeScreen.initState` (patient): `unawaited(OfflineAiService.instance.initialise().then((_)=> checkModelOnStartup()).catchError((_) {}))` — fires once on patient home entry.
- `ChatBotScreen.initState`: `unawaited(OfflineAiService.instance.ensureModelLoaded())` + subscribes `statusStream` + `Connectivity.statusStream` to `setState`.
- `ChatBotScreen.didChangeDependencies`: seeds greeting Message if empty (`context.tr('greeting') + tr('dihati_assistant') + tr('ask_health')`).
- `SymptomCheckerScreen._analyze`: on offline catch → `await OfflineAiService.instance.initialise(); final stream = queryOffline("I have symptoms: $combinedQuery"); for await...` + `OfflineMedicalRepository().buildSymptomCheckerContext` helper.

All callers treat `OfflineAiService` as **ever-present**; they call `initialise()` even after foreground — it is no-op if already `_initialised`.

---

## 14. Response Type Catalogue (what the user actually sees)

| Trigger | Provider | Wraps as AiResponse (intent/agent/routing) | User-visible text (ChatBot bubble, SymptomChecker card) | Risk level | Prefix |
|---|---|---|---|---|---|
| Any emergency keyword (en/hi/mr/paediatric set) hit | `OfflineSafetyService.matchedEmergencyTerms` → `buildEmergencyResponse` | intent emergency, agent offline_ai_router, urgency emergency | 9-section `toFormattedText()` (🚨 + assessment + WARNING SIGNS + 108/112) inside `OfflineResponse` streaming `Stream.value(text)` | emergency (0xD32F2F red) | ChatBot further prefixes 🚨 EMERGENCY 🚨 |
| Medical terms hit, LLM ready (only when flag true) | `OfflineMedicalLookupService.search` (3 entries) + `LocalLlmService.generate` via MediaPipe LLM | offline_medical, offline_ai_router, offline_ai_safety_and_lexicon | Streamed LLM tokens sanitised (`[Information removed for safety]` for diagnosis/dosage patterns), bounded by `_kSystemPrompt` 4-point structure, ends with professional-care reminder | returned risk is whatever LLM says but caller treats it as `requiresProfessionalReview==true` | ChatBot prefixes ⚠️ Please consult if `requiresProfessionalReview` |
| Medical terms hit, LLM not ready (today's prod for all non-emergencies) | `OfflineMedicalLookupService.search` (3 entries) only | same offline_medical (but via lexiconOnly) | `The offline assistant found... This is NOT a diagnosis...\n--- {Condition} ---\nWarning signs: ...\n{generalInformation}\nWhen to seek care: ...` per entry; streamed once | detached; SymptomChecker shows same via `SymptomResult` or Card | same ⚠️ |
| `buildSymptomCheckerContext` fallback (SymptomChecker only) | `OfflineMedicalRepository.findBySymptoms` (2 entries) | same, but text chosen as `finalAdvice = offlineText.isNotEmpty ? offlineText : fallbackContext` | bullet list `• {condition}\n  Warning signs: {2}\n  {whenToSeekCare}` with header `These symptoms can occur... Below is NOT a diagnosis.` | — | — |
| No terms, no model | `OfflineResponse.noInformation` | none (fallback path never produces AiResponse else throws) | `The offline assistant does not have specific information about this topic. For medical questions, please consult a qualified healthcare provider or use GramHealth online when connectivity is available.` | insufficientInformation | — |
| Model unavailable on device | `OfflineResponse.unavailable` | — | `Offline AI is not available on this device. Please use GramHealth online for medical questions.` | — | — |

Every non-`emergency` output carries `standardDisclaimer` in its structured companion, but the ChatBot bubble (legacy) wraps it with `⚠️ Please consult a professional.` because `requiresProfessionalReview==true` — keep that wrapper, not the card disclaimer, for ChatBot.

### If you must validate determinism

For each fixture query in the table, assert:

1. Emergency — assert `OfflineAiService.isEmergency(query)==true` and `buildEmergencyResponse(query).text` equals `ClinicalResponse.emergency(query:query).toFormattedText()`.
2. Lexicon — e.g. `"mujhe bukhar aur khasi hai"` → `_hindiSymptomMap` rewrites → `search` returns `fever` shard entries; `_buildLexiconOnlyResult` text starts with `The offline assistant found...` and contains `Condition` names from those shards.
3. Unsupported — nonsense latin phrase → no entries → `noInformation().text` verbatim.
4. ChatBot wrapping — `AiService.query('...long known medical question while offline...')` yields `answer` that equals the lexiconOnly block; `agent==offline_ai_router && urgency==routine && confidence==medium`.

---

## 15. Observable State & UI Surfaces

- **OfflineSetupCard** (`lib/widgets/offline_setup_card.dart`) reads `OfflineAiService.modelStatus`, `.downloadProgress`, `.lastError`, `.statusReason`, `.compatibility`; shows: Checking spinner, Downloading linear progress (`downloadedBytes/expectedBytes` mb/mb + %), Pending with retry reason + **Download/Resume** button → `startDownload()`, Error with retry button, `lexiconOnly` shows “Knowledge mode active” banner (no button). Dismissable via `onDismiss`.
- **ChatBot header subtitle** (`chatbot_screen:82`): maps `NetworkStatus` + `LocalModelStatus.*` → `'AI • Online' (green 4CAF50)` vs `'Offline AI • Downloading n%' | Verifying | Ready | Knowledge mode | ...` (orange FF9800).
- **ConnectivityBadge / OfflineStatusIndicator** (`widgets/connectivity_badge`, `offline_status_indicator`): colored pill reflecting `NetworkStatus`.
- **Progress ticker** is `statusStream` (`LocalModelManager.statusController` broadcast) nudged per chunk (`_statusController.add(_status)`), plus a 10s `Connectivity._pingServer` in weak case.
- **Diagnostics surface** (`OfflineAiService.diagnostics()`): map useful for a hidden debug screen — mirrors production logs but never mixes PII. Include it in any rebuild diagnostics screen.

---

## 16. File Map — What to Copy or Reimplement

Quiet name-check: if the rebuild preserves paths exactly, diff regressions are reviewable. Minimum mandated port (no skipping — every file contributes to the pipeline):

```
lib/config/offline_ai_config.dart                     (registry + all tuning + all prefs keys)
lib/models/local_model_status.dart                    (enum + displayLabel extension)
lib/models/offline_model_metadata.dart                (OfflineModelMetadata + LocalModelCompatibility)
lib/models/medical_lexicon_entry.dart                 (MedicalLexiconEntry + snippet + searchableText)
lib/models/clinical_response.dart                     (RiskLevel + Assessment + PossibleCondition + EvidenceItem + ClinicalResponse.toFormattedText + emergency/offlineUnknown/offlineLexicon)
lib/models/offline_response.dart                      (OfflineResponseDecision + OfflineResponse emergency/unavailable/noInformation)
lib/models/ai_response.dart                           (AiResponse.fromJson + offline synthetic shape)
lib/repositories/offline_medical_repository.dart      (search wrapper + buildSymptomCheckerContext)
lib/services/offline_safety_service.dart              (all 11 emergency sets + matchedEmergencyTerms + sanitise)
lib/services/offline_medical_lookup_service.dart      (manifest+shard loader, LRU 4, _hindiSymptomMap, _spellingVariants, normalise)
lib/services/offline_ai_router.dart                   (_kSystemPrompt verbatim, route 2→5, _buildContext(prompt), generation sanitise)
lib/services/local_llm_service.dart                   (LocalLlmService abstract + LiteRtLmService — MethodChannel gramhealth/offline_llm + EventChannel gramhealth/offline_llm_tokens, Qwen ChatML buildQwenPrompt, ready/generating guards)
lib/services/local_model_manager.dart                 (FSM, verify, persistence, auto-download gating, listener for connectivity changes, backoff Timer)
lib/services/local_model_download_service.dart        (range-resume download + Atomic rename + SHA-256 AccumulatorSink)
lib/services/offline_ai_service.dart                  (coordinator — initialise, checkModelOnStartup, queryOffline streaming, diagnostics)
lib/services/connectivity_service.dart                (NetworkStatus + 10s ping via /api/health, isWifi/isMobile helpers consumed by auto-download gate)
lib/services/ai_service.dart                          (debugForceOnlineAi flag + online→offline wrapper + AiResponse synthesise — firewall for offline path)
lib/data/local_database.dart                          (sqflite cache holders — cached_* tables used to back offline lists; not LLM but required so offline lists stay stable post-rebuild)
android/app/src/main/kotlin/.../GramhealthLlmPlugin.kt (MethodChannel handler + EventChannel tokens + handleInitialize/generate/cancel/compatibility/smokeTest, Qwen prompt builder, CPU enforcement)
assets/offline_medical/manifest.json                   (term→shard map, keep exact JSON — indentation-insensitive but keys are authoritative)
assets/offline_medical/metadata.json                   (version, shards, sources/license — UI snapshot)
assets/offline_medical/shards/*.json.gz                (all 13 sharded MedicalLexiconEntry JSON lists — GZip + archive decoder expects .json.gz)
pubspec.yaml assets stanza                              (must list manifest + metadata + shards dir, and deps: archive, crypto, convert, connectivity_plus, path_provider, shared_preferences, http)
```

If you re-generate scaffolding (e.g. `flutter create`) you must re-wire `android/` so that `GramhealthLlmPlugin` is registered (it lives under `package com.gramhealth`; `GeneratedPluginRegistrant`/`MainActivity` must still load the plugin). The cleanest path is to diff `android/app/src/main/` against this repo and merge plugin files verbatim before any kotlin version bump. The Kotlin code pins `Backend.CPU` — do not default to GPU/Auto.

---

## 17. Exact Generation Semantics to Match in Rebuild

- **Temperature/topP/topK**: `0.2 / 0.9 / 40` (`offline_ai_config`). Even when generating offline, these are passed at `initialize(maxTokens, temperature, topP, topK)` (Kotlin reconstructs via `LlmInferenceOptions.Builder`) — so the model sees the same decoding every session. `maxTokens` for online model's full generation path is `400` (`maxNewTokens`), smoke test uses isolated `32`.
- **ChatML prefix**: `"<|im_start|>system\n$system<|im_end|>\n<|im_start|>user\n$user<|im_end|>\n<|im_start|>assistant\n"` (`GramhealthLlmPlugin.buildQwenPrompt`) where `$system` is `_kSystemPrompt` and `$user` is the composite `USER QUERY:…\n\nOFFLINE MEDICAL CONTEXT:…` string. Rebuild must preserve this template — Qwen's instruction tuning expects it.
- **Context budget**: at most `offlineContextMaxCharacters=1500` characters injected, divided among up to `offlineMaxEntries=3` entries (`_buildContext` slices per entry `1500/n`). Do not simply concatenate all shard entries or you will exceed Qwen's 32k window accounting via `offlineMaxPromptTokens=1024` guard (currently informational, not enforced — but respected via `offlineContextMaxCharacters` cut).
- **Post-generation sanitiser**: runs **token-by-token** via `.map(sanitiseGeneratedText)` on the `EventChannel` stream before `OfflineAiService` buffers. Pattern list is `you have … / the diagnosis is … / take \d+ mg/tablet/pill / dosage:` — keep case-insensitive replacement with `'[Information removed for safety]'`.
- **Streaming contract**: `EventChannel` emits per-token `String` then one terminal `"__EOS__"`; Kotlin listener on `generateAsync` calls `eventSink.success(partial)` for every partial and `__EOS__` when `done`. Dart `LiteRtLmService.generate` translates `__EOS__` → `close()`. `AiService` wrapper consumes this by `await for token in stream: buffer.write(token)` → `buffer.trim()`. Therefore any new frontend consuming `queryOffline` must handle `Stream<String>` with an explicit EOS — do not treat chunk boundaries as sentence boundaries.
- **Emergency sanitiser note**: the emergency path bypasses the LLM entirely, so sanitising is irrelevant — keep the early return, do not let the LLM “correct” an emergency.

---

## 18. Rebuild Sequence (suggested — last phase)

1. Ensure docs 01-03 are implemented and `POST /api/ai/query` is live on Render.
2. Copy `assets/offline_medical/` to `assets/offline_medical/` verbatim and register in `pubspec.yaml` (flutter pub get). Failure mode: missing shards silently give `noInformation()` — easy to miss.
3. Copy the entire `lib/*/offline* + local* + models/*` family as one commit; keep filenames identical.
4. Restore `android/app/src/main/kotlin/com/gramhealth/GramhealthLlmPlugin.kt` verbatim; ensure `android/app/build.gradle.kts` includes `implementation("com.google.mediapipe:tasks-genai:0.10.14")` (already present in current build — confirm version matches `tasksGenaiVersion`).
5. Run `HomeScreen` flow in Android emulator with airplane mode OFF — verify `checkModelOnStartup()` transitions to `lexiconOnly` (“Knowledge mode”) automatically (this is expected with shipped flag).
6. Enable airplane mode, open `ChatBot`, type `chest pain` → assert 🚨 EMERGENCY banner. Type `mujhe tez bukhar hai` → assert lexiconOnly block naming `fever`/related entries with `Warning signs:` line and footer disclaimer + ChatBot ⚠️ prefix. Type gibberish `xylophone quantum` → assert `does not have specific information...` line.
7. Flip `OfflineAiConfig.enableLocalLlmRuntime = true` on a dev branch only, trigger `await LocalModelDownloadService.download` overnight on Wi-Fi (file is ~489MB). On a `arm64-v8a` device with ≥1.5GB free RAM, confirm `modelStatus` progresses `downloading → verifying → ready → loaded` and a medical query now streams tokens (compare same query's lexiconOnly text vs LLM text — they must differ; the LLM version must honour the 4-point `_kSystemPrompt` structure).
8. Revert flag to `false` before shipping; offline answers will then remain lexiconOnly-deterministic regardless of whether the .tflite exists on disk.

This reproduces today's offline product exactly, while keeping the LLM upgrade path reversible behind a single boolean.

---

*End of doc 04. Combined suite `01..04` is now a self-closed rebuild spec — no backend change, no prompt rewording, no missing button expected by review.*
