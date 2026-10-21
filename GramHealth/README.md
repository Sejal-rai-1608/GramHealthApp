# RuralCare Flutter

## Overview
RuralCare is a Flutter application aimed at providing essential healthcare services to remote and underserved communities. This project serves as a starter template, showcasing best practices in Flutter architecture, theming, state management, and integration with backend services.

## Features
- Clean, modular architecture using the **Provider** pattern.
- Custom theming with light and dark modes.
- Integrated health data models and REST API client.
- Responsive UI supporting mobile and tablet form‑factors.
- Internationalization (i18n) ready.

## Getting Started
### Prerequisites
- Flutter SDK (≥ 3.22.0)
- Android Studio / VS Code with Flutter plugins
- A device or emulator (Android/iOS) for testing

### Installation
```bash
# Clone the repository
git clone https://github.com/your-org/ruralcare_flutter.git
cd ruralcare_flutter

# Get Flutter dependencies
flutter pub get
```

### Running the App
```bash
# Launch on connected device or emulator
flutter run
```

## Project Structure
```
lib/
├─ theme/               # App theming (colors, text styles)
│   ├─ app_theme.dart
│   └─ app_colors.dart
├─ models/              # Data models (e.g., Patient, Appointment)
├─ services/            # API clients, repositories
├─ screens/             # UI screens and widgets
└─ main.dart            # App entry point
```

## Testing
Unit and widget tests are located in the `test/` directory.
```bash
flutter test
```

## Contributing
Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Write tests for new functionality.
4. Submit a pull request.

## License
This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

I have an existing healthcare application. I want to extend the current app by adding a complete healthcare consultation management system.

IMPORTANT:

* Do NOT rebuild the entire application from scratch.
* First understand the existing project structure, frontend, backend, database, authentication, routing, components, theme, and API architecture.
* Reuse the existing UI components, design system, authentication, API services, and database wherever possible.
* Keep the existing features working.
* Make the new features production-ready, responsive, clean, and consistent with the existing application.
* Implement both frontend and backend wherever required.
* Add proper role-based access control for Patient, Doctor, and Admin.
* Do not use fake/static data in the final implementation if the existing backend/database can support real data.

## 1. PATIENT – PRESCRIPTION / TREATMENT AFTER CONSULTATION

After a doctor completes a consultation, the patient should be able to see the complete prescription/treatment plan.

Create a dedicated "Prescription / Treatment" section.

The patient should see:

### Prescription Details

* Doctor name
* Doctor specialization
* Consultation date and time
* Diagnosis / health issue
* Doctor's notes
* Medicines prescribed
* Medicine name
* Dosage
* Quantity
* Frequency
* Timing
* Duration
* Before food / after food
* Special instructions
* Follow-up date
* Additional recommendations

Example:

Medicine: Paracetamol
Dosage: 500 mg
Frequency: 2 times a day
Timing: Morning and Night
Duration: 5 days
Instruction: After food

Make the medicine schedule extremely easy for the patient to understand.

Display a "Today's Medication" view where the patient can clearly see:

Morning

* Medicine name
* Dose
* Whether it should be taken before/after food

Afternoon

* Medicine name
* Dose

Night

* Medicine name
* Dose

Also provide:

* Treatment start date
* Treatment end date
* Remaining days
* Completed medicines
* Upcoming medicines
* Follow-up reminder

If appropriate for the existing architecture, allow medication reminders/notifications.

The patient should be able to open previous prescriptions from consultation history.

## 2. DOCTOR – CREATE PRESCRIPTION AFTER CONSULTATION

When a doctor completes an appointment/consultation, provide a "Complete Consultation" workflow.

Doctor should be able to enter:

* Symptoms
* Diagnosis
* Doctor's observations
* Prescription
* Medicines
* Dosage
* Frequency
* Timing
* Duration
* Food instructions
* Additional instructions
* Follow-up date

Doctor should be able to add multiple medicines dynamically.

Example:

* Add Medicine

Each medicine should have structured fields:

* Medicine name
* Dosage
* Frequency
* Time
* Duration
* Food instruction
* Notes

After submitting:

1. Consultation should be marked as completed.
2. Prescription should be stored in the database.
3. Patient should immediately be able to view the prescription.
4. Prescription should appear in the patient's consultation history.
5. Doctor should be able to view the prescription later.
6. Admin should be able to manage/view prescription records according to permissions.

Add validation so incomplete prescriptions cannot accidentally be submitted.

## 3. PATIENT – CONSULTATION HISTORY

Create a "Consultation History" section.

Display:

* Doctor
* Specialization
* Consultation date
* Consultation status
* Diagnosis
* Prescription availability
* Follow-up date

Each consultation should have:

View Details

Inside details:

* Doctor information
* Consultation information
* Diagnosis
* Notes
* Prescription
* Treatment plan
* Follow-up instructions

