# GramHealth Frontend Rebuild — 02 / Navigation & Interaction Map

> **One diagram + exhaustive table: every clickable element → destination route or function.**
> Apply by reproducing these `context.go / push / pop / SnackBar / Dialog / Service.call` edges exactly. `=>` = navigation, `→` = function call, `⟂` = guard bounce.
> Reading order = app boot → per-screen depth-first.

---

## Boot Flow (no user interaction)

```
main() [main.dart:54]
  ① AuthGuard.init() reads SharedPreferences gram_health_token + gram_health_user
  ② ConnectivityService.initialize() starts 10s ping GET {baseUrl}/api/health
  ③ SyncService.initialize() subscribes to statusStream; if online drains sync_queue + PharmacyService.syncPharmacies()
  ④ GoRouter(initialLocation:'/', redirect:AuthGuard.redirect)
```

**`AuthGuard.redirect(state)` decision tree (`auth_guard.dart:44-74`)**:

```
loggedIn==false && path ∉ {/,/onboarding,/login,/forgot-password}  => /onboarding
loggedIn==true  && path ∈ {/login,/onboarding}                     => _dashboardFor(role)
  role=='admin'     => /admin/dashboard
  role=='doctor'    => /doctor/requests
  role=='pharmacy'  => /pharmacy/dashboard
  else patient/asha => /main/home
loggedIn==true && path startsWith /doctor   && role!='doctor'   => _dashboardFor(role) ⟂
loggedIn==true && path startsWith /admin    && role!='admin'    => _dashboardFor(role) ⟂
loggedIn==true && path startsWith /main     && role∉{patient,asha} => _dashboardFor(role) ⟂
loggedIn==true && path startsWith /pharmacy && role!='pharmacy' => _dashboardFor(role) ⟂
else => null (allow)
```

---

## Graph (Mermaid) — Auth + Patient Happy Path

> Paste into any Mermaid renderer. Nodes = screens/routes, edges = button label + nav method.

