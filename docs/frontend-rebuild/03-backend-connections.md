# GramHealth Frontend Rebuild — 03 / Backend & AI Connection Map

> **Connect the new Flutter build to the already-hosted backend without touching backend code.**
> Hosted base is **Render** production deployment — do not change backend. Just reattach frontend exactly as below.
> Verified against `GramHealth/lib/config/app_config.dart`, `GramHealth/lib/services/*`, `GramHealth/assets/offline_medical/`, and `backend/src/routes|controllers|services/*.js` read on 2026-10-16.

---

## 0. Golden Rules Before Wiring

1. **Single origin — Node.js is the only gateway.** Never call the Python AI service (`GRAM_AI_URL`) directly from the app (`app_config.dart:11` comment *"Node.js backend is the sole gateway to the Python AI service (no direct client-to-AI calls)"*). Every `/agent/*` or `/patient/ingest` call must go through Node first.
2. **Production switch:** `AppConfig.useProduction == true` by default (`app_config.dart:29`). The file compiles to `baseUrl = useProduction ? liveBackendUrl : localBackendUrl`. Keep `true` in release — do not ship with localhost.
3. **Timeouts:** `ApiClient` wraps `http.*.timeout(Duration(seconds: 35))` (`api_client.dart:64,78`); `AiService.query` uses 120s (`ai_service.dart:46`); symptom checker call wraps with `.timeout(Duration(seconds: 45))`. Replicate these or users in rural 2G will see spurious errors.
4. **Auth header shape:** `Authorization: Bearer <SharedPreferences gram_health_token>` added by `ApiClient._headers(auth:true)` (`api_client:20-22`). Login/Register/Reset use `auth:false`. AI route also sends `X-Request-ID: req-<epoch>-<hash>` (`ai_service:25`).
5. **Offline-first queue:** Any `POST/PATCH/DELETE` that may occur offline must go through `SyncService.push` (not naked `ApiClient.post`) — see §7.

---

## 1. Environment & Base URLs (`lib/config/app_config.dart`)

```dart
// app_config.dart:16,19,29,43
static const String liveBackendUrl       = 'https://gramhealthapp.onrender.com';
static const String adbReverseBackendUrl = 'http://127.0.0.1:3000';      // adb reverse tcp:3000 tcp:3000
static const String defaultLanBackendUrl = 'http://192.168.0.102:3000';   // optional LAN dev
static LocalBackendMode localBackendMode = LocalBackendMode.adbReverse;  // adbReverse | lan
static String lanBackendUrl = defaultLanBackendUrl;
static bool   useProduction = true;            // <- ship true
static String get baseUrl => useProduction ? liveBackendUrl : localBackendUrl;

// Keys
static const String tokenKey = 'gram_health_token';  // SharedPreferences stores JWT here
static const String userKey  = 'gram_health_user';   // JSON-encoded {id, name, email, role, ...}
static const String roleKey  = 'gram_health_role';   // mirrored role (sometimes)
```

Derived route getters (all **node-gated**, no direct AI calls):

```
apiHealth          = $baseUrl/api/health           GET   (connectivity ping)
apiAuth            = $baseUrl/api/auth             -> /register, /login, /reset-password
apiDoctors         = $baseUrl/api/doctors          -> / , /me, /:id, /consultations, /prescriptions, /medical-records
apiPatients        = $baseUrl/api/patients         -> /me
apiConsultations   = $baseUrl/api/consultations    -> / , /:id, /:id/status, /:id/accept, /:id/complete, /:id/assign-doctor, /:id/voicenote
apiMedicalRecords  = $baseUrl/api/medical-records  -> /upload, /me, /patient/:patientId, /:id
apiPrescriptions   = $baseUrl/api/prescriptions    -> / , /me, /:id, (/doctors/prescriptions is under doctors router)
apiUsers           = $baseUrl/api/users            -> (admin user table, if exposed)
apiPharmacy        = $baseUrl/api/pharmacy         -> /list (GET), /inventory (POST)
apiAi              = $baseUrl/api/ai               -> /query (POST)
```

All paths in the sections below are shown as **full URLs via `AppConfig.*` getters** — use those in Dart; the backend routers mount identically under `backend/src/routes/*.routes.js`.

---

## 2. Connectivity Check (used to gate downloads, calls, offline banners)

**Flutter side (`lib/services/connectivity_service.dart`):**

```dart
ConnectivityService.instance.initialize()
  -> Connectivity.onConnectivityChanged.listen(...) + Timer.periodic(10s, _pingServer)

_pingServer():
  result = await Connectivity.checkConnectivity()
  if none → NetworkStatus.offline
  else http.get(baseUrl + '/api/health', timeout 5s)
     200 && latency>1500ms → NetworkStatus.weak
     200 && latency≤1500ms → NetworkStatus.online
     non-200              → offline
     TimeoutException      → weak
     other exception       → offline

enum NetworkStatus { online, weak, offline }
bool isOnline => currentStatus != offline
Future<bool> isWifiOrEthernet()  // checks Wifi||Ethernet in connectivity results
Future<bool> isMobileData()       // checks Mobile
Stream<NetworkStatus> statusStream
```

**Backend (`GET /api/health` → `backend/src/routes/connectivity.routes.js` → health controller):**

```
GET  https://gramhealthapp.onrender.com/api/health
Auth: none
Response 200: { success: true, message: "GramHealth API is running" } (or similar)
Used only for reachability; no auth.
```

`SyncService` and `LocalModelManager` subscribe to `statusStream`; weak forces Audio-only in teleconsultation (`teleconsultation_request_screen:50`).

---

## 3. HTTP Layer (`lib/services/api_client.dart`)

```dart
class ApiClient {
  static Future<dynamic> get(String url, {bool auth = true})
  static Future<dynamic> post(String url, Map<String,dynamic> body, {bool auth = true})
  static Future<dynamic> patch(String url, Map<String,dynamic> body, {bool auth = true})
  static Future<dynamic> delete(String url, {bool auth = true})
  // each: http.<verb>(Uri.parse(url), headers: _headers(auth), body: jsonEncode(body)).timeout(35s)
  // _headers: { Content-Type: application/json, Accept: application/json, Authorization: Bearer <token> if auth }
  // _assertSuccess: if status <200||>=300 → throw ApiException(message, statusCode)
  //   special: if parsed.code=='VALIDATION_ERROR' && errors is List → message = errors[0].message
}

class ApiException implements Exception { String message; int statusCode; }
```

Notes: `ApiClient` is **not** resilient (no retry). `SyncService.push` wraps it — see §7.