Allow patients to easily distinguish:

* Upcoming consultation
* Completed consultation
* Cancelled consultation

## 4. NEARBY HEALTHCARE / HOSPITAL INFORMATION

Add a "Nearby Healthcare" feature.

The patient should be able to find nearby:

* Hospitals
* Clinics
* Pharmacies
* Diagnostic/Lab centers
* Emergency healthcare facilities

Use the appropriate map/location API supported by the existing project.

Request location permission properly.

Display nearby healthcare facilities with:

* Name
* Type
* Distance
* Address
* Phone number
* Opening hours, if available
* Rating, if available
* Emergency availability, if available

Provide actions:

* View Details
* Get Directions
* Call
* Open in Maps

Create a clean map + list interface.

If location permission is denied:

* Allow manual location/search.
* Do not break the application.

IMPORTANT:
Do not expose or store precise patient location unnecessarily.
Use location only for finding nearby healthcare services unless the existing application explicitly requires location storage.

## 5. DOCTOR DASHBOARD

Create/extend a dedicated Doctor Dashboard.

Doctor dashboard should contain:

### Overview

* Today's appointments
* Pending consultation requests
* Total patients
* Completed consultations
* Upcoming appointments

### Requests

Doctor should be able to:

* View consultation requests
* Accept request
* Reject request
* View patient information
* View requested consultation reason

### Appointments

Doctor should be able to:

* View today's appointments
* Upcoming appointments
* Completed appointments
* Cancelled appointments
* Open appointment details
* Start consultation
* Complete consultation

### Patients

Doctor should be able to:

* View assigned/consulted patients
* Search patients
* Open patient profile
* View relevant consultation history
* View previous prescriptions
* Add consultation notes

Only show patient information that the doctor is authorized to access.

### Consultation History

Doctor should be able to view:

* Previous consultations
* Diagnosis
* Notes
* Prescriptions
* Follow-up information

### Prescription Management

Doctor should be able to:

* Create prescription
* Edit prescription where permitted
* View previous prescriptions
* Add multiple medicines
* Set dosage/frequency/duration
* Add treatment instructions
* Set follow-up date

Create a professional healthcare dashboard with sidebar navigation.

Suggested navigation:

Dashboard
Requests
Appointments
Patients
Consultations
Prescriptions
Profile
Settings

## 6. ADMIN DASHBOARD

Create/extend an Admin Dashboard for complete system management.

Admin navigation:

Dashboard
Users
Doctors
Patients
Appointments
Consultations
Prescriptions
Pharmacies
Hospitals/Healthcare Facilities
Reports
System Settings

### Admin Overview

Show:

* Total users
* Total patients
* Total doctors
* Pending doctor approvals
* Today's appointments
* Completed consultations
* Active pharmacies
* Healthcare facilities
* System activity

### User Management

Admin can:

* View users
* Search users
* Filter users by role
* View user details
* Activate/deactivate users
* Manage account status

Roles:

* Patient
* Doctor
* Admin

### Doctor Management

Admin can:

* View doctors
* Add doctor
* Edit doctor
* Approve/reject doctor registration
* Activate/deactivate doctor
* View specialization
* View qualifications
* View consultation statistics

Doctor profile should support:

* Name
* Profile photo
* Specialization
* Qualification
* Experience
* License/registration information if already supported
* Contact information
* Availability
* Verification status

### Pharmacy Management

Admin can:

* Add pharmacy
* Edit pharmacy
* Remove/deactivate pharmacy
* View pharmacy details
* Manage pharmacy status

### Healthcare Facility Management

Admin can manage:

* Hospitals
* Clinics
* Diagnostic centers
* Emergency facilities

Fields may include:

* Name
* Type
* Address
* Contact
* Coordinates/location
* Opening hours
* Emergency availability
* Status

## 7. ROLE-BASED ACCESS CONTROL

Implement proper RBAC.

Patient:

* Own profile
* Own appointments
* Own consultations
* Own prescriptions
* Nearby healthcare

Doctor:

* Doctor dashboard
* Assigned requests
* Appointments
* Authorized patient information
* Consultations
* Prescriptions
* Doctor profile

Admin:

* Complete system management
* Users
* Doctors
* Patients
* Appointments
* Healthcare facilities
* Pharmacies
* System configuration

A patient must NEVER be able to access another patient's medical records.

A doctor must only access patient information that they are authorized to access.

Admin access should follow the existing security architecture.

## 8. DATABASE / BACKEND

Inspect the existing database before making changes.

If required, introduce or update entities such as:

User
Patient
Doctor
Appointment
Consultation
Prescription
PrescriptionMedicine
Medicine
HealthcareFacility
Pharmacy
Notification

Suggested relationships:

User
→ Patient / Doctor / Admin