```mermaid
flowchart TD
  A[/ Splash '/'] -->|"Get Started ─ PrimaryButton ─ context.go"| B[/ Onboarding '/onboarding']
  B -->|"language pill ─ GestureDetector ─ showLanguageSelector()"| B
  B -->|"SlideButton onComplete ─ context.go"| C[/ Login '/login']
  C -->|"role chips (patient/doctor/admin/pharmacy) ─ setState"| C
  C -->|"Continue ─ PrimaryButton ─ _handleLogin() → AuthService.login → AuthGuard.onLogin → context.go"| D
  C -->|"Register ─ _handleRegister() → AuthService.register → login → context.go"| D
  C -->|"Forgot Password? ─ GestureDetector ─ context.go"| F[/ ForgotPassword '/forgot-password']
  F -->|"Reset Password ─ AuthService.resetPassword → context.go"| C
  C -->|"language pill ─ showLanguageSelector"| C
  D{{_navigateByRole switch}}
  D -->|"patient/asha"| H[/ Home '/main/home' — MainShell]
  D -->|"doctor"| DR[/ DoctorRequests '/doctor/requests']
  D -->|"admin"| AD[/ AdminDashboard '/admin/dashboard']
  D -->|"pharmacy"| PH[/ PharmacyDashboard '/pharmacy/dashboard']

  H --> H1["ConnectivityBadge • language pill → showLanguageSelector • bell → context.push('/notifications') • avatar → context.go('/main/profile')"]
  H --> BANNER["Banner Learn more ─ ElevatedButton → context.push('/notifications')"]
  H --> OFFCARD["OfflineSetupCard (autoDownload progress)"]
  H --> ACTIVE["Active consultations: Join/Audio ─ CallService.startCall + ConsultationService.updateStatus('COMPLETED') • Record Note ─ showDialog(VoiceNoteDialog) • Call Doctor ─ CallService.startCall"]
  H --> SERVICES["Services 6-card Wrap"]
  SERVICES -->|"Card 1 Consult"| L[/ DoctorList '/main/doctors']
  SERVICES -->|"Card 2 Symptoms"| S[/ SymptomChecker '/main/symptoms']
  SERVICES -->|"Card 3 Medicine"| M[/ Medicine '/medicine?query=']
  SERVICES -->|"Card 4 Records"| PR[/ PatientRecords '/main/records']
  SERVICES -->|"Card 5 Emergency"| E[/ Emergency '/emergency']
  SERVICES -->|"Card 6 Prescriptions"| RX[/ Prescriptions '/prescriptions']
  H -->|"Explore all → context.go"| L
  H -->|"specialist pill → setState filter"| H
  H -->|"Doctor card tap → context.push"| DD[/ DoctorDetails '/doctor-details/:id']
  H -->|"Book now ─ ElevatedButton → context.push extra{doctorId,doctorName}"| T[/ TeleconsultationRequest '/teleconsultation-request']
  H -->|"FAB chat bubble ─ GestureDetector → context.push"| CH[/ Chatbot '/chatbot']
  H -->|"Bottom nav MainShell _onTap(i) → context.go"| NAV

  L -->|"Search TextField onChanged → setState filter"| L
  L -->|"Spec chip → setState"| L
  L -->|"Card tap → context.push"| DD
  L -->|"videocam circle → context.push"| T
  L -->|"Book consultation → context.push"| T

  DD -->|"Book Teleconsultation → context.push extra"| T
  DD -->|"Call / Audio ─ CallService.startCall"| VC[/ VideoCall '/video-call/:id']
  DD -->|"tel: ─ launchUrl"| TEL

  T -->|"Back ─ context.pop"| H
  T -->|"Reason chip → setState"| T
  T -->|"VIDEO/AUDIO card → setState(selectedType) — disabled when weak/offline"| T
  T -->|"Symptoms TextField"| T
  T -->|"OfflineVoiceRecorder onRecordingComplete → _voiceNoteBase64"| T
  T -->|"Time slot radio → setState"| T
  T -->|"Send request ─ PrimaryButton → ConsultationService.createConsultation → _isSubmitted + auto-pop 1.8s"| H

  S -->|"Chip / other TextField + mic toggle → setState"| S
  S -->|"Analyze symptoms → _analyze() → OfflineSafety emergency? → ClinicalResponse.emergency else AiService.query → StructuredClinicalResponseCard / fallback"| S

  PR -->|"Upload IconButton → Navigator.push(UploadRecordScreen)"| U[/ UploadRecord '/upload (Navigator.push)']
  PR -->|"Retry / Refresh → _fetchRecords() → MedicalRecordService.getMyRecords"| PR
  PR -->|"Eye IconButton → data:image? → Dialog Image.memory else launchUrl(fileUrl)"| PR
  PR -->|"empty Upload Record ElevatedButton → Navigator.push"| U
  U -->|"Camera/Gallery OutlinedButton → _pickImage(ImageSource) → base64"| U
  U -->|"Upload ─ ElevatedButton → MedicalRecordService.uploadManualRecord → Navigator.pop(true)"| PR
  PR -.->|"back"| H

  M -->|"query TextField + Search → PharmacyService.searchPharmaciesLocal + Haversine sort"| M
  M -->|"Call / Directions ─ launchUrl tel:/maps"| M

  E -->|"SEND SOS+GSM big circle → _triggerSOS() → Geolocator + sms:phones?body=mapsLink"| E
  E -->|"FirstAid card → _showFirstAidDialog → AlertDialog"| E
  E -->|"Emergency response card → tel:108"| TEL
  E -->|"Nearest PHC → maps search PHC"| MAPS
  E -->|"Add ICE → _showAddContactDialog → SharedPreferences ice_contacts"| E
  E -->|"Contact phone circle → tel:phone"| TEL

  CH -->|"back → context.pop"| H
  CH -->|"send circle (hasText) → _handleSend → AiService.query"| CH
  CH -->|"status subtitle + OfflineStatusIndicator + OfflineSetupCard"| CH

  RX -->|"list via PrescriptionService.getPrescriptions"| RX
  HO[/ HealthOverview '/health-overview'] -->|"back → context.pop"| PR2

  subgraph Admin ["Admin (DashboardLayout + Sidebar)"]
    AD
    ADU[/ AdminUsers '/admin/users']
    ADD[/ AdminDoctors '/admin/doctors']
    ADP[/ AdminPatients '/admin/patients']
    ADA[/ AdminAppointments '/admin/appointments']
    ADC[/ AdminConsultations '/admin/consultations']
    ADRX[/ AdminPrescriptions '/admin/prescriptions']
    ADPH[/ AdminPharmacies '/admin/pharmacies']
    ADF[/ AdminFacilities '/admin/healthcare-facilities']
    ADRPT[/ AdminReports '/admin/reports']
    ADSET[/ AdminSettings '/admin/settings']
    AD --- ADU & ADD & ADP & ADA & ADC & ADRX & ADPH & ADF & ADRPT & ADSET
  end

  subgraph Doctor ["Doctor"]
    DR --> DRC[/ DoctorConsultations '/doctor/consultations']
    DR -->|"Accept → ConsultationService.acceptConsultation → status ACTIVE"| DRC
    DRC -->|"Complete → DoctorCompleteConsultation → ConsultationService.completeConsultation"| DRC
    DR --> DRX[/ DoctorPrescriptions '/doctor/prescriptions']
    DR --> DRP[/ DoctorPatients]
    DR --> DRPR[/ DoctorProfile]
  end
```

---

## Exhaustive Table — Screen → Clickable Element → Method → Destination / Effect

### Splash → Onboarding → Login → ForgotPassword