---

## 4. Auth (`lib/services/auth_service.dart` + `backend/src/routes/auth.routes.js`)

Storage: JWT lives in **SharedPreferences** (`prefs.getString(AppConfig.tokenKey)`), not `flutter_secure_storage` (legacy import kept only). User object JSON lives under `AppConfig.userKey`. `AuthService.getUser()` decodes it. `LocalDatabase.clearAllData()` is called on every `login` (before save) and on `logout` → isolation guarantee.

### 4.1 POST /api/auth/register

```
POST https://gramhealthapp.onrender.com/api/auth/register
Auth: none (ApiClient auth:false)
Headers: Content-Type: application/json

Body (AuthService.register):
{
  name:     string  required
  email:    string  required (validated ^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$)
  phone:    string  required
  password: string  required (≥8 chars, caller validates; server also validates)
  role:     string  required — send TOUPPER ("PATIENT"|"DOCTOR"|"ADMIN"|"PHARMACY"|"ASHA")
  address:  string? optional (required when role==PHARMACY)
  latitude: double? optional (derived via geocoding when pharmacy)
  longitude: double? optional
}

Validator: backend/src/validators/auth.validator.js  register  (Joi/Zod — enforces email, password, role, phone, etc.)
Success envelope: { success:true, data: { id, name, email, phone, role, ... } }  (user row)
  → Caller then immediately logs in; register alone does NOT persist token.
Errors: 400 VALIDATION_ERROR {message, code:"VALIDATION_ERROR", errors:[{message,path}]}, 409 DUPLICATE_EMAIL
Flutter handler (login_screen:165): ApiException.message shown as SnackBar; pharmacy geocoding failure shown before request.

Frontend call:
  await AuthService.register(name:..., email:..., phone:..., password:..., role:_selectedRole, address:..., latitude:..., longitude:...)
  await AuthService.login(email, password)  // chained
```

### 4.2 POST /api/auth/login

```
POST https://gramhealthapp.onrender.com/api/auth/login
Auth: none
Body: { email: string, password: string }

Backend: auth.controller login → bcrypt verify → sign JWT (payload includes userId/id, role) → returns:
{ success:true, data: { token: string (JWT), user: { id, name, email, phone, role, address, hospital, specialization? ... } } }

Flutter (AuthService.login, auth_service.dart:64):
  ApiClient.post('${AppConfig.apiAuth}/login', {email,password}, auth:false) // timeout 35s via ApiClient
  prints debug logs: [AUTH] POST url, Base URL, Network reachable, status, Token received: bool
  on success:
    1. await LocalDatabase.instance.clearAllData()  // wipe prior user caches + sync_queue
    2. await _saveToken(token)    // prefs.setString(tokenKey, token)
    3. await _saveUser(user)      // prefs.setString(userKey, jsonEncode(user))
    4. return user
  error taxonomy:
    SocketException/TimeoutException → ApiException(503|504, 'Backend unreachable...' / 'Connection timed out...')
    ApiException pass-through with correct status (401 etc.) + prints
    generic network string contains socketexception/connection refused/failed to fetch/clientexception → 503

After success, caller must: AuthGuard.onLogin(role.toLowerCase()); then context.go to dashboard (login_screen _navigateByRole).
```

### 4.3 POST /api/auth/reset-password

```
POST https://gramhealthapp.onrender.com/api/auth/reset-password
Auth: none
Body: { email: string (or phone) , newPassword: string }
  Flutter sends as { email: emailOrPhone, newPassword } (auth_service:182)
Backend: verifies email/phone exists → hashes newPassword → updates user row → returns {success:true, message:"Password reset..."}
Frontend: AuthService.resetPassword(emailOrPhone: ..., newPassword: ...)
  ForgotPassword screen calls it, then Scaffold success + context.go('/login')
Errors: 404 USER_NOT_FOUND, 400 VALIDATION
```

### 4.4 isLoggedIn / getCurrentRole / logout

```dart
AuthService.isLoggedIn  async { token = await getToken(); return token!=null && isNotEmpty }
AuthService.getCurrentRole() async { if !isLoggedIn return null; user=await getUser(); return user['role'] lowercased }
AuthService.logout() async { prefs.remove(tokenKey); prefs.remove(userKey); await LocalDatabase.clearAllData(); }
AuthService.getToken() -> prefs.getString(tokenKey)  // used by ApiClient._headers
AuthService.getUser()  -> jsonDecode(prefs.getString(userKey))
```

No backend call for these four.

---

## 5. AI — Chatbot & Analysis (Online Path + Offline Fallback)

### 5.1 Flutter surface

Two callers hit the **same single endpoint**:

| Caller | File | Query built | Lang/extra |
|---|---|---|---|
| ChatBot send | `lib/screens/common/chatbot_screen.dart:141` `_handleSend → AiService.query(text)` | raw user typed text | reads `ConnectivityService` for status chip only, not for branching — branching lives inside AiService |
| SymptomChecker Analyze | `lib/screens/patient/symptom_checker_screen.dart` `_analyze` + legacy twin `lib/screens/symptom_checker_screen.dart` | `"I have the following symptoms: $combinedQuery. What could this mean?"` with `combinedQuery` = `(_selected Set + _otherCtrl.text).join(', ')` | emergency pre-check (`OfflineAiService.isEmergency`) before any network call; wraps `AiService.query(...).timeout(45s)` |

### 5.2 Single Online Endpoint: Node.js → Python AI Service

