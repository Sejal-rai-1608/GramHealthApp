# GramHealth Frontend Rebuild — 01 / Roles × Screens × Buttons × Functions

> **Purpose:** Nothing-to-miss inventory for recreating the entire Flutter UI from scratch.
> **Source of truth:** `GramHealth/lib/**/*.dart` read verbatim on 2026-10-16. File paths = `GramHealth/lib/...` unless stated.
> **App identity:** `ruralcare_flutter` / `RuralCare` (§ `pubspec.yaml` v1.0.0+1, `lib/main.dart:212`).

---

## 1. Roles & Route Guards

Auth state is **synchronous in-memory** (`lib/utils/auth_guard.dart:14` `AuthGuard._cachedRole`, populated by `AuthGuard.init()` from `AuthService` SharedPreferences). GoRouter `redirect: AuthGuard.redirect` (`lib/main.dart:64`).

| Role string (lowercase) | Dashboard target (`AuthGuard._dashboardFor`) | Guarded prefix | How role is set |
|---|---|---|---|
| `patient` (default), `asha` | `/main/home` | `/main/*` (`lib/utils/auth_guard.dart:65`) | `AuthService.login` saves `user['role']`, `AuthGuard.onLogin(role)` called in `LoginScreen._navigateByRole` |
| `doctor` | `/doctor/requests` | `/doctor/*` (`auth_guard.dart:59`) | same |
| `admin` | `/admin/dashboard` | `/admin/*` (`auth_guard.dart:62`) | same |
| `pharmacy` | `/pharmacy/dashboard` | `/pharmacy/*` (`auth_guard.dart:68`) | same |

Public routes (no auth): `/`, `/onboarding`, `/login`, `/forgot-password` (`auth_guard.dart:46`). Logged-in user hitting `/login` or `/onboarding` is bounced to role dashboard.

Registration roles shown in UI: `patient` → User, `doctor`, `admin`, `pharmacy` (`login_screen.dart:362-374`). Registration payload sends `role.toUpperCase()` (`auth_service.dart:150`). For `pharmacy`, registration requires **address → geocoding** via `geocoding.Geocoding().locationFromAddress` to obtain `latitude/longitude` (`login_screen.dart:152-163`).

---

## 2. Complete Route Table (`lib/main.dart:62-199`)

| # | Path | Builder | Extra / params | Shell |
|---|---|---|---|---|
| 1 | `/` | `SplashScreen` | — | — |
| 2 | `/onboarding` | `OnboardingScreen` | — | — |
| 3 | `/login` | `LoginScreen` | — | — |
| 4 | `/forgot-password` | `ForgotPasswordScreen` | — | — |
| 5 | `/main` | `MainShell(child: HomeScreen)` | redirect target for patient/asha | `MainShell` (bottom nav) |
| 5a | `/main/home` | `MainShell(child: HomeScreen)` | patient home | MainShell |
| 5b | `/main/doctors` | `MainShell(child: DoctorListScreen)` | doctor search | MainShell |
| 5c | `/main/symptoms` | `MainShell(child: SymptomCheckerScreen)` | patient symptom checker | MainShell |
| 5d | `/main/records` | `MainShell(child: PatientRecordsScreen)` | patient health vault | MainShell |
| 5e | `/main/profile` | `MainShell(child: ProfileScreen)` | patient profile | MainShell |
| 6 | `/doctor` | `DoctorRequestsScreen` | doctor dashboard | — |
| 6a | `/doctor/requests` | `DoctorRequestsScreen` | pending requests inbox | — |
| 6b | `/doctor/consultations` | `DoctorConsultationsScreen` | active past consults | — |
| 6c | `/doctor/prescriptions` | `DoctorPrescriptionsScreen` | my prescriptions | — |
| 6d | `/doctor/profile` | `DoctorProfileScreen` | doctor profile | — |
| 6e | `/doctor/onboarding` | `DoctorOnboardingScreen` | new-doctor professional details | — |
| 7 | `/admin` | `AdminDashboardScreen` | admin shell | DashboardLayout + Sidebar |
| 7a | `/admin/dashboard` | `AdminDashboardScreen` | KPI + activity | DashboardLayout |
| 7b | `/admin/users` | `AdminUsersScreen` | user table | DashboardLayout |
| 7c | `/admin/doctors` | `AdminDoctorsScreen` | doctor table | DashboardLayout |
| 7d | `/admin/patients` | `AdminPatientsScreen` | patient table | DashboardLayout |
| 7e | `/admin/appointments` | `AdminAppointmentsScreen` | appointment table | DashboardLayout |
| 7f | `/admin/consultations` | `AdminConsultationsScreen` | consultation table | DashboardLayout |
| 7g | `/admin/prescriptions` | `AdminPrescriptionsScreen` | prescription table | DashboardLayout |
| 7h | `/admin/pharmacies` | `AdminPharmaciesScreen` | pharmacy table / inventory | DashboardLayout |
| 7i | `/admin/healthcare-facilities` | `AdminFacilitiesScreen` | facility CRUD | DashboardLayout |
| 7j | `/admin/reports` | `AdminReportsScreen` | reports / charts | DashboardLayout |
| 7k | `/admin/settings` | `AdminSettingsScreen` | system settings | DashboardLayout |
| 8 | `/pharmacy/dashboard` | `PharmacyDashboardScreen` | pharmacy inventory | — |
| 9 | `/notifications` | `NotificationsScreen` | — | — |
| 10 | `/chatbot` | `ChatBotScreen` | — | — |
| 11 | `/doctor-details/:id` | `DoctorDetailsScreen(doctorId: id)` | `pathParameters['id']` | — |
| 12 | `/teleconsultation-request` | `TeleconsultationRequestScreen` | `extra: {doctorId, doctorName, doctorPhone}` (`teleconsultation_request_screen.dart:38`) | — |
| 13 | `/prescriptions` | `PrescriptionListScreen` | medicines inventory / patient prescriptions | — |
| 14 | `/video-call/:id` | `VideoCallScreen(doctorId: id)` | `pathParameters['id']`, `extra: {doctorName, doctorPhone, isAudioOnly}` (`call_service.dart:49`) | — |
| 15 | `/medicine` | `MedicineAvailabilityScreen(medicineQuery: query)` | `queryParameters['query']` | — |
| 16 | `/health-overview` | `HealthOverviewScreen` | hardcoded demo patient | — |
| 17 | `/doctor/consultations` (+ push from `UploadRecordScreen` via `Navigator.push` fallback) | `UploadRecordScreen` | `Navigator.push(MaterialPageRoute(builder: UploadRecordScreen))` from `PatientRecordsScreen:55,65` | — |