| Screen | Visual element | Underlying widget | `onTap` / `onPress` / `onComplete` | What executes | Nav dest / side effect |
|---|---|---|---|---|---|
| Splash `/` | Get Started | `PrimaryButton` (`splash:164`) | `onPress` | `() => context.go('/onboarding')` | `=> /onboarding` |
| Onboarding `/onboarding` | Language pill top-right | `GestureDetector` (`91`) | `onTap` | `showLanguageSelector(context)` (modal bottom sheet with en/hi/mr/gu radios, `LanguageController.instance.setLanguage`) | Dialog |
| Onboarding | Bottom swipe card | `SlideButton(onComplete: () => context.go('/login'))` (`265`) | `onComplete` (drag threshold) | `context.go('/login')` | `=> /login` |
| Login `/login` | Language pill | `GestureDetector` (`273`) | `onTap` | `showLanguageSelector` | Dialog |
| Login | Role cards (4) — User/Doctor/Admin/Pharmacy | `GestureDetector` wrapping `AnimatedContainer` (`211`) | `onTap` | `setState(() => _selectedRole = role)` where `role ∈ {patient,doctor,admin,pharmacy}` | local state |
| Login | Full Name / Phone / Pharmacy Address fields | `CustomInput` | — | controlled `TextEditingController` | — |
| Login | Full Name etc. only when `_isRegistering==true` | `if (_isRegistering) ...` (`350`) | — | — | — |
| Login | Pharmacy Address only when `_selectedRole=='pharmacy'` | `if (_selectedRole=='pharmacy')` (`388`) | — | before register geocodes address | — |
| Login | Email or Phone field | `CustomInput` (`396`) | — | — | — |
| Login | Password field | `CustomInput obscureText:true` (`401`) | — | — | — |
| Login | Forgot Password? link (login mode) | `GestureDetector` (`413`) | `onTap` | `context.go('/forgot-password')` | `=> /forgot-password` |
| Login | Confirm Password (register mode) | `CustomInput obscureText:true` (`426`) | — | — | — |
| Login | Continue / Register (large amber) | `PrimaryButton` (`441`) | `onPress: _handleContinue` → `_handleLogin` or `_handleRegister` | **Login:** validate non-empty → `AuthService.login(email,password)` → `AuthGuard.onLogin(role)` → `_navigateByRole(role)` switch (`60-70`): `admin=>/admin/dashboard`, `doctor=>/doctor/requests`, `pharmacy=>/pharmacy/dashboard`, else `=>/main/home`. **Register:** validate required+email regex+password≥8+confirm match → if pharmacy: `geocoding.Geocoding().locationFromAddress(address) → lat/lng` else error SnackBar → `AuthService.register(...)` → `AuthService.login(...)` → if `role=='doctor'` then `AuthGuard.onLogin` + `context.go('/doctor/onboarding')` else `_navigateByRole` | `=> role dashboard` or SnackBar |
| Login | “Already have an account?” / “Register new account” toggle link | `GestureDetector` (`451`) | `onTap` | `setState(() => _isRegistering = !_isRegistering)` | local |
| Forgot `/forgot-password` | Email/Phone + New Password + Confirm fields | `CustomInput` | — | — | — |
| Forgot | Reset Password | `ElevatedButton/PrimaryButton` | `onPress` | `AuthService.resetPassword(emailOrPhone, newPassword)` (`POST /api/auth/reset-password`) → SnackBar success | then `context.go('/login')` (`74`) |
| Forgot | Back to Login link + top back | `GestureDetector` / `IconButton` (`94,164`) | `onTap/onPress` | `context.go('/login')` | `=> /login` |

### MainShell (Patient Bottom Nav)

| Element | Widget | Handler | Effect |
|---|---|---|---|
| Home tab | `NavigationBar NavigationDestination(icon:home_outlined)` | `onDestinationSelected: _onTap(0)` → `context.go('/main/home')` (`main_shell:28,30`) | `=> /main/home` |
| Doctors tab | same | `_onTap(1) → /main/doctors` | `=> /main/doctors` |
| Symptoms tab | same | `_onTap(2) → /main/symptoms` | `=> /main/symptoms` |
| Records tab | same | `_onTap(3) → /main/records` | `=> /main/records` |
| Profile tab | same | `_onTap(4) → /main/profile` | `=> /main/profile` |

### Home `/main/home`

| Element | Widget | Handler | Destination / Function |
|---|---|---|---|
| ConnectivityBadge | `Container` pill reading `ConnectivityService` | — | displays Online/Weak/Offline |
| Language pill (nativeName) | `Semantics(button) GestureDetector` (`143`) | `onTap: showLanguageSelector` | Dialog |
| Bell (notifications) | `GestureDetector` via `_iconButton` (`145`) | `onTap: () => context.push('/notifications')` | `=> /notifications` (push) |
| Avatar (letter) | `GestureDetector` (`147`) | `onTap: context.go('/main/profile')` | `=> /main/profile` |
| Banner Learn more | `ElevatedButton amber` (`165`) | `onPress: context.push('/notifications')` | `=> /notifications` |
| OfflineSetupCard | `OfflineSetupCard()` (`172`) | internally `OfflineAiService.startDownload()` / progress | downloads GGUF |
| Active consultation — Join (VIDEO) / Audio | `ElevatedButton` (`183`) | `onPressed: async { await CallService.startCall(...audioOnly); setState(remove); await ConsultationService.updateStatus(id,'COMPLETED'); }` | initiates `flutter_phone_direct_caller` call, fallback `context.push('/video-call/:id')`; removes card |
| Active consultation — Record Note (offline) | `OutlinedButton.icon mic` (`188`) | `onPressed: showDialog(VoiceNoteDialog(consultationId))` | Dialog that records via `record`+`audioplayers`, on save calls `ApiClient.patch /consultations/:id/voicenote` or queues |
| Active consultation — Call Doctor (offline) | `ElevatedButton.icon call` (`190`) | `CallService.startCall` | `tel:` or `/video-call/:id` fallback |
| Services Card — Consult doctors | `GestureDetector GlassCard` (`221 onTap:_handleCategoryTap '1'`) | `context.go('/main/doctors')` | `=> /main/doctors` |
| Services Card — Symptoms | `id:'2'` | `context.go('/main/symptoms')` | `=> /main/symptoms` |
| Services Card — Medicine | `id:'3'` | `context.push('/medicine')` | `=> /medicine` (push) |
| Services Card — Records | `id:'4'` | `context.go('/main/records')` | `=> /main/records` |
| Services Card — Emergency | `id:'5'` | `context.push('/emergency')` | `=> /emergency` |
| Services Card — Prescriptions | `id:'6'` | `context.go('/prescriptions')` | `=> /prescriptions` |
| Specialists header Explore all | `GestureDetector Text` (`200`) | `context.go('/main/doctors')` | `=> /main/doctors` |
| Specialist filter pills (All/GP/Cardio/Neuro/Pedia) | `GestureDetector AnimatedContainer` (`202`) | `onTap: setState(_selectedSpecialistKey=key)` → recomputed `_filteredDoctors` by spec keyword | local filter |
| Doctor card (whole) | `GestureDetector Container GlassCard` (`228`) | `context.push('/doctor-details/${doc.id}')` | `=> /doctor-details/:id` |
| Doctor card Book now | `ElevatedButton amber 36h` (`238`) | `context.push('/teleconsultation-request', extra:{doctorId,doctorName})` | `=> /teleconsultation-request` with extra |
| FAB chat bot (56 circle) | `Positioned GestureDetector` (`210`) | `context.push('/chatbot')` | `=> /chatbot` |

