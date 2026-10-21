# GramHealth Frontend Rebuild — Implementation Plan

**Status:** Draft for review — do not code until approved
**Source of truth:** `docs/frontend-rebuild/01-roles-screens-buttons-functions.md`, `02-navigation-interaction-map.md`, `03-backend-connections.md`, `04-offline-chatbot-spec.md` + `PRODUCT.md`, `PROJECT_STRUCTURE.md`, `.impeccable/design.json`
**Current state:** `GramHealth/` is empty (deleted for rebuild). Backend at `https://gramhealthapp.onrender.com` unchanged.

---

## 1. Goal & Constraints

**Goal:** Rebuild Flutter client from scratch with premium UI/UX that fixes prior poor experience while preserving every functional contract.

**Non-negotiables:**
- Flutter offline-first client, Android-first (phones + tablets). iOS target preserved but not priority.
- Preserve auth, role guards, API/service architecture, offline cache+sync, healthcare privacy. Backend is sole gateway — never call Python AI directly.
- 4 roles: patient/asha → `/main/*`, doctor → `/doctor/*`, pharmacy → `/pharmacy/dashboard`, admin → `/admin/*` + public `/`, `/onboarding`, `/login`, `/forgot-password`.
- 4 locales en/hi/mr/gu via `LanguageController` + `translations.dart` — no English-only truncations.
- Single primary action per screen, high-contrast opaque surfaces (Clear Careway), 48dp min touch (52dp primary/emergency), pass a11y, offline/error/empty/permission states first-class.

---

## 2. Design Authority — Clear Careway (`.impeccable/design.json`)

Adopt the already-generated Clear Careway system as replacement world (replaces leaf/glass incumbents):

- **Palette:** Ink #17211D, Clear Teal #007A6E / Mint #D5F3EC, Sunlit Amber #F0A624, Warm Coral #D9584B, Emergency #B3261E, Ground #F7FAF7, Surface #FFFFFF. No glassmorphism — opaque cards, tonal elevation, `ambient-low`/`ambient-raised` shadows only.
- **Typography:** Manrope Display (one per screen), Atkinson Hyperlegible Body/Label (16sp min, verified at 1.3x scale). Two-weight rule.
- **Motion:** `ease-standard` 180ms state / 280ms route; single FAB; CustomPainters sparse + semantic.
- **Rules:** Careway Rule (next safe action > decoration), Signal Budget (one dominant + one support color), Breathing Room (heading top gap > bottom), Opaque Surface Rule.
- **Breakpoints:** compact <600dp (NavBar), medium 600–839dp (Rail/drawer), expanded ≥840dp (persistent nav + 1200dp max content).

Refinement vs redesign decision: This is a **replacement visual world** — keep product truth/content/function/role boundaries, discard prior leaf-green glass look as anti-reference. Reuse Material 3 `ColorScheme.fromSeed` tuned to Clear Teal, `AppColors`/`AppTheme` tokens, `AppRadii`.

---

## 3. Architecture Snapshot

**Boot:** `main() → AuthGuard.init() (prefs token/user) → ConnectivityService.initialize() (10s ping GET /api/health) → SyncService.initialize() (drains sync_queue + syncPharmacies when online) → GoRouter(initialLocation:'/', redirect:AuthGuard.redirect) → RuralCareApp ValueListenableBuilder(lang)`.

**AuthGuard:** sync in-memory `_cachedRole` from SharedPreferences; public routes `/`, `/onboarding`, `/login`, `/forgot-password`; logged-in bounce to `_dashboardFor(role)`; prefix guards for `/main`, `/doctor`, `/admin`, `/pharmacy`.

**Data layer:** `sqflite gramhealth_offline.db v4` — tables `sync_queue`, `cached_consultations/prescriptions/users/doctors/records/pharmacies`. `LocalDatabase.clearAllData()` on every login/logout. `SyncService.push()` queues when `currentStatus != online` else `ApiClient` (35s timeout) with 5-retry + 409 conflict handling.