**Global entry:** `main() async` calls `AuthGuard.init()`, `ConnectivityService.instance.initialize()`, `SyncService.instance.initialize()` before `runApp` (`main.dart:54-60`).

---

## 3. Shared Widgets Catalogue (`lib/widgets/`)

| Widget | Props / API | Purpose | Used by |
|---|---|---|---|
| `GlassCard` | `child`, `padding`, `borderRadius`, `borderColor`, `color` | blurred card paper (paper bg + outline border) | Home, DoctorList, Patient screens, Chatbot input, HealthRecords, Emergency, etc. |
| `PrimaryButton` | `title`, `onPress`, `width` | amber/sage CTA | Splash, Login, SymptomChecker, Teleconsultation |
| `SlideButton` | `title`, `onComplete` | swipe-to-continue | Onboarding bottom card |
| `CustomInput` | `label`, `placeholder`, `controller`, `obscureText` | form field (login/register/profile) | Login, Profile |
| `TopNavbar` | — | patient web header (out of scope for handset but present) | DashboardLayout |
| `Sidebar` / `DashboardLayout` | `title`, `child` | admin shell: left nav + header | All `admin/*` screens |
| `SearchBar` | `controller`, `onChanged` | doctor search | DoctorList |
| `FilterDropdown` | `value`, `items`, `onChanged` | role filters | Admin tables |
| `StatusBadge` | `status` (Completed/Active/Resolved etc.) | pill badge | Admin dashboard |
| `StatCard` | `icon`, `label`, `value` | KPI tile | Admin dashboard |
| `ConnectivityBadge` | (reads `ConnectivityService`) | Online/Weak/Offline pill | HomeScreen header |
| `OfflineStatusIndicator` | `isOnline` | small dot / label | ChatBot header |
| `OfflineSetupCard` | `onDismiss` | GGUF download progress / prompt | Home, ChatBot |
| `OfflineVoiceRecorder` | `doctorPhone`, `doctorName`, `onRecordingComplete(base64)` | record module (record + audioplayers) | TeleconsultationRequest, Home active-consultations |
| `VoiceNoteDialog` / `VoiceNoteHistoryDialog` | `consultationId` | record + play for a consultation | HomeScreen offline row |
| `MedicineFormCard` | — | pharmacy add-medicine form row | PharmacyDashboard |
| `MedicationSchedule` | — | prescription meds schedule | PrescriptionList |
| `StructuredClinicalResponseCard` | `response: ClinicalResponse`, `sourceLabel` | 9-section AI/medical card | SymptomChecker |
| `LoadingState` / `EmptyState` | message | placeholder | DoctorList, PatientRecords, etc. |
| `LanguageSelectorModal` (`showLanguageSelector`) | — | bottom sheet radio for en/hi/mr/gu | Home, ChatBot, Onboarding, Login, Profile |