### DoctorList `/main/doctors`

| Element | Handler | Effect |
|---|---|---|
| Search TextField (50h) | `onChanged: setState({})` → `_filtered` where `name/spec contains query` (`44`) | live filter, no nav |
| Spec filter chips (GP/Pedia/Cardio/Derma) | `onTap: setState(_activeFilterKey)` (`136`) | toggles active pill (lime vs white); filtering currently search-only, chip is visual state |
| Card tap (whole area) | `context.push('/doctor-details/${doc.id}')` (`209`) | `=> /doctor-details/:id` |
| Small videocam circle (top-right) | `context.push('/teleconsultation-request')` (`251`) same | `=> /teleconsultation-request` (no extra when from list) |
| Book consultation amber bar | `context.push('/teleconsultation-request')` (`312`) | `=> /teleconsultation-request` |
| Retry on error | `ElevatedButton onPress: _loadDoctors` → `DoctorService.getDoctors()` | reload |
| Loading / empty | `CircularProgressIndicator` / Text | — |

### DoctorDetails `/doctor-details/:id`

| Element | Handler | Effect |
|---|---|---|
| Back | `context.pop()` | `<= back` |
| Book Teleconsultation / Consult Now (amber) | `context.push('/teleconsultation-request', extra:{doctorId,doctorName,doctorPhone})` | `=> /teleconsultation-request` |
| Call / Video Call button | `CallService.startCall(context, consultationId: temp, audioOnly: bool, doctorId/Phone/Name)` → `FlutterPhoneDirectCaller.callNumber(phone)` otherwise `context.push('/video-call/:id', extra:{doctorName,doctorPhone,isAudioOnly})` (`call_service:44-59`) | `tel:` or `=> /video-call/:id` |
| Phone icon / tel: link | `launchUrl(Uri.parse('tel:$phone'))` | dialer |

### TeleconsultationRequest `/teleconsultation-request`

| Element | Handler | Effect |
|---|---|---|
| Back | `context.pop()` (`97`) | `<= back` |
| Reason chips (5) | `onTap: setState(_selectedReason=r)` (`107`) | single-select pill sage vs white |
| Type cards — Video Call / Audio Call (when online/weak) | `onTap: setState(_selectedType='VIDEO'/'AUDIO')` (`112`) — hidden when `NetworkStatus.offline` (shows amber info box) or when `weak` hides Video option (`50`) | local |
| Symptoms TextField (hint other_symptoms, 3-4 lines) | `TextEditingController _symptomsCtrl` | free text |
| Voice recorder row | `OfflineVoiceRecorder(onRecordingComplete: (b64)=> _voiceNoteBase64=b64)` (`118`) | captures base64 voice note for payload `voiceNoteUrl` |
| Time slot rows (3) | `onTap: setState(_selectedTime=slot)` check_circle vs radio (`122`) | single-select |
| Send request (PrimaryButton full width) / spinner when `_isSubmitting` | `onPress: _handleSubmit` (`62`): gathers `reason(_selectedReason), symptoms(optional), scheduledTime(_selectedTime), doctorId, type(offline?'OFFLINE':_selectedType), voiceNoteUrl(_voiceNoteBase64)` → `ConsultationService.createConsultation(...)` (→ `SyncService.push` POST `AppConfig.apiConsultations`); on success `setState(_isSubmitted=true)` shows green check success screen; `Future.delayed(1800ms) {context.pop()}` (`69`); on `ApiException` SnackBar `e.message` emergency color; on network catch SnackBar | `<= pop after success`, else stays |
| Success state (green check + request_done / urgent_success_msg) | auto-dismiss | `=> pop` |

### SymptomChecker `/main/symptoms` (Patient + root twin)

| Element | Handler | Effect |
|---|---|---|
| Chip (7) Fever/Headache/Cough/Chest Pain/Fatigue/Stomach Ache/Nausea | `onTap: setState(add/remove from _selected)` (`patient symptom_checker:130`) | multi-select |
| Other symptoms TextField | `TextEditingController _otherCtrl` | appends to query |
| Mic toggle (40, amberWash when recording) | `onTap: setState(_isRecording=!_isRecording)` (`152`) — visual only (no STT yet) | pulse circle |
| Analyze symptoms (PrimaryButton) | `_analyze()` (`49`): `symptomsToAnalyze = _selected + _otherCtrl` → `combinedQuery = join(', ')` → if `OfflineAiService.isEmergency(combinedQuery)` → `buildEmergencyResponse` → `ClinicalResponse.emergency` + `SymptomResult condition:'Emergency Indicator'` (no network) and return; else set `_isAnalyzing=true` → `AiService.query("I have ... $combinedQuery")` with `.timeout(45s)`; on success derive `condition:'Clinical Assessment (intent)'`, `advice: answer`, `action: requiresProfessionalReview/urgency=='emergency'? immediate : monitor`, `source:'Online AI'` and store `structuredResponse`; on catch if `debugForceOnlineAi` show “Online AI Request Error”; else offline fallback: `OfflineAiService.initialise→ queryOffline → buffer` + `OfflineMedicalRepository.buildSymptomCheckerContext` fallback, set `_resultSource='Offline AI'`, `_clinicalResult=null` with general message | renders `StructuredClinicalResponseCard` if `structuredResponse` present else 4-row fallback GlassCard + disclaimer |
| Result card or loading spinner | `if _isAnalyzing` spinner `ai_processing`; else `TweenAnimationBuilder translate 30→0` (`298`) then card | — |