```
Flow:  Flutter AiService.query()  →  Node POST /api/ai/query  →  Python POST /agent/query  →  Python RAG/Gemini  →  back to Flutter as AiResponse

Flutter → Node:
  HTTP POST  https://gramhealthapp.onrender.com/api/ai/query
  Headers:
    Content-Type: application/json
    Authorization: Bearer <JWT>                // from SharedPreferences gram_health_token (mandatory; 401/403 НЕ falls back offline)
    X-Request-ID: req-<epoch>-<5-digit hash>   // generated flutter-side per query (ai_service.dart:25)
  Body:
    { query: string (trimmed), patientId?: string|null }   // patientId forwarded when chatbot knows it (currently passed only if caller gives it)
  Timeout: 120s (ai_service.dart:46)

  Node route (backend/src/routes/ai.routes.js):
    router.post('/query', authenticate, loggingMiddleware(req.headers X-Request-ID, userId, queryLength) → next, queryAi)

  Node controller (backend/src/controllers/ai.controller.js  queryAi):
    validates query non-empty (400 if blank)
    detects specialties keywords (neurology, pediatric, cardio, gynecology, dermatology, orthopedic, general) for DB enrichment
    if isDoctorQuery (contains doctor/dr/specialist/list or matchedSpecialty or name token) →
      prisma.doctor.findMany ORed name/specialization/hospitalName, take 10, include user{ name,phone,email }
      builds dynamicDbContext string + doctorSearchResultText
    builds GRAMHEALTH_MASTER_KNOWLEDGE_BASE (+) dynamicDbContext → calls AiService (Node service)
    Node AiService (backend/src/services/ai.service.js  queryAgent):
      aiBaseUrl = process.env.GRAM_AI_URL  (production MUST be set, else dev http://127.0.0.1:8000)
      endpoint  = `${aiBaseUrl}/agent/query`
      POST body { query, patient_id: patientId }
      Headers { Content-Type, X-Request-ID }
      timeout 120000
      on 200 → returns json as-is to controller which wraps as { success:true, data: aiData }
      on error → wraps as { statusCode: 503/513, message: 'AI Service Error: <detail>' }

  Python AI service expected (GRAM_AI_URL, not hosted on Render Node host):
    POST {aiBaseUrl}/agent/query
    Body: { query: string, patient_id?: string }
    Returns (example, inferred from ai.controller logs + AiResponse model):
    {
      query: string,
      intent: string,                // e.g. doctor_search | symptom_triage | general_medical | knowledge_base
      agent: string,                 // e.g. gramhealth_agent / rag_agent
      answer: string,                // the human-readable answer (mandatory; if contains "AI reasoning service is currently unavailable" the Flutter treats as failure)
      grounded: boolean?,
      confidence: string?,           // low|medium|high
      urgency: string?,              // routine|high|emergency
      requiresProfessionalReview: boolean?,
      routing_method: string?,       // offline_ai_safety_and_lexicon etc.
      sources?: string[],
      evidence?: {…} | list,
      graph_path?: string[],
      structuredResponse?: any
    }

  Node → Flutter envelope (ai.service success):
    Response 200 on success:
    { success: true, data: { query, intent, agent, answer, grounded, confidence, urgency, requiresProfessionalReview, evidence, sources, routing_method, graph_path, ... } }
    On AI down (axios throws): node returns 503 (wrappedError.statusCode 503) which Flutter then handles.

  Flutter (lib/services/ai_service.dart class AiService):
    final bool debugForceOnlineAi = false   // ai_service:12 constant — keep false in prod

    static Future<AiResponse> query(String queryText, {String? patientId}) async {
      token = await AuthService.getToken(); if null throw 'Not authenticated'
      backendUri = Uri.parse('${AppConfig.apiAi}/query')
      requestId = 'req-${epoch}-${hashCode%100000}' // padded 5 digits
      try:
        resp = await http.post(backendUri,
          headers: {Content-Type, Authorization: Bearer token, X-Request-ID: requestId},
          body: jsonEncode({query:queryText, if(patientId) patientId}),
        ).timeout(120s)
        if status==401||403:
           print auth error; throw Exception('Authentication required or session expired...')  // MUST NOT fallback offline (ai_service:50)
        if status==200:
           decode JSON; handle two shapes:
             shape A: {success, data: {...}} → dataMap = decoded['data'] (Map)
             shape B: {query,...} legacy flat → dataMap = decoded itself (if decoded['query'] != null)
           check answer present: dataMap['answer'] non-empty trimmed
           log success/data/answerExists/intent/agent/routing_method
           if answer preview contains 'AI reasoning service is currently unavailable' || 'AI response generation failed':
              throw Exception('Backend returned fallback error...')
           if answerExists: return AiResponse.fromJson(dataMap)  // stored with requiresProfessionalReview, urgency, etc.
           else: throw Exception('Backend returned 200 OK but missing answer')
        if 502/503/504:
           isNetworkOrBackendUnavailable=true; lastError='Backend AI service unavailable (502/503/504): body'
        else (400/422/500 etc.):
           try jsonDecode error body; if message throw Exception(message) else generic throw status+body
      on SocketException/TimeoutException/ClientException → isNetworkOrBackendUnavailable=true; lastError = e.toString()
      on other catch where str contains failed to fetch/network/connection/clientexception → same
      else → rethrow (validation/auth etc.)

      // Offline fallback (only if online path proved network/backend unreachable)
      if debugForceOnlineAi: bypass fallback → throw Exception(lastError ?? 'Online AI service failed. (Silent offline fallback disabled)')
      if isNetworkOrBackendUnavailable:
         print OFFLINE_FALLBACK_STARTED
         await OfflineAiService.instance.initialise()
         isEmergency = OfflineAiService.instance.isEmergency(queryText)  // deterministic keyword match
         stream = OfflineAiService.instance.queryOffline(queryText)
         buffer all tokens → offlineText
         if offlineText.isNotEmpty:
           return AiResponse(
             query: queryText,
             intent: isEmergency ? 'emergency' : 'offline_medical',
             agent: 'offline_ai_router',
             answer: offlineText,
             grounded: true,
             confidence: 'medium',
             urgency: isEmergency ? 'emergency' : 'routine',
             requiresProfessionalReview: true,
             routingMethod: 'offline_ai_safety_and_lexicon',
           )
         else: fall through
      throw Exception(lastError!)
    }
```

**ChatBot → AiResponse → UI transform (`chatbot_screen:145-153`):**

```dart
aiResponse = await AiService.query(text)
responseText = aiResponse.answer ?? "I'm sorry..."
if aiResponse.urgency == 'emergency': responseText = "🚨 EMERGENCY 🚨\n$responseText"
else if requiresProfessionalReview == true: responseText = "⚠️ Please consult a professional.\n$responseText"
isOffline = (agent == 'offline_ai_router') || (routingMethod?.contains('offline') ?? false)
add Message(sender:'ai', text: responseText, isOffline:isOffline)
on catch: add error Message(sender:'ai', text:'Sorry, I encountered an error: $e')
```

**SymptomChecker → AiResponse → UI transform (`symptom_checker:88-104`):**