Theme: `lib/theme/app_colors.dart` leaf ramp + `AppTheme.theme` (Material 3 `ColorScheme.fromSeed(leafGreenPrimary)` + `GoogleFonts.inter`), `lib/theme/app_theme.dart`. Radii constants `AppRadii.{sm,md,lg,pill}`.

---

## 4. Per-Screen Detail

### 4.1 SplashScreen (`lib/screens/common/splash_screen.dart`)

| Element | Widget | Handler / Navigation |
|---|---|---|
| Animated logo glow + scale | `ScaleTransition` on `AnimationController _logoCtrl` (repeat reverse 1000ms), `_textCtrl` fade+slide | — |
| Title “RuralCare” + tagline | `Text` | — |
| **Get Started** | `PrimaryButton(title: 'Get Started')` | `onPress: () => context.go('/onboarding')` (`:166`) |

State: `TickerProviderStateMixin`, `_logoScale 1.0→1.2`, `_textOpacity 0→1`, `_textSlide 20→0` (500ms delay).

### 4.2 OnboardingScreen (`lib/screens/common/onboarding_screen.dart`)

| Element | Widget | Handler |
|---|---|---|
| Language selector pill (top-right) | `GestureDetector` | `showLanguageSelector(context)` (`:91`) |
| Decorative plus icon | static | — |
| Floating quote card (rotating among `quote_1..quote_5`, 5s interval via `Future.doWhile`) | `AnimatedSwitcher` | `context.tr(_quoteKeys[_quoteIndex])` |
| Floating icons (heart, chart) | `Container` with `BoxShadow` | — |
| Animated blobs background | `_buildBlobs()` with two `AnimationController` (8s, 10s) | — |
| Title `care_made_simple` + `onboarding_desc` | `Text` | — |
| **SlideButton** | `SlideButton(title: 'get_started', onComplete)` | `context.go('/login')` (`:265`) |

### 4.3 LoginScreen (`lib/screens/common/login_screen.dart`) — Login + Registration

Mode toggle: `_isRegistering` bool, text switch, `setState(() => _isRegistering = !_isRegistering)` (`:451`).

**Login mode buttons:**

| Button | Handler | Effect |
|---|---|---|
| Email/Phone field + Password | `CustomInput` | trim + send to `AuthService.login(email, password)` |
| **Forgot Password?** | `GestureDetector` | `context.go('/forgot-password')` (`:413`) |
| **Continue / Sign in** | `PrimaryButton` → `_handleContinue` → `_handleLogin` | `AuthService.login` → `AuthGuard.onLogin(role)` → `_navigateByRole(role)` (`:57` → role → `/admin/dashboard` \| `/doctor/requests` \| `/pharmacy/dashboard` \| `/main/home`) |
| Toggle link “Register new account” | `GestureDetector` | flips `_isRegistering` |
| Language pill | `GestureDetector` | `showLanguageSelector` |

**Register mode extra fields:**

| Field | Widget | Handler |
|---|---|---|
| Role chips (User / Doctor / Admin / Pharmacy) | `_buildRoleCard(role, icon, title)` ×4, `onTap: setState(_selectedRole = role)` (`:212`) | sets `_selectedRole` ∈ `patient, doctor, admin, pharmacy` |
| Full Name, Phone, Email, Password, Confirm Password | `CustomInput` | validation: required, email regex `^[\w-\.]+@...`, password ≥8, confirm match (`:123-138`) |
| Pharmacy Address (only when `_selectedRole == 'pharmacy'`) | `CustomInput(controller: _addressCtrl)` | geocoded via `geocoding.Geocoding().locationFromAddress` (`:154`) → `latitude/longitude`; error SnackBar on failure |
| **Register** | `PrimaryButton` → `_handleRegister` | `AuthService.register(name,email,phone,password,role,address,latitude,longitude)` → then `AuthService.login` auto-login; if `role == 'doctor'` → `context.go('/doctor/onboarding')` else `_navigateByRole` (`:180-184`) |

Error surfaces: `SnackBar` (redAccent, floating, radius 12) via `_showError`. Handles `ApiException` 401/400→“Invalid email or password”, 503→“Backend unreachable. ADB reverse”, 504→timeout.

### 4.4 ForgotPasswordScreen (`lib/screens/common/forgot_password_screen.dart`)

| Element | Handler |
|---|---|
| Email/Phone `CustomInput` | — |
| New Password + Confirm | — |
| **Reset Password** | `AuthService.resetPassword(emailOrPhone: ..., newPassword: ...)` (`POST /api/auth/reset-password`) → `SnackBar` success → `context.go('/login')` (`:74`) |
| **Back to Login** | `context.go('/login')` (`:94,164`) |

### 4.5 HomeScreen `MainShell > HomeScreen` (`lib/screens/common/home_screen.dart`) — PATIENT