### HealthOverview `/health-overview`

| Element | Handler | Effect |
|---|---|---|
| Back chevron (44 paper, outline) | `context.pop()` (`85`) | `<= back` |
| Tune icon (right) | static | — |
| 5 pulsing hotspots + anatomy image | `AnimatedBuilder` pulse `scale 1.0→1.5 opacity 1.0→0.4` (`232-265`) | decorative |
| Metric cards (oxygen, kidney, heart rate, BP, cholesterol) | `_buildMetricCard` (`268`) | — |
| Bottom card 162cm · avatar · 64kg | static demo `kPatientData` | — |

### HealthRecords `/main/records` variant — `health_records_screen.dart` (mock admin toggle)

| Element | Handler | Effect |
|---|---|---|
| Admin/Patient view toggle (top-right text) | `setState(_isAdmin=!_isAdmin)` (`78`) | flips list source |
| Circular + Add record | `setState(_showAddModal=true)` (`80`) | overlay |
| Modal scrim / Cancel | `setState(_showAddModal=false)` (`108,126`) | close |
| Save inside modal | `onPress: _addRecord → setState(add to list)` (`128`) | local add |
| Record card (diagnosis/prescription) | `GestureDetector → context.push('/health-overview')` (`148`) | `=> /health-overview` |

### PatientRecords `/main/records` (real vault) `patient_records_screen.dart`

| Element | Handler | Effect |
|---|---|---|
| AppBar upload IconButton (cloud_upload) | `onPressed: Navigator.push(MaterialPageRoute(UploadRecordScreen))` then `if(result==true) _fetchRecords()` (`55`) | `=> UploadRecordScreen` via Navigator (not go_router) |
| AppBar refresh IconButton | `onPressed: _fetchRecords` → `MedicalRecordService.getMyRecords()` (`56`) | reload, shows offline branch if needed |
| Error state Retry | `ElevatedButton onPressed: _fetchRecords` (`75`) | reload |
| Empty Upload Record | `ElevatedButton.icon onPressed: Navigator.push(UploadRecordScreen)` (`78`) | `=> UploadRecordScreen` |
| Row trailing eye IconButton | `onPressed: if fileUrl startsWith data:image → base64Decode → showDialog(Dialog(InteractiveViewer(Image.memory))) else launchUrl(fileUrl) else SnackBar` (`94`) | Dialog or external URL |
| Scaffold maybe FAB | `ElevatedButton onPressed: Navigator.push(UploadRecordScreen)` (`65`) | — |

### UploadRecord `upload_record_screen.dart` (pushed via Navigator)

| Element | Handler | Effect |
|---|---|---|
| Camera | `OutlinedButton.icon onPressed: _pickImage(ImageSource.camera)` (`117`) | `ImagePicker.pickImage` → bytes → `base64Encode` → preview + store `fileUrl = data:image/...;base64,...` |
| Gallery | `OutlinedButton.icon onPressed: _pickImage(ImageSource.gallery)` (`119`) | same |
| Upload (amber 56h full width, disabled when `_isUploading`) | `onPressed: _upload` → `MedicalRecordService.uploadManualRecord(title,type,fileUrl)` (`POST /medical-records/upload` via SyncService if offline) → on success `Navigator.pop(context, true)`; on error SnackBar; spinner while uploading (`122-124`) | `<= pop true` → caller refresh |
| Optional title/type fields | `TextField` + `DropdownButton` for documentType | — |

### MedicineAvailability `/medicine?query=`

| Element | Handler | Effect |
|---|---|---|
| Query TextField (pre-filled from `queryParameters['query']`) | controller | — |
| Search button | `onPress: _search()` → `PharmacyService.searchPharmaciesLocal(query, lat, lon)` + `Geolocator.getCurrentPosition` fallback → sorts by Haversine `_calculateDistance` (`pharmacy_service:110`) → `PharmacySearchResult` list | renders cards with distanceKm, isAvailable pill, address |
| Pharmacy card Call / Route icons | `tel:` via `launchUrl`, `maps` via `launchUrl(https://maps...)` | dialer / maps |
| Cache refresh | `PharmacyService.syncPharmacies()` (`GET /api/pharmacy/list` → `cacheData cached_pharmacies`) | background via SyncService on online |

### EmergencyHelp `/emergency`

| Element | Widget | `onTap`/`onPressed` | Function |
|---|---|---|---|
| Back | `GestureDetector` (`186`) | `context.pop()` | `<= back` |
| SEND SOS + GPS (double red circle 220/180) | `GestureDetector Container` (`217`) | `_triggerSOS()` (`81`) | See §4.16: Geolocator permission → `getCurrentPosition(Accuracy.best)` → `mapsLink = https://www.google.com/maps/search/?api=1&query=lat,lng` → `message Uri.encodeComponent("EMERGENCY! I need help... $mapsLink")` → `phones = _contacts.map(phone).join(',')` → `launchUrl(Uri.parse("sms:$phones?body=$message"))` ; failure SnackBar; `_isLocating` true shows `CircularProgressIndicator` (`244`) |
| First-Aid horizontal cards (Snakebite, Burns, CPR, Poisoning 120×100) | `GestureDetector` (`277`) | `_showFirstAidDialog(guide)` → `AlertDialog` icon+title+content + **Understood** → `Navigator.pop` (`150`) | Dialog |
| Emergency response card (medical_services icon) | `GlassCard GestureDetector` (`306`) | `_handleCall('108')` → `launchUrl(Uri.parse('tel:108'))` (`74`) | dialer |
| Nearest PHC card (location_on) | `GlassCard GestureDetector` (`326`) | `_routeToNearestPHC()` → `launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=hospital+clinic+PHC"), externalApplication)` (`113`) | maps |
| Add ICE (In-Case-of-Emergency) TextButton.icon | `TextButton.icon` (`356`) | `_showAddContactDialog()` → 3 `TextField`s (Name, Relationship, Phone) → `AlertDialog Save Contact` → `_saveContact(name,rel,phone)` → `SharedPreferences.setString('ice_contacts', jsonEncode(_contacts))` + `setState` (`67`) | persists to prefs |
| Contacts list `GlassCard` rows (name, relation, phone + phone circle) | `GestureDetector` (`408`) | `_handleCall(phone)` → `tel:` (`74`) | dialer |