```dart
try:
  aiResponse = await AiService.query("I have the following symptoms: $combinedQuery. What could this mean?").timeout(45s)
  conditionText = (intent!=null && intent!='offline_medical' ? 'Clinical Assessment (${intent})' : 'Clinical Assessment')
  _clinicalResult = aiResponse.structuredResponse   // when python returns a structured ClinicalResponse JSON (rare; usually null)
  _resultSource = 'Online AI'
  _result = SymptomResult(condition:conditionText, advice: aiResponse.answer ?? 'No advice', action: requiresProfessionalReview||urgency=='emergency' ? 'Please consult...' : 'Monitor...', source:'Online AI')
catch:
  if debugForceOnlineAi → show SymptomResult condition 'Online AI Request Error', advice e.toString()
  else → await OfflineAiService.initialise()
        offlineStream = queryOffline("I have symptoms: $combinedQuery"); buffer → offlineText
        fallbackContext = await OfflineMedicalRepository().buildSymptomCheckerContext(symptomsToAnalyze)
        finalAdvice = offlineText.isNotEmpty ? offlineText : fallbackContext
        setState _clinicalResult=null, _resultSource='Offline AI', _result condition:'These symptoms can occur...'  advice:finalAdvice action:'Please seek professional...'
emergency pre-check at top of _analyze (before try): if isEmergency(combinedQuery) → buildEmergencyResponse → _clinicalResult=emergency.structuredResponse ?? ClinicalResponse.emergency(query) + SymptomResult condition Emergency Indicator / action 108/112 bottled/ Emergency Triage source
```

### 5.3 Python AI ingest (patient records sync to AI graph)

Not triggered from chatbot; fired when medical records are created — keeps Python RAG graph patient-aware.

```
Node AI service method (backend/src/services/ai.service.js  syncPatientRecord):
  POST {GRAM_AI_URL}/patient/ingest
  Body: { patient_id, record_id, record_type, record_date, text, source }
  Headers { X-Request-ID, Content-Type }
  timeout 120000
  Called (inferred from medicalRecord.controller uploadPatientRecord / createMedicalRecord): after Prisma insert succeeds, unawaited try/catch syncPatientRecord(... text=ocrOrFileExcerpt ... )
  Safe to omit on new frontend initial build — AI works without it, but records will not become RAG-queryable until re-added.
```

---

## 6. Consultations (`POST` + `GET` + `PATCH`)

Flipper: calls that go via `SyncService.push` when offline vs raw `ApiClient` when strictly online are noted.

| Call | Where made (Flutter) | Endpoint | Method | Body / Query | Auth & shape | Offline | Response / Side effects |
|---|---|---|---|---|---|---|---|
| **Create teleconsultation request** | `TeleconsultationRequestScreen._handleSubmit` → `ConsultationService.createConsultation(...)` (`consultation_service.dart:176`) | `POST ${AppConfig.apiConsultations}` | `POST` | `notes` = `"$reason\nPreferred time: $scheduledTime"`; `{ type: VIDEO|AUDIO|OFFLINE, notes, symptoms?, doctorId?, voiceNoteUrl? (base64?) }` | `AuthService` bearer via `SyncService.push` (which calls `ApiClient.post`) | `SyncService.push(entityType:'consultation', operation:'POST', endpoint:apiConsultations, payload:body)` — when `ConnectivityService.currentStatus != online` enqueues to `sync_queue` and returns `{status:'PENDING_SYNC', id:uuid}`; when online does `ApiClient.post` else catches and enqueues. If PENDING_SYNC, `TeleconsultationRequestScreen` still shows success screen (green check) and auto-pops 1.8s (`createConsultation:204`). | Online: `{ success:true, data: { id, status: PENDING|ACCEPTED, type, notes, symptoms, scheduledTime, doctorId, patientId, ... doctor,user, patient,user, voiceNotes } }` → `ConsultationModel.fromJson`. Offline: `ConsultationModel(id:uuid,status:'PENDING_SYNC', type, reason, ...)` temp |
| **List patient consultations** | `HomeScreen._loadConsultations` (`listConsultations(status:'ACTIVE')`) and `DoctorList`-indirect; `Teleconsultation` history (not in current patient nav) | `GET ${AppConfig.apiConsultations}?page=1&limit=20&status=ACTIVE\|PENDING...` | `GET` | query params `page, limit, status?` | bearer via `ApiClient.get` | If `currentStatus != online` → reads `LocalDatabase.getAllCachedData('cached_consultations')` then filters `status==...` locally (`consultation_service:118`). Online path: `ApiClient.get` → `response['data']` is `List` → for each with `id` `cacheData('cached_consultations', id, item)` then map `ConsultationModel.fromJson` (`130-134`). | `List<ConsultationModel>` ordering as backend returns |
| **List doctor consultations** | `DoctorRequestsScreen`, `DoctorConsultationsScreen` → `ConsultationService.listDoctorConsultations(status?)` (`143`) | `GET ${AppConfig.apiDoctors}/consultations?page=&limit=&status=` | `GET` | same | bearer | same offline cache fallback `cached_consultations` (`149-155`); online caches likewise (`163-166`) | `List<ConsultationModel>` |
| **Get single consultation** | detail screens | `GET ${AppConfig.apiConsultations}/:id` | `GET` | — | bearer | always online (`ApiClient.get`) — no offline fallback implemented | `ConsultationModel` |
| **Doctor accepts consultation** | `DoctorRequestsScreen` Accept button | `PATCH ${AppConfig.apiConsultations}/:id/accept` | `PATCH` | body `{ notes? }` (doctor notes optional) | bearer via `SyncService.push(entityType:'consultation_$id', operation:'PATCH', endpoint:..., payload:{notes})` | queued when offline → `_updateLocalCacheStatus(id,'ACCEPTED')` then returns `ConsultationModel(id,status:'ACCEPTED_OFFLINE')` (`239-241`); online success → force `cache status ACTIVE` (`245`) then parsed `data` | Online: `ConsultationModel` updated; offline queue item `entity_type='consultation_$id'` |
| **Doctor completes consultation** | `DoctorCompleteConsultationScreen` Complete button | `PATCH ${AppConfig.apiConsultations}/:id/complete` | `PATCH` | `{ notes?, riskLevel? }` (`riskLevel.name` emergency/high/moderate/low/insufficientInformation)  | SyncService same pattern (`252-274`) | Offline → cache status COMPLETED + returned COMPLETED_OFFLINE; online  → cache COMPLETED | `ConsultationModel` |
| **Update consultation status (generic)** | `HomeScreen` Join flow after CallService (`home_screen:183 updateStatus(id,'COMPLETED')`) and anywhere else needing arbitrary status | `PATCH ${AppConfig.apiConsultations}/:id/status` | `PATCH` | `{ status: string }` | via `SyncService.push(entityType:'consultation_$id', operation:'PATCH', endpoint:'.../status', payload:{status})` then `_updateLocalCacheStatus` (`286`) | queued when offline | void-ish caller awaits |
| **Assign doctor** | `AdminConsultationsScreen` assign dropdown | `PATCH ${AppConfig.apiConsultations}/:consultationId/assign-doctor` | `PATCH` | `{ doctorId: string }` | `ApiClient.patch` (online only) (`consultation_service:277`) | no offline queue (admin screen is web/desktop) | `ConsultationModel` |
| **Add voice note(s) to consultation** | `VoiceNoteDialog` / `VoiceNoteHistoryDialog` / `OfflineVoiceRecorder` → via `SyncService` or `ApiClient` eventually hits | `PATCH ${AppConfig.apiConsultations}/:id/voicenote` | `PATCH` | `{ voiceNoteUrl?/voiceNotes? }` (base64 or URL) | authenticated; route allows PATIENT, ASHA, ADMIN, DOCTOR (`consultation.routes: PATCH /:id/voicenote authorize(...)`) | may queue if offline | — |
| **Upload voice note URL at request creation** | teleconsultation request `voiceNoteUrl: _voiceNoteBase64` included in `createConsultation` POST above | same POST | — | — | — | — | — |