**Init:** `_loadUser()` (from `AuthService.getUser()`), `_loadDoctors()` (`DoctorService.getDoctors()`), `_loadConsultations()` (`ConsultationService.listConsultations(status: 'ACTIVE')`), `OfflineAiService.instance.initialise() → checkModelOnStartup()` (`:42`).

**Header row:**

| Button | Handler |
|---|---|
| `ConnectivityBadge` | reads `ConnectivityService` stream |
| Language pill (current language nativeName) | `showLanguageSelector` |
| Notifications bell (44×44 paper, outline border) | `context.push('/notifications')` (`:145`) |
| Avatar circle (first letter of `_userName`) | `context.go('/main/profile')` (`:147`) |

**Banner (free checkup)**

| Button | Handler |
|---|---|
| **Learn more** (amber ElevatedButton) | `context.push('/notifications')` (`:165`) |

**OfflineSetupCard** — `const OfflineSetupCard()` (`:172`) (shows GGUF progress, Wi-Fi gate, dismiss).

**Active Consultations section** (`_activeConsultations: List<ConsultationModel>` where `status == 'ACTIVE'`):

| State | Buttons | Handlers |
|---|---|---|
| Online | **Join** (VIDEO) / **Audio** pill (`ElevatedButton`) | `CallService.startCall(context, consultationId: c.id, audioOnly: c.type=='AUDIO', doctorId/Name/Phone)` → then `removeWhere(id==c.id)` + `ConsultationService.updateStatus(c.id,'COMPLETED')` (`:183`) |
| Offline | **Record Note** (`OutlinedButton.icon` mic) | `showDialog(VoiceNoteDialog(consultationId: c.id))` (`:188`) |
| Offline | **Call Doctor** (`ElevatedButton.icon` call) | `CallService.startCall` as above (`:190`) |

**Services grid — 6 GlassCards (2-col Wrap):**

| Card | `onTap` → |
|---|---|
| `service_consult` (monitor_heart) | `context.go('/main/doctors')` (`:113`) |
| `service_symptoms` (search) | `context.go('/main/symptoms')` (`:114`) |
| `service_medicine` (pharmacy) | `context.push('/medicine')` (`:115`) |
| `service_records` (description) | `context.go('/main/records')` (`:117`) |
| `service_emergency` (emergency) | `context.push('/emergency')` (`:118`) |
| `Prescriptions` (article) | `context.go('/prescriptions')` → `PrescriptionListScreen` (`:116`) |

**Specialists:**

| Element | Handler |
|---|---|
| Section title + **Explore all** link | `context.go('/main/doctors')` (`:200`) |
| Filter pills (`spec_all, spec_gp, spec_cardio, spec_neuro, spec_pedia`) | `setState(_selectedSpecialistKey = key)` (`:202`), filters by `specialization.toLowerCase().contains(keyword)` (`:93-97`) |
| Doctor cards horizontal (148h) — each shows avatar (`CachedNetworkImage` 84×84), “Dr. name”, specialization, hospital, **Book now** (`ElevatedButton` amber) | Card tap `context.push('/doctor-details/${doc.id}')` (`:229`); **Book now** `context.push('/teleconsultation-request', extra: {doctorId, doctorName})` (`:238`) |
| Loading / empty states | `CircularProgressIndicator` / “No doctors found” |

**FAB:** Floating chat bot circle (56×56 sageDeep, bottom 88 right 16): `context.push('/chatbot')` (`:210`).

### 4.6 MainShell (`lib/screens/common/main_shell.dart`)

Bottom `NavigationBar` (80dp, `sagePale` indicator, 5 tabs): `/main/home`, `/main/doctors`, `/main/symptoms`, `/main/records`, `/main/profile` (`:20`). `onDestinationSelected: _onTap(i) → context.go(_tabs[i])` (`:28`). Labels `tab_home, tab_doctors, tab_symptoms, tab_records, tab_profile` via `context.tr`.

### 4.7 ProfileScreen (`lib/screens/common/profile_screen.dart`) — PATIENT

Loads from `AuthService.getUser()` (`:50`). Fields: `name,email,phone,age,gender,bloodGroup,pinCode,address,abhaId`. Six controllers (`_nameCtrl,_phoneCtrl,_ageCtrl,_pinCtrl,_addressCtrl,_abhaCtrl`).

| Button | Handler |
|---|---|
| Avatar (circle + camera badge) | static |
| **Edit profile / Save** pill (ink → green when editing) | `setState(_isEditing=true)` or `_handleSave` (copies controller text → display vars, `_isEditing=false`) (`:87,165`) |
| Info card rows — email, phone, age/gender, pin, bloodGroup (red drop), ABHA (blue) | `GlassCard` with icon + label + value |
| Expanded edit form (when `_isEditing`) — username, phone, age/pin 2-col, address, ABHA | `TextField` per `_buildInputGroup`; **Save changes** (`GestureDetector → _handleSave`) amber container |
| **App settings > Language** row | `showLanguageSelector` (`:345`) |
| **Notifications** row | `context.push('/notifications')` |
| **Logout** (red) | `AuthGuard.onLogout(); AuthService.logout()` (`clearAllData`) → `context.go('/onboarding')` (`:365-367`) |