Patient
→ Appointments
→ Consultations
→ Prescriptions

Doctor
→ Appointments
→ Consultations
→ Prescriptions

Consultation
→ Prescription

Prescription
→ Multiple PrescriptionMedicines

HealthcareFacility
→ Location information

Do not duplicate existing models unnecessarily.

Use proper foreign keys, indexes, validation, timestamps, and relationships according to the existing backend/database technology.

## 9. API REQUIREMENTS

Follow the existing API architecture.

Create endpoints/services for:

Patient:

* Get appointments
* Get consultation history
* Get prescription
* Get medication schedule
* Search nearby healthcare

Doctor:

* Get consultation requests
* Accept/reject request
* Get appointments
* Get authorized patients
* Create consultation
* Complete consultation
* Create prescription
* Get prescription history

Admin:

* Manage users
* Manage doctors
* Manage pharmacies
* Manage healthcare facilities
* Manage system records

Protect every endpoint using authentication and role-based authorization.

## 10. UI/UX REQUIREMENTS

Maintain the existing application's design language.

Make the interface:

* Modern
* Clean
* Healthcare-focused
* Responsive
* Mobile-friendly
* Accessible
* Easy for non-technical patients

Prescription screen should be especially simple.

Use clear visual sections such as:

Today's Medicines
Morning
Afternoon
Night

Treatment Progress

Follow-up

Doctor's Instructions

Avoid overwhelming patients with unnecessary medical terminology.

## 11. NOTIFICATIONS

If notification infrastructure already exists, integrate with it.

Possible notifications:

Patient:

* Appointment confirmation
* Appointment reminder
* New prescription available
* Medication reminder
* Follow-up reminder

Doctor:

* New consultation request
* Appointment reminder

Admin:

* New doctor registration
* Pending approval
* Important system events

Do not add an entirely new notification infrastructure if an existing one can be reused.

## 12. SECURITY & PRIVACY

Because this application handles healthcare information:

* Protect medical records.
* Never expose another patient's data.
* Validate all API requests.
* Implement authorization on backend, not only frontend.
* Avoid storing unnecessary sensitive information.
* Do not expose database credentials/API keys in frontend code.
* Sanitize user inputs.
* Use secure authentication.
* Log important administrative actions where appropriate.
* Follow the application's existing security and privacy architecture.

## 13. IMPLEMENTATION PROCESS

Before coding:

1. Inspect the complete existing project.
2. Identify frontend framework.
3. Identify backend framework.
4. Identify database.
5. Identify authentication system.
6. Identify existing user roles.
7. Identify existing appointment/consultation functionality.
8. Identify reusable components.
9. Identify existing API/service architecture.
10. Identify existing dashboard components.

Then create an implementation plan.

After that:

1. Update database schema/models.
2. Create/update backend APIs.
3. Implement RBAC.
4. Implement Patient Prescription/Treatment.
5. Implement Consultation History.
6. Implement Nearby Healthcare.
7. Implement Doctor Dashboard.
8. Implement Admin Dashboard.
9. Connect all frontend screens to real APIs.
10. Add loading/error/empty states.
11. Add form validation.
12. Test role permissions.
13. Test complete patient → doctor → prescription flow.
14. Fix all build/runtime errors.
15. Ensure existing features still work.

## 14. COMPLETE USER FLOW

The final application should support this complete flow:

Patient
→ Search/Book Doctor
→ Consultation Request
→ Doctor receives Request
→ Doctor accepts
→ Appointment
→ Consultation
→ Doctor enters Diagnosis + Prescription
→ Complete Consultation
→ Prescription saved
→ Patient receives notification
→ Patient opens Prescription
→ Patient sees Today's Medication Schedule
→ Patient follows Treatment
→ Follow-up Reminder
→ Consultation History updated

Also:

Patient
→ Nearby Healthcare
→ Detect/Search Location
→ Hospitals / Clinics / Pharmacies / Labs
→ View Details
→ Call / Directions / Maps

And:

Doctor
→ Doctor Dashboard
→ Requests
→ Appointments
→ Patient
→ Consultation
→ Prescription
→ Consultation History

Admin
→ Admin Dashboard
→ Users
→ Doctors
→ Patients
→ Appointments
→ Consultations
→ Prescriptions
→ Pharmacies
→ Healthcare Facilities
→ System Management

IMPORTANT FINAL REQUIREMENT:

Do not just create static UI screens.

Implement the complete functional flow using the existing frontend, backend, database, authentication, and APIs.

Before modifying files, inspect the project and explain:

* What already exists
* What needs to be added
* Which files will be modified
* Which database models will change
* Which APIs will be added
* Which screens/components will be added

Then implement the changes systematically without breaking existing functionality.
---

*For detailed documentation, refer to the `docs/` folder and the inline code comments.*