Backend guards (`backend/src/routes/consultation.routes.js`):
```
POST   /              authorize(PATIENT,ASHA)                validate createConsultation
GET    /              authorize(PATIENT,DOCTOR,ASHA,ADMIN)
GET    /:id           authorize(PATIENT,DOCTOR,ASHA,ADMIN)
PATCH  /:id/status    authorize(PATIENT,DOCTOR,ASHA,ADMIN)   validate updateStatus
PATCH  /:id/accept    authorize(DOCTOR)
PATCH  /:id/complete  authorize(DOCTOR)
PATCH  /:id/assign-doctor authorize(PATIENT,ASHA,ADMIN)
PATCH  /:id/voicenote authorize(PATIENT,ASHA,ADMIN,DOCTOR)
```
`AppConfig.apiConsultations` covers the first list; `/api/doctors/consultations` is aliased under doctors router (`doctor.routes: GET /consultations authorize(DOCTOR)`).

---

## 7. Doctors (`GET` catalogue + profile)

| Call | Flutter | Endpoint | Method | Body/Query | Offline |
|---|---|---|---|---|---|
| **List doctors** | `HomeScreen._loadDoctors`, `DoctorListScreen._loadDoctors` → `DoctorService.getDoctors({specialization?, page=1, limit=20})` | `GET ${AppConfig.apiDoctors}?page=&limit=&specialization?` | `GET` | `specialization` optional filter; `page/limit` pagination (always 20 in app) (`doctor_service:66`) | If `currentStatus != online` → reads `getAllCachedData('cached_doctors')` filtered by specialization (`71-77`). Online try/catch: on headers+status success → loop `cacheData('cached_doctors', id, item)` (`88-92`). On network exception, falls back to cache if non-empty (`98-104`). |
| **Get doctor by ID** | `DoctorDetailsScreen` init + `CallService` fallback resolution + `Teleconsultation` header cache | `GET ${AppConfig.apiDoctors}/:id` | `GET` | — | Offline : `getCachedData(cached_doctors, id)` → `DoctorModel`; else throw 'Doctor data not found offline.' (`112-114`). Online: fetch + cache then `DoctorModel`. |
| **Create doctor profile (post-register doctor onboarding)** | `DoctorOnboardingScreen` submit | `POST ${AppConfig.apiDoctors}` | `POST` | `{ specialization, experienceYears, hospitalName, consultationFee?, bio?, isAvailable, profileImageUrl? }` (from onboarding fields) (`doctor.routes: POST / authorize(DOCTOR) validate createDoctor`) | SyncService or ApiClient (online only in current app) |
| **Update my doctor profile** | `DoctorProfileScreen` Save | `PATCH ${AppConfig.apiDoctors}/me` | `PATCH` | partial fields minus role | online |
| **Get my doctor** | `DoctorProfileScreen` load / `DoctorService.getMyDoctor` (if used) | `GET ${AppConfig.apiDoctors}/me` | `GET` | — | online |
| **List my doctor consultations** | `DoctorConsultations` etc. already in §6 | `GET ${AppConfig.apiDoctors}/consultations` | `GET` | `?status&...` | cache as above |
| **List my doctor prescriptions** | `DoctorPrescriptionsScreen` → `PrescriptionService.getDoctorPrescriptions` → calls `GET /api/doctors/prescriptions` (see §9) | `GET ${AppConfig.apiDoctors}/prescriptions` | `GET` | `?page&limit` | `cached_prescriptions` fallback (see §9) |
| **List my doctor medical records** | `DoctorPatientsScreen` maybe via `GET /api/doctors/medical-records` | `GET ${AppConfig.apiDoctors}/medical-records` | `GET` | `? ...` | cached_records variant |

Backend (`doctor.routes.js`):
```
POST /               authorize(DOCTOR)                         createDoctor
GET  /me             authorize(DOCTOR)                         getMyDoctor
PATCH /me            authorize(DOCTOR)                         updateMyDoctor
GET  /consultations  authorize(DOCTOR)                         listDoctorConsultations
GET  /medical-records authorize(DOCTOR)                        listDoctorMedicalRecords
GET  /prescriptions  authorize(DOCTOR)                         listDoctorPrescriptions
GET  /               authorize(PATIENT,DOCTOR,PHARMACY,ASHA,ADMIN) listDoctors
GET  /:id            same                                      getDoctorById
```

Doctor model shape used in Flutter (`DoctorModel.fromJson`, `doctor_service:34`):
```json
{
  "id": "uuid",
  "specialization": "General Physician|Cardio|...",
  "experienceYears": 8,
  "rating": 4.7,
  "isAvailable": true,
  "profileImageUrl": "https://...",
  "consultationFee": "500" | null,
  "bio": "...",
  "hospital": "PHC X" | null,
  "user": { "name": "Dr. Roshan", "phone": "98...", "email": "..." }
}
```
Legacy derived getters (`doctor_service:52-59`) `spec, exp ('8 yrs'), image (fallback unsplash), fee ('₹...'), patients='—'` etc. are optional to replicate.

---

## 8. Patients (`GET me` + `PATCH me`)

| Call | Endpoint | Method | TLS |
|---|---|---|---|
| `PatientService.getMyPatient` | `GET ${AppConfig.apiPatients}/me` | `GET` | bearer `ApiClient.get` (`patient_service:34`) |
| `PatientService.updateMyPatient(Map data)` | `PATCH ${AppConfig.apiPatients}/me` | `PATCH` | bearer `ApiClient.patch` (`40`) |