**API:** `AppConfig.baseUrl = useProduction ? https://gramhealthapp.onrender.com : adbReverse/lan`. `ApiClient` Bearer `gram_health_token`. `AiService.query` 120s + `X-Request-ID`, 401/403 no fallback, 502/503 fallback to `OfflineAiService`. See doc 03 §17 for 22 distinct endpoints.

**Offline AI:** `OfflineAiRouter` 5-level hierarchy: L2 emergency (safety sets 70+ keywords) → L3 lexicon+LLM (only if `enableLocalLlmRuntime==true` + `loaded/generating`, currently false) → L4 lexiconOnly (production path, formatted header + 3 entries) → L5 unavailable/noInformation. Model Qwen2.5-0.5B-Instruct_seq128_q8_ekv1280.tflite 513MB, sha `49b3b...6032ac`, LiteRT-LM via `gramhealth/offline_llm` MethodChannel. Lexicon `assets/offline_medical/manifest.json + 13 shards *.json.gz`.

---

## 4. Ordered Task List

### Phase 0 — Scaffolding (1 day, blocking)
- [ ] 0.1 `flutter create GramHealth --platforms android,ios --org com.gramhealth` → restore `pubspec.yaml` deps: `go_router`, `google_fonts`, `shared_preferences`, `sqflite`, `http`, `connectivity_plus`, `geolocator`, `geocoding`, `image_picker`, `cached_network_image`, `flutter_phone_direct_caller`, `url_launcher`, `record`, `audioplayers`, `jitsi_meet_wrapper ^0.2.0+1`, `crypto`, `intl`, `flutter_localizations` + assets `assets/images/`, `assets/offline_medical/{manifest,metadata,shards/*.json.gz}`.
- [ ] 0.2 Copy verbatim `lib/config/app_config.dart` (keep `useProduction:true`, `liveBackendUrl`, `tokenKey/userKey`) + `assets` declarations. Verify `GET /api/health` 200.
- [ ] 0.3 Establish `lib/main.dart` boot sequence + `l10n/app_language.dart` + `translations.dart` + `utils/auth_guard.dart` (exact redirect tree doc 02).

### Phase 1 — Core Infrastructure
- [ ] 1.1 `data/local_database.dart` v4 + `services/{api_client,connectivity_service,sync_service,auth_service}.dart` verbatim public symbols.
- [ ] 1.2 Remaining services: `consultation_service`, `doctor_service`, `patient_service`, `medical_record_service`, `prescription_service`, `pharmacy_service`, `call_service`, `ai_service` (120s, header shape, emergency pre-check, timeout 45s in symptom checker).
- [ ] 1.3 Models: `ai_response`, `clinical_response` (9 sections + `standardDisclaimer` + `RiskLevel`), `offline_response`, `medical_lexicon_entry`, `local_model_status`, `offline_model_metadata`.