### 4.8 NotificationsScreen (`lib/screens/common/notifications_screen.dart`)

| Button | Handler |
|---|---|
| Back chevron | `context.pop()` (`:100`) |
| **Mark all read** | `_markAllRead()` (local state) (`:116`) |
| List items (tap) | no navigation (display only) |

### 4.9 ChatBotScreen (`lib/screens/common/chatbot_screen.dart`)

| Element | Handler |
|---|---|
| Header back | `context.pop()` (`:217`) |
| Subtitle status badge (`_statusSubtitle`/`_statusColor`, green orange) derived from `ConnectivityService` + `OfflineAiService.modelStatus` (`:82-119`) | — |
| `OfflineStatusIndicator(isOnline)` | — |
| `OfflineSetupCard(onDismiss: hide)` (only when offline + model not ready/lexiconOnly) (`:267`) | — |
| Messages `ListView` (user dark, AI white, offline/online pill per `AiResponse.agent == 'offline_ai_router'` or `routingMethod contains offline`) (`:152`) | — |
| TextField (hint `ask_health`) + 44 circular send (sage when non-empty else grey) | `onTap: hasText ? _handleSend : null` → `AiService.query(text)` (`:122`), urgency emoji prepend, scroll to bottom (`:182`). `OfflineAiService.ensureModelLoaded()` on init. |
| Error bubble | `Message(sender:'ai', text: "Sorry... ${e}")` (`:169`) |

### 4.10 SymptomCheckerScreen — Patient (`lib/screens/patient/symptom_checker_screen.dart`) and legacy root twin (`lib/screens/symptom_checker_screen.dart` similar)

Chips: `['Fever','Headache','Cough','Chest Pain','Fatigue','Stomach Ache','Nausea']` (`:34`), multi-select `_selected Set<String>`, text `_otherCtrl` + mic toggle (`_isRecording`) pulsating amber wash.

| Button | Handler |
|---|---|
| Chip tap | `setState(add/remove)` (`:130`) |
| Mic toggle (40×40) | `setState(_isRecording = !_isRecording)` (`:152`) |
| **Analyze symptoms** (`PrimaryButton`) | `_analyze()` (`:49`): join chips+other → `combinedQuery` → emergency pre-check (`OfflineAiService.isEmergency`) → immediate `ClinicalResponse.emergency` + `SymptomResult` “Emergency Indicator” (no network call). Otherwise `AiService.query("I have... $combinedQuery")` (`.timeout(45s)`). On success → `_clinicalResult = aiResponse.structuredResponse` + `_resultSource='Online AI'` + `SymptomResult`. On `catch` if `debugForceOnlineAi` surface error; else offline path: `OfflineAiService.initialise → queryOffline("I have symptoms: $combinedQuery")` streamed → `OfflineMedicalRepository.buildSymptomCheckerContext` fallback, `_resultSource='Offline AI'`. |
| Result area | Loading spinner (`ai_processing`) when `_isAnalyzing`; then `StructuredClinicalResponseCard(response, sourceLabel)` if `_clinicalResult != null` else fallback `GlassCard` 4-row display (Result Source / Possible condition / Advice / Suggested action) + disclaimer (`:295-354`). |

### 4.11 HealthOverviewScreen (`lib/screens/patient/health_overview_screen.dart`)

Purely visual demo (hardcoded `kPatientData` Muminul Hoque). `AnimationController _pulseCtrl` (1500ms repeat reverse, scale 1.0→1.5 + opacity).

| Button | Handler |
|---|---|
| Back | `context.pop()` (`:85`) |
| Tune icon (right) | static |
| Anatomy hotspots (5 pulsing dots) | decorative, `_buildHotspot` (`:232`) |
| Metric cards: oxygen, kidney, heart rate, BP, cholesterol | `_buildMetricCard` |
| Bottom paper card: 162cm • avatar • 64kg | — |
| 360° badge + border ring | — |

No backend calls.

### 4.12 HealthRecordsScreen (`lib/screens/patient/health_records_screen.dart`) — Admin toggled mock

| Button | Handler |
|---|---|
| Top bar pretend toggle `Admin view / Patient view` | `setState(_isAdmin = !_isAdmin)` (`:78`) |
| **Add record** circular amber `+` | `setState(_showAddModal = true)` (`:80`) |
| Modal overlay (tapping scrim closes) | `setState(_showAddModal=false)` (`:108`) + `TextButton Cancel` / `ElevatedButton Save → _addRecord` (`:126,128`) |
| Record card (date / doctor / diagnosis / prescription) | `GestureDetector → context.push('/health-overview')` (`:148`) |