Backend `patient.routes.js`:
```
GET   /me   authorize(PATIENT|? )   getMyPatient
PATCH /me   authorize(PATIENT)      updateMyPatient   — body: { bloodGroup?, allergies?, chronicConditions?, age?, ... }
```
PatientModel (`patient_service:4`): `{ id, userId, bloodGroup?, allergies?, chronicConditions? }` plus derived from `user` join (name/phone etc. via Profile).

---

## 9. Medical Records — ABHA Health Vault

| Call | Flutter | Endpoint | Method | Body | Offline |
|---|---|---|---|---|---|
| **List my records** | `PatientRecordsScreen._fetchRecords` → `MedicalRecordService().getMyRecords()` | `GET ${AppConfig.apiMedicalRecords}/me` (raw `http.get` with `Authorization: Bearer <token>`, not ApiClient) (`medical_record_service:20`) | `GET` | — | If `currentStatus != online` → `getAllCachedData('cached_records')` → `MedicalRecord.fromJson` (`12`). Online: `http.get(...){Authorization, Content-Type}` expecting `{ data: [...] }` each has `id` → `cacheData('cached_records', id, item)` (`33`) |
| **List a patient's records (doctor/admin)** | `DoctorPatientsScreen` / `MedicalRecordService.getDoctorRecords(patientId)` | `GET ${AppConfig.apiMedicalRecords}/patient/:patientId` | `GET` | — | Same offline fallback filtered `where patientId == ...` (`45`); online `http.get .../patient/:patientId` same caching |
| **Upload manual record (patient)** | `UploadRecordScreen._upload` → `MedicalRecordService.uploadManualRecord(title,type,fileUrl)` | `POST ${AppConfig.apiMedicalRecords}/upload` | `POST` | `{ title, documentType, fileUrl (data:image/... base64 or URL), issuedDate: now.toIso8601 }` (`medical_record_service:119`) | If `currentStatus != online`: create optimistic `tempId = offline_temp_{epoch}`; `recordData = { id:tempId, patientId:'self', title, documentType:type, fileUrl, issuedDate:now, createdAt:now, source:'MANUAL' }`; `cacheData('cached_records', tempId, recordData)`; `SyncService.push(entityType:'medical_record_$tempId', operation:'POST', endpoint:'.../upload', payload:{title,documentType,fileUrl,issuedDate})` → returns `MedicalRecord.fromJson(recordData)` (`82-110`). Online: `http.post(...){Authorization} body json` expects `201 { data: record }` else throw. |
| **Create record (doctor)** | (admin/doctor create, not in patient vault) `POST ${AppConfig.apiMedicalRecords}/` | `POST /api/medical-records/` | `POST` | `createMedicalRecordValidator` body (`recordType, data ...`) | online only (`authorize(DOCTOR)`) |
| **Get record by id** | detail fetch | `GET ${AppConfig.apiMedicalRecords}/:id` | `GET` | — | — |

Backend (`medicalRecord.routes.js`):
```
POST /        authorize(DOCTOR)                       validate createMedicalRecord   → createMedicalRecord
POST /upload  authorize(PATIENT,DOCTOR)               uploadPatientRecord
GET  /me      authorize(PATIENT)                      listMyMedicalRecords
GET  /patient/:patientId authorize(DOCTOR,ADMIN)      listDoctorPatientRecords
GET  /:id     authorize(PATIENT,DOCTOR,ADMIN)         getMedicalRecordById
```

Model (`lib/models/medical_record.dart`): `{ id, patientId, title, documentType, fileUrl?, issuedDate, createdAt, source }`

---

## 10. Prescriptions

| Call | Flutter | Endpoint | Method | Body/Query | Offline |
|---|---|---|---|---|---|
| **List patient prescriptions** | `PrescriptionListScreen`, mock `HealthRecordsScreen` `PrescriptionList` variant → `PrescriptionService.getPrescriptions(page,limit)` | `GET ${AppConfig.apiPrescriptions}/me?page=&limit=` | `GET` | `page/limit` default 1/20 | Offline → `getAllCachedData('cached_prescriptions')` mapped (`82-84`). Online try: `ApiClient.get(url)` → `items=data` → `cacheData(cached_prescriptions,id,item)` each → build `apiPrescriptions`; then also load `cached` where `diagnosis=='Sync Pending...'` drafts → `[...drafts, ...apiPrescriptions]` (`103-106`). On catch fallback to cache. |
| **List doctor prescriptions** | `DoctorPrescriptionsScreen` → `getDoctorPrescriptions(page,limit)` | `GET ${AppConfig.apiDoctors}/prescriptions?page=&limit=` | `GET` | same | Same pattern (`121-152`) — `cached_prescriptions` fallback & drafts merge |
| **Create prescription (doctor, from consultation)** | Consultation detail / Complete flow → `PrescriptionService.createPrescription({consultationId, medicines:List<Map>, instructions?})` | `POST ${AppConfig.apiPrescriptions}` | `POST` | `{ consultationId, medicines: [{name,dosage,frequency,duration,instructions?}...], instructions? }` (`prescription_service:161`) | Via `SyncService.push(entityType:'prescription', operation:'POST', endpoint:apiPrescriptions, payload:body)` (`167`). If PENDING_SYNC: build local `draftJson = { id:uuid, doctor:{user:{name:'Local Draft'}, specialization:'-'}, patient:{user:{name:'Local Draft'}}, createdAt:now, diagnosis:'Sync Pending...', medicines }` → `cacheData(cached_prescriptions, id, draftJson)` → `PrescriptionModel.fromJson(draftJson)` (`174-191`). Online: parse `response['data']`. |
| **Get single prescription** | detail | `GET ${AppConfig.apiPrescriptions}/:id` | `GET` | — | — |
| Backend dashboard list-all | admin | (same docs controller `listDoctorPrescriptions` but as admin listing) | — | — | — |

Backend (`prescription.routes.js`):
```
POST /     authorize(DOCTOR)                 validate createPrescription → createPrescription
GET  /me   authorize(PATIENT)                validate listMyPrescriptions → listMyPrescriptions
GET  /:id  authorize(PATIENT,DOCTOR,ADMIN)   validate prescriptionParam → getPrescriptionById
+ doctor.routes exposes GET /doctors/prescriptions authorize(DOCTOR) → listDoctorPrescriptions
```

Model (`PrescriptionModel` from `services/prescription_service.dart:8`):
```json
{
  "id": "uuid",
  "diagnosis": "string",
  "createdAt": "ISO8601",
  "medicines": [ {"name","dosage","frequency","duration", ...} ],
  "doctor": { "user": {"name":...}, "specialization":"..." },
  "patient": { "user": {"name":...} }
  // accessors: doctorName, specialization, patientName, date(YYYY-MM-DD), diagnosis, medicines, toDisplayMap()
}
```