Seed contacts if no prefs (`:59`): `Ambulance 102`, `Dispatch Line 108`.

### ChatBot `/chatbot`

| Element | Widget | Handler | Effect |
|---|---|---|---|
| Back chevron (44 secondaryBg, 12r) | `GestureDetector Container` (`216`) | `context.pop()` | `<= back` |
| Header subtitle status dot + text `_statusSubtitle/_statusColor` | `Text` (`249`) | derived from `ConnectivityService.isOnline ? 'AI • Online' (green 4CAF50) : OfflineAiService model status (downloading/verifying/ready/lexiconOnly etc. orange FF9800)` (`82-119`) | display |
| OfflineStatusIndicator | `OfflineStatusIndicator(isOnline)` (`259`) | — | — |
| OfflineSetupCard (conditional) | `if (_showSetupCard && isOffline && status ∉ {ready,loaded,generating,lexiconOnly}) OfflineSetupCard(onDismiss: setState(false))` (`267`) | download/progress | — |
| Messages ListView (user dark bubble right, AI white left + memory icon) | `ListView.builder` (`280`) | each AI bubble shows pill `AI • Offline (FF9800 alpha0.15)` vs `AI • Online (4CAF50 alpha0.15)` based on `isOffline` (`329`) | — |
| Timestamp `HH:MM` per bubble | `Text("${hour:02}:${minute:02}")` | — | — |
| TextField hint `ask_health`, 1-4 lines | `TextField(controller:_inputCtrl, minLines:1, maxLines:4)` (`380`) | — | — |
| Send circle 44 (sage when `hasText` else CCC) | `ValueListenableBuilder GestureDetector` (`398`) | `onTap: hasText ? _handleSend : null` → builds user `Message` + `setState add` + `_scrollToBottom()` (`138`) → `await AiService.query(text)` (`141`) → prefixes `🚨 EMERGENCY 🚨` if `urgency=='emergency'` else `⚠️ Please consult` if `requiresProfessionalReview` (`146`) → computes `isOffline = agent=='offline_ai_router' || routingMethod.contains('offline')` → adds AI `Message(isOffline)` + scroll; on catch adds error AI message `Sorry... ${e}` (`168`) | chat history |
| Init | `OfflineAiService.instance.ensureModelLoaded()` on `initState` (`48`), `initial Greeting` `Dihati Assistant` message (`62`) | — | background |
| Subs | `modelSub` + `connSub` listen statusStream to `setState` (`50,53`) | — | — |

### Prescriptions `/prescriptions` (Patient)

| Element | Handler | Effect |
|---|---|---|
| List via `PrescriptionService.getPrescriptions(page,limit)` (`GET /api/prescriptions/me`) + cached `cached_prescriptions` fallback (`prescription_service:82-113`) | — | cards show `doctorName, specialization, date, diagnosis, medicines` (`MedicationSchedule` sub-rows), **View** detail opens inline `Dialog` with full `toDisplayMap()` |

### VideoCall `/video-call/:id`

| Element | Handler | Effect |
|---|---|---|
| Back/leave | `context.pop()` (`149,248`) | `<= back` |
| Mute toggle | `setState(_isMuted=!_isMuted)` (`224`) + native channel mute | — |
| Camera, end, etc. | `jitsi_meet_wrapper` join | — |
| Params | `pathParameters['id']` + `extra {doctorName, doctorPhone, isAudioOnly}` consumed in `initState` | — |
| Fallback entry | `CallService.startCall` pushes here when `FlutterPhoneDirectCaller.callNumber` returns `false` or throws (`call_service:46-59`) | `=> /video-call/:id` |

### Profile `/main/profile` (repeat for completeness)

Covered above; extra rows: **Language** → `showLanguageSelector`, **Notifications** → `context.push('/notifications')`, **Logout** → `AuthGuard.onLogout(); AuthService.logout(); context.go('/onboarding')` (`365-367`) which `clearAllData()` wipes sqflite + prefs token.

### Doctor — Requests / Consultations / Complete / Prescriptions etc.