No network (local list).

### 4.13 PatientRecordsScreen (`lib/screens/patient/patient_records_screen.dart`) — Real Health Vault

| Button | Handler |
|---|---|
| AppBar upload | `Navigator.push(MaterialPageRoute(UploadRecordScreen))` then `if(result==true) _fetchRecords()` (`:55,65`) |
| Refresh | `_fetchRecords()` → `MedicalRecordService.getMyRecords()` (`:56`) |
| Error retry | `ElevatedButton Retry → _fetchRecords` (`:75`) |
| Empty “Upload Record” | same push |
| Record row trailing eye `visibility` | if `fileUrl startsWith('data:image')` → decode base64 → `Dialog(InteractiveViewer(Image.memory(bytes)))`; else `_launchUrl(fileUrl)` via `url_launcher`; else SnackBar “No attachment” (`:94`) |
| ListTile tap | — (eye only) |

### 4.14 UploadRecordScreen (`lib/screens/patient/upload_record_screen.dart`)

Requires `titleCtrl, typeDropdown, fileUrl/Base64`. Two pick paths via `image_picker: ImagePicker` `pickImage(ImageSource.camera/gallery)` → read bytes → `base64Encode` → preview + store as `data:image/*;base64,...`.

| Button | Handler |
|---|---|
| **Camera** (`OutlinedButton.icon`) | `_pickImage(ImageSource.camera)` (`:117`) |
| **Gallery** (`OutlinedButton.icon`) | `_pickImage(ImageSource.gallery)` (`:119`) |
| **Upload** (`ElevatedButton` 56h amber, full width) | `_upload()` → `MedicalRecordService.uploadManualRecord(title, type, fileUrl)` (`POST /api/medical-records/upload`); shows `CircularProgressIndicator` while `_isUploading`, SnackBar success → `Navigator.pop(context, true)` (`:122-125`). |
| Back | `Navigator.pop` |

### 4.15 TeleconsultationRequestScreen (`lib/screens/patient/teleconsultation_request_screen.dart`)

Init: `didChangeDependencies` reads `GoRouterState.of(context).extra → {doctorId, doctorName, doctorPhone}` (`:38`). Listens `ConnectivityService.statusStream` (`:50`); on `weak` forces `VIDEO→AUDIO`.

Static options:
- `_reasons = ['General Fever','Cough & Cold','Skin Issue','Stomach Pain','Other']`
- `_timeSlots = ['Morning (9 AM - 12 PM)','Afternoon (1 PM - 4 PM)','Evening (5 PM - 8 PM)']`

| Control | Widget | Handler |
|---|---|---|
| Back | `GestureDetector` | `context.pop()` (`:97`) |
| Doctor header `GlassCard` (avatar 48 + “Dr. name” + spec) | — | — |
| Reason chips (5 pills) | `GestureDetector → setState(_selectedReason=r)` (`:107`) | single-select |
| Consultation type row (when not offline) — Video (High Network) / Audio (Low Bandwidth) cards | `GestureDetector → setState(_selectedType='VIDEO'/'AUDIO')` (`:112`) | online only; offline amber info box replaces row (`:111`) |
| Symptoms free text | `TextField(_symptomsCtrl, 3-4 lines, hint other_symptoms)` | — |
| Voice recorder module | `OfflineVoiceRecorder(doctorPhone, doctorName, onRecordingComplete: (b64)=> _voiceNoteBase64=b64)` (`:118`) | stores base64 voiceNote |
| Time slots (3 rows radio + check) | `GestureDetector → setState(_selectedTime=slot)` (`:122`) | single-select |
| **Send request** (`PrimaryButton` full width) or spinner when `_isSubmitting` | `_handleSubmit` (`:62`): calls `ConsultationService.createConsultation(reason:_selectedReason, symptoms, scheduledTime:_selectedTime, doctorId, type: offline?'OFFLINE':_selectedType, voiceNoteUrl:_voiceNoteBase64)` → via `SyncService.push` → on success `setState(_isSubmitted=true)` → auto `context.pop()` after 1800ms; error SnackBar (emergency red) (`:70-76`) | — |
| Success screen (when `_isSubmitted`) | sageWash bg, paper card with green check, `request_done` + `urgent_success_msg` | auto-dismiss |

### 4.16 EmergencyHelpScreen (`lib/screens/common/emergency_help_screen.dart`)