---

## 11. Pharmacy & Medicine Finder

| Call | Flutter | Endpoint | Method | Body | Notes |
|---|---|---|---|---|---|
| **Sync pharmacies** (background on `SyncService.initialize` when online) | `PharmacyService.syncPharmacies()` | `GET ${AppConfig.apiPharmacy}/list`  → `https://gramhealthapp.onrender.com/api/pharmacy/list` | `GET` | — | bearer. On success: `data as List` mapped `PharmacyModel.fromJson` → per item `cacheData('cached_pharmacies', p.id, p.toJson())` (`70-79`). Called automatically on `SyncService.initialize` when `status != offline` (`sync_service:34-37`) and on every `status==online|weak` while app lives (`22-27`). Failure is swallowed with log (`Failed BG Pharmacy Sync`). |
| **Update inventory (pharmacist)** | `PharmacyDashboardScreen` toggle | `POST ${AppConfig.apiPharmacy}/inventory` | `POST` | `{ medicineName: string, inStock: bool }` (`pharmacy_service:87`) | `auth=PHARMACY` only (`pharmacy.routes: authorize("PHARMACY")`). Not queued. |
| **Local search (offline-capable)** | `MedicineAvailabilityScreen` search | — (no backend) | — | input `medicineQuery` (from `GoRouter` query param `query`) + `Geolocator.getCurrentPosition` lat/lon | Reads `getAllCachedData('cached_pharmacies')` → `PharmacyService.searchPharmaciesLocal(medicine, userLat, userLon)` (`94`): per pharmacy `hasMedicine(medicine)` (case-insensitive `medicineName.contains(lowerMed)` && `inStock==true`) (`48-56`), builds `PharmacySearchResult(pharmacy, distanceKm, isAvailable)`, sorts by distance, Haversine `_calculateDistance = 12742*asin(sqrt(a))` (`110-117`). |
| **Pharmacy model** | | | | `PharmacyModel { id, name, latitude, longitude, address, inventories: [{medicineName,inStock,quantity?,price?}...], userId }` | `toJson()` mirrors same |

Backend (`pharmacy.routes.js`):
```
GET  /list       authenticate                          listing (cached in client; auth but any role)
POST /inventory   authenticate + authorize(PHARMACY)    updateInventory
```

---

## 12. Admin / Other Routes (for admin shell tables)

Not all invoked from patient build, but keep these for admin screens when you rebuild them:

| Endpoint | Method | Auth | Body/Query |
|---|---|---|---|
| `GET  /api/users` | GET | authorize ADMIN | list users, `?role&page&limit` |
| `GET  /api/facilities` etc. (healthcare-facilities router, if mounted) | — | ADMIN | CRUD |
| `GET  /api/appointments` (alias of consultations list) | GET | ADMIN | `?status` |
| `GET  /api/reports` | GET | ADMIN | reports aggregation |
| `POST /api/asha-workers` etc. | — | — | ASHA sync |

Discover concrete validators/controllers in `backend/src/validators/*` + `controllers/*`; the routers listed in §globals enumerate them all.

---

## 13. Offline-First & Sync Queue (`lib/data/local_database.dart` + `lib/services/sync_service.dart`)

### Database

```dart
// local_database.dart:21-58
LocalDatabase.instance = sqflite.openDatabase('gramhealth_offline.db', version:4)
  sync_queue(entity_type, operation, endpoint, payload, created_at, retry_count)
  cached_consultations(id TEXT PK, data TEXT json)
  cached_prescriptions
  cached_users
  cached_doctors
  cached_records
  cached_pharmacies
  onUpgrade: 2→cached_doctors, 3→cached_records, 4→cached_pharmacies
  clearAllData() deletes every cache table + sync_queue (called on login+logout for isolation)
  enqueueSync({id:uuid, entityType, operation: POST|PATCH|DELETE, endpoint: full URL, payload: Map})
  getSyncQueue() → rows ordered created_at ASC
  removeSyncItem(id)
  incrementRetry(id, currentCount) → retry_count = currentCount+1
  cacheData(table, id, json) → insert replace
  getCachedData(table, id)
  getAllCachedData(table)
```

### Sync Engine

```dart
// sync_service.dart: SyncService.instance.initialize() — singleton
_networkSubscription = ConnectivityService.statusStream.listen((status){
  if status==online||weak { processQueue(); PharmacyService.syncPharmacies().catch... }
})
if init currentStatus != offline { processQueue(); syncPharmacies() }

push({entityType, operation, endpoint, payload}) async {
  if currentStatus != online:
    uuid=v4(); enqueueSync(...); return {status:'PENDING_SYNC', id:uuid}
  else try {
    if operation==POST => ApiClient.post(endpoint,payload)
    else if PATCH => ApiClient.patch(endpoint,payload)
    else if DELETE=> ApiClient.delete(endpoint)
  } catch(e) {
    print('Network error fallback to queue');
    uuid=v4(); enqueueSync(...); return {status:'PENDING_SYNC', id:uuid, error:e.toString()}
  }
  // so every write either hits backend or queues — never fails silently
}

processQueue() async {
  if _isSyncing return; // mutex
  _isSyncing=true
  queue = await LocalDatabase.getSyncQueue()
  for task in queue:
    if currentStatus==offline break
    {id,entity_type,operation,endpoint,payload(jsonDecode), retry_count}
    if retry_count>=5 { print max retries; continue } // kept for manual review, not removed
    try {
      if operation==POST  => await ApiClient.post(endpoint,payload); try delete cached_${entityType}s draft row where id==task.id // removes optimistic temp (sync_service:122-125)
      else if PATCH => await ApiClient.patch(endpoint,payload)
      else if DELETE=> await ApiClient.delete(endpoint)
      await removeSyncItem(id)
    } catch(e) {
      if e.toString().contains('409') { // conflict
        await incrementRetry(id,999) // max out → stop retrying that item
      } else {
        await incrementRetry(id, retry_count)
      }
    }
  _isSyncing=false
}
```

Every writer in the app that uses `SyncService.push` (consultations accept/complete/create, prescriptions create, records upload offline path, medical lookup is read-only) is covered. Replicate calls **exactly** with same `entityType`/`operation`/`endpoint` triples so queue replay reconstructs correctly.

---

## 14. Health Ping + Network-Aware Behaviour Consumers

