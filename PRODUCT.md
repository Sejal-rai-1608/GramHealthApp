# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

GramHealth serves people in rural and underserved communities who need straightforward access to healthcare. Its confirmed role groups are:

- Patients managing consultations, prescriptions, health records, symptoms, and nearby care.
- Doctors handling consultation requests, appointments, patient context they are authorized to see, clinical notes, and prescriptions.
- Pharmacists managing medicine availability and prescription fulfillment.
- Administrators managing users, providers, consultations, prescriptions, pharmacies, facilities, and reports.

## Product Purpose

GramHealth is an offline-first healthcare application that connects patients with doctors, pharmacies, and nearby healthcare facilities. It supports the complete consultation journey: finding care, requesting and conducting consultations, recording clinical outcomes, issuing prescriptions, following treatment plans, and reviewing health history. Success means that people can complete essential healthcare tasks safely and clearly even when connectivity is limited.

## Positioning

The product combines rural-care workflows with an offline-first Flutter client: cached records and queued changes remain useful during unreliable connectivity, while multilingual UI and offline AI/safety fallbacks support patients who may have limited access to continuous network service. Healthcare privacy and role-based access are part of the product promise, not merely implementation details.

## Operating Context

- The primary client is the Flutter application in `GramHealth/`, with an Android-first mobile and tablet experience. An iOS target also exists in the repository, but Android is the confirmed priority for this UI context.
- Network conditions may be intermittent. The client uses local persistence, connectivity status, background synchronization, and online/offline service routing.
- Core workflows include onboarding and authentication, role-based dashboards, doctor discovery, symptom checking, teleconsultation, video calls, prescriptions and medication schedules, medical records, pharmacy lookup, nearby healthcare search, notifications, and emergency help.
- The application supports English, Hindi, Marathi, and Gujarati through the existing localization layer.
- The repository also contains a Node.js backend and a separate AI service. Those remain supporting product context; this init's visual scope is the Flutter client.

## Capabilities and Constraints

- Preserve the existing authentication, routing, role boundaries, API/service architecture, offline cache and sync behavior, and healthcare data privacy expectations.
- A patient must not see another patient's medical records. A doctor must only see patient information authorized by the existing security model. Backend authorization remains authoritative.
- Do not invent clinical claims, medical guidance, testimonials, metrics, or healthcare facility data as part of UI work.
- For future Impeccable visual revamps, focus on `GramHealth/lib/**/*.dart`, especially screens, reusable widgets, `theme/` files, Dart `CustomPainter`/`CustomPaint` implementations when present or introduced, and Flutter layout composition (`Row`, `Column`, `Flex`, `Stack`, slivers, adaptive navigation, constraints, and responsive breakpoints).
- Keep `backend/`, `gramhealth-ai/`, generated Android/iOS platform files, data/service internals, and tests out of visual-scope changes unless a UI behavior or build check explicitly requires a supporting edit.
- Prefer reusable Flutter widgets and the existing Material 3 theme rather than duplicating one-off screen styling. Preserve loading, error, empty, offline, permission-denied, and emergency states while improving the look and feel.

## Brand Commitments

- The workspace identity is GramHealth/GramHealthApp. The existing Flutter package and app title use the name RuralCare; preserve both references until the owner makes a canonical naming decision.
- Healthcare should feel trustworthy, calm, practical, and understandable for non-technical patients.
- The current client has an established green botanical palette, Material 3 theming, and reusable glass/card/button components. These are incumbent implementation evidence, not a mandate to keep every visual treatment unchanged during the requested revamp.

## Evidence on Hand

- `PROJECT_STRUCTURE.md` documents the Flutter client, roles, workflows, screens, widgets, offline-first architecture, and backend boundary.
- `GramHealth/README.md` documents the RuralCare healthcare purpose, responsive Flutter client, localization, consultation/prescription workflows, accessibility expectations, and privacy requirements.
- `GramHealth/pubspec.yaml` confirms Flutter, GoRouter, Material 3-compatible theming dependencies, maps, connectivity, local persistence, audio, location, and healthcare-related integrations.
- `GramHealth/lib/main.dart` confirms role-based routing for patient, doctor, pharmacy, admin, and shared flows.
- `GramHealth/lib/theme/app_theme.dart` and `GramHealth/lib/theme/app_colors.dart` document the incumbent theme and reusable color system.
- No separate product brief or design authority was present before this init. No clinical evidence or user research was supplied; future work must not fabricate either.

## Product Principles

1. Make essential care tasks understandable at a glance, especially for patients under stress or with limited technical familiarity.
2. Design for intermittent connectivity without hiding status, losing user work, or weakening safety messaging.
3. Preserve strict role boundaries and healthcare privacy throughout every workflow.
4. Use multilingual, accessible, responsive Flutter patterns that remain usable on Android phones and tablets.
5. Improve visual coherence through reusable Dart widgets and theme primitives rather than screen-by-screen decoration.

## Accessibility & Inclusion

- Support the confirmed English, Hindi, Marathi, and Gujarati locales without relying on English-only labels or fixed-width text.
- Keep patient-facing language clear and avoid unnecessary medical terminology.
- Preserve the repository's responsive mobile/tablet and accessibility goals; layouts must tolerate Android text scaling, localization expansion, the on-screen keyboard, system insets, and offline/error states without clipping or hiding critical actions.
- Keep touch interactions usable for a broad range of patients, including people using lower-end Android hardware or inconsistent connectivity.