| Button | Handler |
|---|---|
| Back | `context.pop()` (`:186`) |
| **SEND SOS + GPS** big red double circle (220/180) | `_triggerSOS()` (`:81,218`): check `Geolocator.isLocationServiceEnabled` → `Geolocator.checkPermission` → `getCurrentPosition(Accuracy.best)` → `mapsLink = https://www.google.com/maps/search/?api=1&query=lat,lng` → `message = URLEncoder("EMERGENCY! ... $mapsLink")` → `phones = _contacts.map(phone).join(',')` → `launchUrl(Uri.parse("sms:$phones?body=$message"))`; SnackBar on catch. Shows `CircularProgressIndicator` when `_isLocating`. |
| First-Aid horizontal list (Snakebite, Severe Burns, CPR, Poisoning) 120×100 cards | `GestureDetector → _showFirstAidDialog(guide)` → `AlertDialog` with icon+title+content, **Understood** → `Navigator.pop` (`:278,150`) |
| **Emergency response** card (medical_services icon) | `_handleCall('108')` → `launchUrl(Uri.parse('tel:108'))` (`:307`) |
| **Nearest PHC** card (location icon) | `_routeToNearestPHC()` → `launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=hospital+clinic+PHC"), externalApplication)` (`:114,327`) |
| **Add ICE** (Add In-Case-of-Emergency) | `_showAddContactDialog()` (`:357`): 3 TextFields (Name, Relationship, Phone) → `AlertDialog Save Contact` → `_saveContact(name,rel,phone)` → `SharedPreferences.setString('ice_contacts', jsonEncode(_contacts))` |
| Contact list `GlassCard` rows (name, relation, phone) + circular phone icon | `GestureDetector → _handleCall(phone)` → `tel:phone` (`:409`) |

Default `_contacts` if no `SharedPreferences ice_contacts`: `[{name:Ambulance, relation:Emergency Response, phone:102}, {name:Dispatch Line, relation:Medical Hotline, phone:108}]` (`:59`).

### 4.17 VideoCallScreen (`lib/screens/common/video_call_screen.dart`)

| Button | Handler |
|---|---|
| Back / leave | `context.pop()` (`:149,248`) |
| Mute toggle | `setState(_isMuted = !_isMuted)` + native mute (`:224`) |
| Camera, end-call, etc. | via `jitsi_meet_wrapper` (in `pubspec.yaml: jitsi_meet_wrapper: ^0.2.0+1`) |
| Accepts `doctorId` param + `extra {doctorName, doctorPhone, isAudioOnly}` | — |

### 4.18 Doctor — List / Details

**DoctorListScreen** (`lib/screens/doctor/doctor_list_screen.dart`):

| Button | Handler |
|---|---|
| Search bar (50h, search icon) | `onChanged: setState` filters `_filtered` where name/spec contains query (`:106,44`) |
| Filter chips (`spec_gp,spec_pedia,spec_cardio,spec_derma`) | `setState(_activeFilterKey)` (`:136`) |
| Card tap (whole area) | `context.push('/doctor-details/${doc.id}')` (`:209`) |
| Small videocam circle (top-right of card) | `context.push('/teleconsultation-request')` (`:251`) |
| **Book consultation** full-width amber bar | same push (`:312`) |
| Error “Retry” / loading / empty | `ElevatedButton Retry → _loadDoctors` |
| Data source | `DoctorService.getDoctors()` (see § backend) |

**DoctorDetailsScreen** (`doctor_details_screen.dart`, ~14KB) — header avatar, specialization, hospital, rating, exp, bio, availability pill, consultationFee, **Book Teleconsultation** → `context.push('/teleconsultation-request', extra:{doctorId,doctorName,doctorPhone})`, **Video/Audio Call** → `CallService.startCall(...)`, phone `tel:` via `url_launcher`.

### 4.19 Doctor — Requests / Consultations / Prescriptions / Patients / Appointments

**DoctorRequestsScreen** (`doctor_requests_screen.dart` ~15KB): Inbox of `status == PENDING` consultations via `ConsultationService.listDoctorConsultations(status:'PENDING')`. Each row shows patientName, reason, symptoms snippet, voiceNotes play (`VoiceNoteHistoryDialog`), **Accept** → `ConsultationService.acceptConsultation(id, notes)` (`PATCH /api/consultations/:id/accept`) → cache status → `ACTIVE`, **Reject** flow. Tap card → `DoctorConsultations` or details.

**DoctorConsultationsScreen** (`doctor_consultations_screen.dart` ~20KB): Tabs/filters by status (`PENDING, ACTIVE, COMPLETED`). Lists via `listDoctorConsultations`. Actions: **View** → detail, **Complete** → `DoctorCompleteConsultationScreen` (`PATCH /:id/complete`), **Add Voice Note** history.

**DoctorCompleteConsultationScreen** (`doctor_complete_consultation_screen.dart`): Form: riskLevel chips (`low/moderate/high/emergency`), notes TextField, **Complete** → `ConsultationService.completeConsultation(id, notes, riskLevel)`.