| Screen | Tap target | Handler | Route / function |
|---|---|---|---|
| `DoctorRequests /doctor/requests` | Card (patient+reason) tap | open detail (local navigation or push) | — |
| | Voice note history icon (mic) | `showDialog(VoiceNoteHistoryDialog)` | Dialog play via `audioplayers` |
| | **Accept** ElevatedButton | `ConsultationService.acceptConsultation(id, notes)` (`PATCH /api/consultations/:id/accept` via `SyncService.push`) → `cache status ACTIVE` (`consultation_service:228`) → `setState remove from pending + SnackBar` | inline, no nav |
| | **Reject / Decline** | local dismiss or `updateStatus` to CANCELLED | — |
| `DoctorConsultations /doctor/consultations` | Filter tabs/chips (PENDING/ACTIVE/COMPLETED) | `setState filter → listDoctorConsultations(status)` (`listDoctorConsultations: GET /api/doctors/consultations?status=...` or cache) | local |
| | Row **View** | push detail page | — |
| | Row **Complete** | push `DoctorCompleteConsultation` (`Navigator.push` or `context.push`) | `=> DoctorCompleteConsultation` |
| `DoctorCompleteConsultation` | RiskLevel chips (emergency/high/moderate/low/insufficient) | `setState selectedRisk` | local |
| | Notes TextField | — | — |
| | **Complete consultation** PrimaryButton | `ConsultationService.completeConsultation(id, notes:..., riskLevel: selectedRisk.name)` (`PATCH /:id/complete`) → `_updateLocalCacheStatus(id,'COMPLETED')` → pop with success SnackBar (`252`) | `<= pop` |
| `DoctorPrescriptions` | List via `getDoctorPrescriptions` (`GET /api/doctors/prescriptions`) | — | — |
| | **New prescription** from consultation (inside detail) | `PrescriptionService.createPrescription(consultationId, medicines, instructions)` (`POST /api/prescriptions` via SyncService) → local draft if pending sync (`174`) | — |
| `DoctorPatients /doctor/patients` | Card → | `MedicalRecordService.getDoctorRecords(patientId)` (`GET /api/medical-records/patient/:patientId`) | — |
| `DoctorProfile /doctor/profile` | Edit fields + **Save** | `PATCH /api/doctors/me` (`DoctorService updateMyDoctor`) | SnackBar |
| `DoctorSettings` | — | static | — |
| `DoctorOnboarding /doctor/onboarding` (post-register doctor) | Form: specialization `TextField`/`Dropdown`, `experienceYears` number, `hospitalName`, `consultationFee`, `bio` `TextField` multiline, `isAvailable` `Switch`, `profileImageUrl` optional | **Submit** → `POST /api/doctors` (`createDoctor`) + `PATCH /doctors/me` fallback → `context.go('/doctor/requests')` | `=> /doctor/requests` |

### Pharmacy

| Screen | Element | Handler | Effect |
|---|---|---|---|
| `PharmacyDashboard /pharmacy/dashboard` | Inventory table row switch `inStock` | `onChanged → PharmacyService.updateInventory(medicineName, inStock)` (`POST /api/pharmacy/inventory`) (`pharmacy_service:87`) | server toggle |
| | Refresh | `PharmacyService.syncPharmacies()` (`GET /api/pharmacy/list` → `cacheData cached_pharmacies`) | reload |
| `MedicineAvailability /medicine` | Search TextField + **Search** button | `_search()` → awaits `Geolocator.getCurrentPosition` → `searchPharmaciesLocal(query, lat, lon)` (reads `cached_pharmacies`, `hasMedicine` fuzzy, `_calculateDistance` Haversine `12742*asin(sqrt(a))` (`110`), sorts `distanceKm asc`) | renders `PharmacySearchResult` cards (name, address, distanceKm, `isAvailable` badge green/grey, inventories chips) |
| | Call / Directions per pharmacy card | `launchUrl(tel:...)` / `launchUrl(maps search)` | external |
| `PrescriptionList /prescriptions` (also /prescriptions for patient) | same as patient Prescriptions above | — | — |

### Admin (`/admin/*` — all inside `DashboardLayout` + `Sidebar`)

Navigation is **sidebar-driven** (no card pushes): clicking a sidebar item calls `context.go('/admin/<section>')` (Sidebar: ListTile selected state). Content itself is tables/lists with inline actions.

| Screen | Interactive row / button | Handler | Effect |
|---|---|---|---|
| `/admin/dashboard` | StatCards (6) — group/doctors/patients/facilities/pharmacies/appointments | display only | — |
| | Recent Activity rows + StatusBadge (Completed/Active/Resolved) | display only | — |
| `/admin/users` | Search + role FilterDropdown + table rows **Edit / Delete IconButton** | `PATCH /api/users/:id` / `DELETE /api/users/:id` via `ApiClient` then `setState` refresh | inline |
| `/admin/doctors` | Table rows **Approve/Reject** (`ElevatedButton` / `OutlinedButton`) | `PATCH /api/doctors/:id` status update | inline |
| `/admin/patients` | Row **View records** | `context` still inside admin shell, calls `MedicalRecordService.getDoctorRecords(patientId)` style list or navigates to records list | inline dialog or push |
| `/admin/facilities` | **Add facility** `FloatingActionButton` / form Dialog + row **Edit/Delete** | `POST/PATCH/DELETE /api/facilities` (if mounted) then reload | Dialog |
| `/admin/pharmacies` | Table + inventory override | `POST /api/pharmacy/inventory` | inline |
| `/admin/appointments` | Status filter chips (PENDING/ACCEPTED/ACTIVE/COMPLETED) | `setState filter → listConsultations(status)` | local filter |
| `/admin/consultations` | Same consult table + **Assign doctor** (`ElevatedButton` inside row) | `ConsultationService.assignDoctor(consultationId, doctorId)` → `PATCH /api/consultations/:id/assign-doctor` | inline |
| `/admin/prescriptions` | Prescription table | `GET /api/prescriptions` (admin sees all) — display | — |
| `/admin/reports` | Period chips (Week/Month/Year) + export placeholder | local state | — |
| `/admin/settings` | Toggles (notifications etc.) + **Save** | `SharedPreferences` write + SnackBar | — |

> **Fallback nav everywhere:** `Navigator.push(...)` is only used for `UploadRecordScreen` (patient vault) because it is pushed as a modal with return value (`bool`); everything else uses `go_router` (`go` replaces, `push` stacks).

---

## End-to-End Flows (happy + offline variants)