### Phase 2 — Design System & Shared Widgets
- [ ] 2.1 `theme/app_colors.dart` + `theme/app_theme.dart` mapped to Clear Careway ramps (Ink/Teal/Mint/Amber/Coral/Emergency/Ground/Surface) + `AppRadii` + shadows/motion/breakpoints from design.json.
- [ ] 2.2 Reusable widgets replacing GlassCard: `CareCard` (opaque, 1px #EAF1ED, 14r, ambient-low), `PrimaryButton` (48h, 10r, Teal #007A6E), `TonalButton` (Mint), `EmergencyButton` (Red), `InputField` (opaque, 56h, focus 2px Teal + Mint wash), `StatusChip`, `CareChip` (pill, sage vs white), `ConnectivityBadge`/`OfflineStatusIndicator`, `StatCard`, `StatusBadge`, `LoadingState`/`EmptyState`, `SearchBar`, `FilterDropdown`, `LanguageSelectorModal` (bottom sheet en/hi/mr/gu radios).
- [ ] 2.3 Layout shells: `MainShell` (NavigationBar 80dp, sagePale indicator, 5 tabs `tr: tab_home/doctors/symptoms/records/profile` → `context.go`), `DashboardLayout`+`Sidebar` (admin, responsive wrap, selected index ↔ `GoRouter`).

### Phase 3 — Auth & Onboarding (public routes)
- [ ] 3.1 `SplashScreen` — animated logo glow/scale 1.0→1.2 + text fade/slide + `PrimaryButton Get Started → context.go('/onboarding')`.
- [ ] 3.2 `OnboardingScreen` — language pill `showLanguageSelector`, blobs (8s/10s), rotating quotes `quote_1..5` 5s `AnimatedSwitcher`, `SlideButton onComplete → /login`.
- [ ] 3.3 `LoginScreen` — mode toggle `_isRegistering`, role chips patient/doctor/admin/pharmacy → `setState _selectedRole`, fields (name/phone/email/pass/confirm), pharmacy address → `geocoding locationFromAddress` → lat/lng, validation (required, email regex, pass ≥8, match), `PrimaryButton _handleLogin/_handleRegister` → `AuthService` → `AuthGuard.onLogin` → `_navigateByRole`, SnackBar (redAccent 12r), `Forgot Password? → /forgot-password`.
- [ ] 3.4 `ForgotPasswordScreen` — email/phone + new/confirm + `AuthService.resetPassword POST /api/auth/reset-password` → SnackBar → `/login`.

### Phase 4 — Patient Core
- [ ] 4.1 `HomeScreen (/main/home)` — `_loadUser/_loadDoctors/_loadConsultations(ACTIVE)` + `OfflineAiService.initialise→checkModelOnStartup`; header (ConnectivityBadge, lang pill, bell `push /notifications`, avatar `go /main/profile`), banner Learn more `push /notifications`, `OfflineSetupCard`, Active Consultations strip (online Join/Audio `CallService.startCall + updateStatus COMPLETED` / offline Record Note `VoiceNoteDialog` + Call Doctor), Services 6-card Wrap (Consult→/main/doctors, Symptoms→/main/symptoms, Medicine→push /medicine, Records→/main/records, Emergency→push /emergency, Prescriptions→/prescriptions), Specialists (Explore all, 5 filter pills → spec keyword filter, 148h horizontal cards avatar 84, `push /doctor-details/:id`, Book now `push /teleconsultation-request extra{doctorId,doctorName}`), FAB chat `push /chatbot`.
- [ ] 4.2 `DoctorListScreen (/main/doctors)` — `DoctorService.getDoctors()` with search `onChanged` filter + spec chips, card tap `push /doctor-details/:id`, videocam + Book bar `push /teleconsultation-request`, retry/loading/empty.
- [ ] 4.3 `DoctorDetailsScreen (/doctor-details/:id)` — avatar/spec/hospital/rating/exp/bio/availability/fee, Book Teleconsultation `push /teleconsultation-request extra{doctorId,doctorName,doctorPhone}`, Call `CallService.startCall → tel: else push /video-call/:id`.
- [ ] 4.4 `SymptomCheckerScreen (/main/symptoms)` — 7 chips multi-select + other TextField + mic pulse, `_analyze`: emergency `isEmergency→ ClinicalResponse.emergency` no network; else `AiService.query("I have... $combinedQuery").timeout(45s)` → `condition Clinical Assessment (intent)`, `_clinicalResult/_resultSource`, else offline `queryOffline + buildSymptomCheckerContext` fallback, render `StructuredClinicalResponseCard` or 4-row Glass→CareCard + disclaimer.
- [ ] 4.5 `PatientRecordsScreen (/main/records)` — `MedicalRecordService.getMyRecords()` (GET /medical-records/me or cache), upload eye `Navigator.push(UploadRecordScreen)` → `if true _fetchRecords`, retry/empty, eye `data:image→ Dialog InteractiveViewer(Image.memory(base64)) else launchUrl`, offline `cached_records` fallback.
- [ ] 4.6 `UploadRecordScreen` (Navigator push) — Camera/Gallery `ImagePicker→ base64 data:image`, title/type, Upload 56h amber `uploadManualRecord` (offline optimistic `offline_temp_` + `SyncService.push POST /medical-records/upload` else `http.post 201`) → `pop(true)`.
- [ ] 4.7 `HealthOverviewScreen (/health-overview)` — demo hardcoded, pulse 1500ms, hotspots, metric cards, 162cm/64kg card (visual only).
- [ ] 4.8 `ProfileScreen (/main/profile)` — load `AuthService.getUser()`, 6 controllers, avatar, Edit/Save pill, info `CareCard` rows (email/phone/age/gender/pin/blood/ABHA), expanded edit form `handleSave`, Language `showLanguageSelector`, Notifications `push`, Logout `AuthGuard.onLogout + AuthService.logout clearAllData → go /onboarding`.

### Phase 5 — Consultation & Communication
- [ ] 5.1 `TeleconsultationRequestScreen (/teleconsultation-request)` — reads `extra{doctorId,doctorName,doctorPhone}` + `Connectivity statusStream` (weak forces VIDEO→AUDIO), doctor header, 5 reason chips single-select, VIDEO/AUDIO cards (hidden offline, weak hides Video), symptoms TextField, `OfflineVoiceRecorder onRecordingComplete→ _voiceNoteBase64`, 3 time slots radio, Send request `PrimaryButton → ConsultationService.createConsultation(type:offline?OFFLINE:_selectedType, voiceNoteUrl) via SyncService.push POST /api/consultations` → success green check `request_done` + auto `pop` 1800ms.
- [ ] 5.2 `VideoCallScreen (/video-call/:id)` — `pathParameters id + extra{doctorName,doctorPhone,isAudioOnly}`, jitsi_meet_wrapper, mute/camera/end, fallback from `CallService.startCall` when `FlutterPhoneDirectCaller.callNumber` false.
- [ ] 5.3 Voice notes: `OfflineVoiceRecorder`, `VoiceNoteDialog`/`VoiceNoteHistoryDialog` (record+audioplayers, `PATCH /consultations/:id/voicenote` via SyncService, play).

### Phase 6 — Pharmacy & Medicine
- [ ] 6.1 `PharmacyDashboardScreen (/pharmacy/dashboard)` — `PharmacyService.syncPharmacies GET /api/pharmacy/list → cacheData cached_pharmacies`, inventory table toggle `POST /api/pharmacy/inventory`.
- [ ] 6.2 `MedicineAvailabilityScreen (/medicine?query=)` — query TextField prefill, Search `searchPharmaciesLocal(medicine, lat, lon)` Haversine + sort distance, `PharmacySearchResult` badge + Call/Route `tel:`/`maps`.
- [ ] 6.3 `PrescriptionListScreen (/prescriptions)` — `PrescriptionService.getPrescriptions GET /api/prescriptions/me` + `cached_prescriptions` drafts merge, `MedicationSchedule` sub-rows, View `Dialog toDisplayMap()`.

### Phase 7 — Doctor Role
- [ ] 7.1 `DoctorRequestsScreen (/doctor/requests)` — `listDoctorConsultations(status:PENDING)` via `GET /api/doctors/consultations`, Accept `PATCH /:id/accept via SyncService → ACTIVE`, Reject, VoiceNoteHistoryDialog, tap→ detail.
- [ ] 7.2 `DoctorConsultationsScreen (/doctor/consultations)` — tabs PENDING/ACTIVE/COMPLETED, View/Complete `push DoctorCompleteConsultation`.
- [ ] 7.3 `DoctorCompleteConsultationScreen` — riskLevel chips low/moderate/high/emergency, notes, Complete `PATCH /:id/complete {notes,riskLevel}` → COMPLETED → pop.
- [ ] 7.4 `DoctorPrescriptionsScreen` — `GET /api/doctors/prescriptions` + cache, Create `POST /api/prescriptions via SyncService` draft.
- [ ] 7.5 `DoctorPatients/DoctorAppointments/DoctorProfile/DoctorSettings/DoctorOnboarding` — onboarding form `POST /api/doctors` + `PATCH /doctors/me → go /doctor/requests`, profile `PATCH /doctors/me`, patients `GET /doctors/medical-records` via `MedicalRecordService.getDoctorRecords`.

### Phase 8 — Admin Role (`DashboardLayout+Sidebar`)
- [ ] 8.1 `AdminDashboardScreen` — 6 StatCards (Users 1420, Doctors 48, Patients 1372, Facilities 12, Pharmacies 18, Appointments 320) + Recent Activity `StatusBadge`.
- [ ] 8.2 `AdminUsers/Doctors/Patients/Appointments/Consultations/Prescriptions/Pharmacies/Facilities/Reports/Settings` — tables + `FilterDropdown`/search + inline actions: Edit/Delete `PATCH/DELETE /api/users/:id`, Approve/Reject `PATCH /api/doctors/:id`, View records, Add facility `POST/PATCH/DELETE /api/facilities`, Assign doctor `PATCH /consultations/:id/assign-doctor`, inventory reset `POST /pharmacy/inventory`. Navigation via `Sidebar → context.go('/admin/<section>')`.

### Phase 9 — Common
- [ ] 9.1 `NotificationsScreen (/notifications)` — back `pop`, Mark all read local.
- [ ] 9.2 `EmergencyHelpScreen (/emergency)` — SEND SOS 220/180 `Geolocator getCurrentPosition best → mapsLink sms:phones?body=mapsLink` (ice_contacts prefs else 102/108), First-Aid horizontal 120×100 `AlertDialog`, Emergency response `tel:108`, Nearest PHC `maps search`, Add ICE `Dialog 3 fields → prefs ice_contacts`, contact rows `tel:`.
- [ ] 9.3 `ChatBotScreen (/chatbot)` — back `pop`, subtitle `AI • Online green 4CAF50 / Offline orange FF9800` derived from connectivity + `modelStatus`, `OfflineStatusIndicator` + conditional `OfflineSetupCard`, `ListView` bubbles (user dark, AI white, pill AI•Offline/Online via `agent==offline_ai_router || routingMethod.contains offline`), TextField 1-4 lines + 44 send (sage when hasText), `_handleSend → AiService.query → urgency emergency ? 🚨 + ⚠️ + isOffline tag + scroll`, `ensureModelLoaded()` on init, `modelSub`+`connSub` listeners.

### Phase 10 — Offline Chatbot Last (bit-for-bit)
- [ ] 10.1 `config/offline_ai_config.dart` registry (modelRepoId, filename, 513219800, sha `49b3...`, enableLocalLlmRuntime false, `autoDownload true`, `allowMobileData false`, Wi-Fi gate, `offlineContextMaxChars 1500`, `maxNewTokens 400 temp0.2 topP0.9 topK40`).
- [ ] 10.2 `services/local_model_download_service.dart` (Range resume, 30s chunk timeout, 4MB chunks, 3 retries, `.tmp` atomic rename, `computeSha256`).
- [ ] 10.3 `services/local_model_manager.dart` state machine + `checkModelOnStartup` (if verified → `lexiconOnly` when runtime false else `ready`), `checkNetworkAndTriggerDownload` (Wi-Fi gate, `pending/waiting for Wi-Fi`), `startDownload→ verifying→ ready/lexiconOnly`, `loadModel` early-return lexiconOnly, `listenForConnectivityChanges`.
- [ ] 10.4 Native `android/app/src/main/kotlin/.../GramhealthLlmPlugin.kt` — channels `gramhealth/offline_llm` + `gramhealth/offline_llm_tokens`, tasks-genai 0.10.14 reflection, compatibility (arm64-v8a, api≥26, 700MB storage, 1.5GB RAM), `initialize` CPU backend, `generate` Qwen prompt `<|im_start|>...`, EventChannel streaming `__EOS__`, smokeTest/dispose.
- [ ] 10.5 Lexicon `assets/offline_medical/` manifest 200 keys, `metadata 19 conditions 12 shards`, shards `a,b,c,d,f,h,j,m,o,p,s,t,u.json.gz` GZip, `OfflineMedicalLookupService` LRU 4, `_extractMedicalTerms` (Hindi/Marathi map + spelling variants + stopWords), `_loadShard` decompress.
- [ ] 10.6 `OfflineSafetyService` 11 sets 70+ keywords, `isEmergency/matchedEmergencyTerms/sanitiseGeneratedText` (4 regex → `[Information removed for safety]`).
- [ ] 10.7 `OfflineAiRouter` + `OfflineAiService.instance` + deterministic `ClinicalResponse.emergency` (9 sections, `RiskLevel.emergency 0xD32F2F`) + `OfflineResponse` factories + `OfflineMedicalRepository.buildSymptomCheckerContext` + system prompt verbatim.

### Phase 11 — Polish & Hardening
- [ ] 11.1 i18n verification: `context.tr` everywhere, test hi/mr/gu at 1.3x font scale, no clipped CTAs, persistent labels for chips.
- [ ] 11.2 A11y: Semantics for 48dp targets, status never color-alone (dot + text), 4.5:1 contrast on Teal/Ink/Red, screen-reader labels for hotspot/metrics, `Reduce Motion` → crossfade.
- [ ] 11.3 Responsive: compact/medium/expanded nav models, window/IME insets, keyboard avoidance for fields/voice recorder.
- [ ] 11.4 States: loading/error/empty/offline/permission-denied for every list (DoctorList, Records, Consultations, Pharmacy); OfflineSetupCard only when offline + not ready/lexiconOnly.
- [ ] 11.5 Error taxonomy: `ApiException` 401/400 → SnackBar, 503/504 → offline queue, 409 → max retry; `SyncService.processQueue` mutex + 5-retry.
- [ ] 11.6 Verify `impeccable context` + `craft-floor.md` before any UI edit; one batched visual QA (desktop+mobile) then single fix batch.

---

## 5. Failure Modes & Mitigations

- **Backend cold start (Render):** 35s ApiClient + 120s AiService timeouts → show weak/pending UI, queue writes, retry on statusStream online.
- **Geolocator permission denied:** Teleconsultation & SOS fallback — SOS SnackBar, medicine search without distance sort, pharmacy address geocoding error SnackBar.
- **ImagePicker large base64:** cap preview, store `data:image/...` verbatim, viewer handles both base64 Dialog and `launchUrl`.
- **GGUF 513MB download on mobile data:** `allowMobileDataDownload false` gate + Wi-Fi-only autoDownload, resume via Range, 3 retries, progress persisted prefs.
- **Jitsi/phone dialer unavailable:** `CallService.startCall` try `FlutterPhoneDirectCaller.callNumber` → on false/throw `push /video-call/:id`.
- **Multi-user leakage:** `clearAllData()` on login+logout, `AuthGuard` prefix bounces.

---

## 6. Validation Plan

1. **Wiring checklist (doc 03 §16):** `GET /api/health` 200, register→login→ token+user, `GET /api/doctors` list, `POST /api/ai/query {query:"hello who is gramhealth"}` 200 + `data.answer`, airplane create consultation → `PENDING_SYNC` + `sync_queue` row → online drains.
2. **Navigation:** Test AuthGuard matrix (unauth deep link → /onboarding, patient hitting /doctor/* → bounce to /main/home etc.), `go` vs `push` (only UploadRecord uses `Navigator.push` with `bool` return).
3. **Offline:** Kill network, ChatBot shows `AI • Offline` + SetupCard, query lexicon term `bukhar` → lexiconOnly card with 3 warnings, emergency term `chest pain` → double 🚨 banner + emergency ClinicalResponse, SymptomChecker Analyze → fallback context.
4. **Visual QA:** One batched pass desktop+mobile per skill `craft-floor.md` bans (no glass/blur, no muddy olive, no emoji as system, no nested dashboard tiles).

---

## 7. Open Questions (resolve before coding)

1. **Patient MVP vs all roles parallel?** Recommend patient MVP first (Phases 0-6+9 partially) then doctor/pharmacy/admin — confirms highest user value + unblocks backend wiring early.
2. **Confirm Clear Careway as final world?** Design.json is already built — reuse vs tweaking palette/typography.
3. **Keep package `ruralcare_flutter` / title `RuralCare` until canonical GramHealth rename?** PRODUCT.md says preserve both.
4. **Enable LLM runtime now or keep lexiconOnly safe mode?** Recommend keep `false` for V1 to guarantee deterministic bit-for-bit offline answers.

---

*End of plan. Awaiting approval to proceed to coding.*