- `ConnectivityService._pingServer` (`GET ${baseUrl}/api/health timeout 5s`) must remain a **raw `http.get`** (not via ApiClient) to avoid auth noise.
- Teleconsultation `weak` hides Video option; ChatBot/SymptomChecker fallback decisions depend on `isNetworkOrBackendUnavailable` not on `currentStatus` alone (AiService has its own 120s post timeout and 502/503 detection).
- `CallService.startCall` uses `flutter_phone_direct_caller` first and **falls back to `context.push('/video-call/:id')`** whenever the direct caller returns `false` or throws — keep both branches (`call_service:44-59`).

---

## 15. Attachment Upload Shape (Health Vault)

```dart
// medical_record_service.uploadManualRecord(title,type,fileUrl)
if offline: fileUrl remains base64 data URI (e.g. 'data:image/jpeg;base64,...')
  recordData = { id:offline_temp_..., patientId:'self', title, documentType:type, fileUrl, issuedDate:now, createdAt:now, source:'MANUAL' }
else: POST body JSON { title, documentType, fileUrl, issuedDate:now }
  expects 201 { data: recordJSON } else Exception('Failed to upload record: ...')
```

Server stores `fileUrl` as transmitted (base64 strings survive intact). New frontend: keep same on-disk type — `fileUrl: string` (may be `data:` URI). Viewer in `PatientRecordsScreen` already handles both (see §6).

---

## 16. Minimal Wiring Checklist for New Frontend

1. Copy `lib/config/app_config.dart` verbatim (keep `useProduction:true`, `liveBackendUrl`).
2. Copy `lib/services/api_client.dart`, `lib/data/local_database.dart`, `lib/services/connectivity_service.dart`, `lib/services/sync_service.dart`, `lib/services/auth_service.dart` verbatim — or reimplement with same public symbols (`isLoggedIn`, `getToken`, `push`, etc.).
3. Copy `lib/services/{consultation,doctor,patient,medical_record,prescription,pharmacy,call,ai}_service.dart` or implement with same method names, endpoint strings, and `SyncService.push` routing for offline writes.
4. Ensure `main()` calls `AuthGuard.init()`, `ConnectivityService.initialize()`, `SyncService.initialize()` before `runApp` (`main:54-60`).
5. AI: import `AiService.query` with the exact 120s `http.post` + 401/403 no-fallback + 502/503 fallback to `OfflineAiService` pattern (§5).
6. PM2 / Render: no `.env` change other than confirming `GRAM_AI_URL` is set on the Render Node service (it already is). Do not embed `GRAM_AI_URL` in the Flutter build.
7. Run once on device: `adb reverse tcp:3000 tcp:3000` for local dev only — never in release.
8. Verify immediately after wiring:
   - `GET /api/health` returns 200 (controls online chip).
   - `POST /api/auth/register` then `POST /api/auth/login` returns `token + user`.
   - `GET /api/doctors` returns list (use bearer).
   - `POST /api/ai/query` with `{query:"hello who is gramhealth"}` returns 200 with `data.answer` (proves Node→Python path is alive).
   - Toggle airplane mode: create a consultation → observe `PENDING_SYNC` + `sync_queue` row → re-enable network → observe `processQueue` drains → row disappears.

---

## 17. All Distinct Backend Endpoints Hit by Frontend (flat list)

```
POST https://gramhealthapp.onrender.com/api/auth/register
POST https://gramhealthapp.onrender.com/api/auth/login
POST https://gramhealthapp.onrender.com/api/auth/reset-password

GET  https://gramhealthapp.onrender.com/api/health

POST https://gramhealthapp.onrender.com/api/ai/query   (Node; proxies to Python AI at GRAM_AI_URL + /agent/query)
 -> Python POST {GRAM_AI_URL}/agent/query               (never call directly from Flutter)
 -> Python POST {GRAM_AI_URL}/patient/ingest            (background, via Node after record upload)

POST https://gramhealthapp.onrender.com/api/consultations
GET  https://gramhealthapp.onrender.com/api/consultations
GET  https://gramhealthapp.onrender.com/api/consultations/:id
PATCH https://gramhealthapp.onrender.com/api/consultations/:id/status
PATCH https://gramhealthapp.onrender.com/api/consultations/:id/accept
PATCH https://gramhealthapp.onrender.com/api/consultations/:id/complete
PATCH https://gramhealthapp.onrender.com/api/consultations/:id/assign-doctor
PATCH https://gramhealthapp.onrender.com/api/consultations/:id/voicenote

GET  https://gramhealthapp.onrender.com/api/doctors
GET  https://gramhealthapp.onrender.com/api/doctors/me
PATCH https://gramhealthapp.onrender.com/api/doctors/me
POST https://gramhealthapp.onrender.com/api/doctors
GET  https://gramhealthapp.onrender.com/api/doctors/consultations
GET  https://gramhealthapp.onrender.com/api/doctors/prescriptions
GET  https://gramhealthapp.onrender.com/api/doctors/medical-records
GET  https://gramhealthapp.onrender.com/api/doctors/:id

GET  https://gramhealthapp.onrender.com/api/patients/me
PATCH https://gramhealthapp.onrender.com/api/patients/me

POST https://gramhealthapp.onrender.com/api/medical-records/upload
GET  https://gramhealthapp.onrender.com/api/medical-records/me
GET  https://gramhealthapp.onrender.com/api/medical-records/patient/:patientId
GET  https://gramhealthapp.onrender.com/api/medical-records/:id
POST https://gramhealthapp.onrender.com/api/medical-records/     (doctor create)

POST https://gramhealthapp.onrender.com/api/prescriptions
GET  https://gramhealthapp.onrender.com/api/prescriptions/me
GET  https://gramhealthapp.onrender.com/api/prescriptions/:id

GET  https://gramhealthapp.onrender.com/api/pharmacy/list
POST https://gramhealthapp.onrender.com/api/pharmacy/inventory

(Admin / ASHA ancillary — keep mounted but not required for MVP patient build)
GET  https://gramhealthapp.onrender.com/api/users/*
GET  https://gramhealthapp.onrender.com/api/asha-workers/*
```

All of the above use `Authorization: Bearer <Prefs token>` unless explicitly listed as `auth:false` (health + auth endpoints). Replicate exact query params (`page, limit, status, query`) and `Content-Type: application/json`.

---

*Next: `04-offline-chatbot-spec.md` — the fully on-device fallback: Qwen .tflite model, liteRT-LM runtime, safety-router → lexicon → LLM hierarchy, bundled shards, and how to produce identical responses bit-for-bit when rebuilt.*