### Flow A — First launch unauthenticated
```
/ → (auto or Get Started) /onboarding → (SlideButton) /login → (Continue success) => /main/home (patient)
If deep link e.g. /doctor/requests while unauthenticated => AuthGuard bounces to /onboarding before login.
```

### Flow B — Returning authenticated patient (token in prefs)
```
/ → AuthGuard.init restores role=patient → redirect from / to /main/home automatically (no Splash interaction needed)
```

### Flow C — Patient books a consultation
```
Home services card "Consult doctors" => /main/doctors
  → search/filter → tap doctor card => /doctor-details/:id
    → Book teleconsultation => /teleconsultation-request extra{doctorId,...}
      → pick reason chip + symptoms text + voice recorder base64 + time slot + VIDEO/AUDIO
        → Send request => ConsultationService.createConsultation => POST /api/consultations via SyncService.push
          online: {data: consultation} id real → success green screen → pop 1.8s => back to Home
          offline: {status:PENDING_SYNC, id:uuid} → queued in sync_queue, temp ConsultationModel status PENDING_SYNC → same success screen → pop
Home then shows Active Consultations strip (if doctor accepted and status ACTIVE) with Join / Record Note / Call Doctor
  Join => CallService.startCall => tel: or /video-call/:id => after call => updateStatus COMPLETED
```

### Flow D — Symptom checker online vs offline
```
Home services "Symptoms" => /main/symptoms
  → select chips + other text + optional mic pulse
    → Analyze => _analyze():
      if isEmergency(query) => ClinicalResponse.emergency (no network, amber card + SOS prompt)
      else try AiService.query("I have ...") => AiResponse → StructuredClinicalResponseCard (9-section) sourceLabel Online AI
      else (catch timeout/network) => OfflineAiService.queryOffline streamed + OfflineMedicalRepository.buildSymptomCheckerContext → fallback card source Offline AI
```

### Flow E — Chatbot online vs offline
```
/chatbot (from FAB anywhere) — header shows AI • Online (green) or AI • Offline + Setup card
  user types health question → send circle (sage when hasText)
    → AiService.query(text):
       1. POST https://gramhealthapp.onrender.com/api/ai/query {query, patientId?} Bearer token, timeout 120s, header X-Request-ID
       2. 401/403 => throw auth error (no offline fallback per AiService:50)
       3. 200 => parse data.answer; if contains "AI reasoning service is currently unavailable"/"AI response generation failed" treat as failure
          else return AiResponse{intent,agent,answer,grounded,confidence,urgency,...}
       4. 502/503/504 or SocketException/Timeout => isNetworkOrBackendUnavailable=true => fallback if !debugForceOnlineAi:
          await OfflineAiService.initialise(); isEmergency? => offline ai agent routing; stream offlineText => wrap as AiResponse(intent:emergency/offline_medical, agent:offline_ai_router,...)
       5. debugForceOnlineAi==true => rethrow online error (no silent fallback)
  UI tags bubble Online (green) vs Offline (orange) via agent/routingMethod; emergency prefix 🚨; professional review ⚠️
```

### Flow F — Health vault
```
Home services "Records" => /main/records (PatientRecords)
  → AppBar upload (cloud_upload) => Navigator.push UploadRecordScreen
    → Camera/Gallery pick => base64 data:image/... → title+type form → Upload (amber 56h) => MedicalRecordService.uploadManualRecord(title,type,fileUrl)
       online: POST /api/medical-records/upload Authorization Bearer, body {title,documentType,fileUrl,issuedDate} → 201 => pop(true)
       offline: cacheData cached_records tempId optimistic + SyncService.push POST /medical-records/upload queued => pop(true) with temp card showing as optimistic
  → List tile eye => data:image? Dialog(InteractiveViewer(Image.memory(base64))) else launchUrl(fileUrl)
  → Pull/refreshIcon => MedicalRecordService.getMyRecords() GET /api/medical-records/me (online) or getAllCachedData cached_records (offline)
```

### Flow G — SOS emergency (always works, even offline for first-aid cards)
```
Home services Emergency => /emergency
  → SEND SOS+GPS big red => Geolocator permission → getCurrentPosition best → mapsLink => sms:phones?body=mapsLink where phones = SharedPreferences ice_contacts else 102,108
  → First-aid horizontal cards tap => AlertDialog(guide content)
  → tiles: Emergency response tel:108, Nearest PHC maps search hospital clinic PHC, Add ICE dialog persists to ice_contacts, per-contact phone circles tel:
```

### Flow H — Doctor
```
/doctor/requests (doctor login) => listDoctorConsultations(status PENDING) — pull to refresh
  → tap request row => detail + voiceNotes history dialog (audioplayers play)
    → Accept => PATCH /consultations/:id/accept (SyncService) => status ACTIVE => moves to /doctor/consultations
    → from /doctor/consultations row Complete => DoctorCompleteConsultation form (riskLevel + notes)
       → Complete => PATCH /:id/complete + riskLevel => COMPLETED => returns to consultations list
  → Prescriptions tab lists /doctors/prescriptions => create via consultation detail + createPrescription POST /prescriptions via SyncService
```

### Flow I — Admin & Pharmacy
```
Admin login => /admin/dashboard (Sidebar nav). Every section is context.go from Sidebar inside DashboardLayout.
Pharmacy login => /pharmacy/dashboard (inventory table) — update via POST /pharmacy/inventory (PHARMACY role only).
MedicineAvailability /medicine?query=paracetamol => searchPharmaciesLocal over cached_pharmacies (Haversine) sorted distance.
```

---

*Next: doc 03 — every `POST/GET/PATCH/DELETE` backend binding, AI gateway, and how to reattach the new frontend to the hosted Render backend without touching it.*