**DoctorPrescriptionsScreen** (`doctor_prescriptions_screen.dart`): Lists via `PrescriptionService.getDoctorPrescriptions()` (`GET /api/doctors/prescriptions`), each card: patient, diagnosis, date, meds pills. **Create** flow from consultation.

**DoctorPatientsScreen, DoctorAppointmentsScreen, DoctorProfileScreen (`9643`), DoctorSettingsScreen, DoctorOnboardingScreen** — onboarding collects `specialization, experienceYears, hospital, consultationFee, bio, isAvailable, profileImageUrl` → `POST /api/doctors` (`createDoctor`) then patch `/doctors/me`.

### 4.20 Pharmacy

**PharmacyDashboardScreen** (`pharmacy_dashboard_screen.dart`): Inventory table + **Update Stock** → `PharmacyService.updateInventory(medicineName, inStock)` (`POST /api/pharmacy/inventory`), list via `PharmacyService.syncPharmacies()` (`GET /api/pharmacy/list`) cached to `cached_pharmacies`.

**MedicineAvailabilityScreen** (`medicine_availability_screen.dart`): Search field (`medicineQuery` from `queryParameters['query']`), **Search** → `PharmacyService.searchPharmaciesLocal(medicine, userLat, userLon)` (Haversine distance `_calculateDistance` from `CachedPharmacies`), sorted by distance, shows `PharmacySearchResult(pharmacy, distanceKm, isAvailable)` with stock badge + distance + **Call/Route** (`tel:` / maps).

**PrescriptionListScreen** (`prescription_list_screen.dart`): Patient view: lists via `PrescriptionService.getPrescriptions()` (`GET /api/prescriptions/me`), `MedicationSchedule` sub-card, **View** detail.

### 4.21 Admin (11 screens, all wrapped `DashboardLayout(title, child)` + `Sidebar`)

| Screen | Primary buttons / functions |
|---|---|
| `AdminDashboardScreen` | 6 `StatCard` KPIs (Total Users 1,420, Doctors 48, Patients 1,372, Facilities 12, Pharmacies 18, Appointments 320) + 3-row `Recent System Activity` (`GlassCard` + `StatusBadge`) |
| `AdminUsersScreen` | Table + filter `FilterDropdown` role + search + **Edit/Delete** `IconButton` → `PATCH /api/users/:id` etc. |
| `AdminDoctorsScreen` | Doctor table + **Approve/Reject** (`PATCH /api/doctors/:id` status) |
| `AdminPatientsScreen` | Patient table + **View records** → `/medical-records/patient/:id` |
| `AdminFacilitiesScreen` | Facility CRUD via `AdminFacilities` API (`POST/PATCH /api/facilities`) |
| `AdminPharmaciesScreen` | Pharmacy list + inventory reset |
| `AdminAppointmentsScreen` | Appointment table (joins consultations) |
| `AdminConsultationsScreen` | All consultations table + status filter chips + **Assign doctor** (`PATCH /:id/assign-doctor`) |
| `AdminPrescriptionsScreen` | All prescriptions table |
| `AdminReportsScreen` | Charts placeholder (Wrap + GlassCard) |
| `AdminSettingsScreen` | Toggles (future feature) + **Save** → `SharedPreferences` |

Every admin screen uses `context.tr` and `AppColors` theme and `DashboardLayout` responsive wrap; navigation is via `Sidebar` selected index matching `GoRouter` path (no `context.go` inside cards, table actions refresh via `setState` after service call).

---

## 5. Global App Behaviours

| Behaviour | Where | Notes |
|---|---|---|
| Language switching (en/hi/mr/gu) | `lib/l10n/app_language.dart` `LanguageController.currentLanguage` (ValueNotifier) + `translations.dart` + `showLanguageSelector` modal | `RuralCareApp` wraps `MaterialApp.router` in `ValueListenableBuilder` (`main.dart:207`), key `ValueKey(lang.code)`, locale `lang.locale`, delegates `GlobalMaterialLocalizations`. No restart needed. |
| Offline-first queue | `SyncService`, `LocalDatabase`, `ConnectivityService` | Any write routed via `SyncService.push` when offline → `PENDING_SYNC` + local optimistic UI. See doc 03/04. |
| Multi-user isolation | `AuthService.login: clearAllData()` (`auth_service.dart:81`) + `logout: clearAllData` | Prevents cross-user cache leakage. |
| Connectivity detection | `connectivity_plus` + `http GET ${baseUrl}/api/health` ping every 10s (`connectivity_service.dart:79,50`) → statuses `online (<1500ms)` vs `weak (>1500ms Timeout)` vs `offline` | Weak forces Audio in Teleconsultation. |

---
*End of doc 01. Next: `02-navigation-interaction-map.md` for the click→destination→function graph in one diagram.*
