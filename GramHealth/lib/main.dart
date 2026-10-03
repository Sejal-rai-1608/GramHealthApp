import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'services/offline_ai_service.dart';
import 'utils/auth_guard.dart';

import 'l10n/app_language.dart';
import 'theme/app_theme.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/onboarding_screen.dart';
import 'screens/common/login_screen.dart';
import 'screens/common/main_shell.dart';
import 'screens/common/home_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/common/notifications_screen.dart';
import 'screens/common/chatbot_screen.dart';
import 'screens/common/video_call_screen.dart';
import 'screens/common/emergency_help_screen.dart';

import 'screens/patient/symptom_checker_screen.dart';
import 'screens/patient/patient_records_screen.dart';
import 'screens/patient/teleconsultation_request_screen.dart';
import 'screens/patient/health_overview_screen.dart';

import 'screens/doctor/doctor_list_screen.dart';
import 'screens/doctor/doctor_details_screen.dart';
import 'screens/doctor/doctor_requests_screen.dart';
import 'screens/doctor/doctor_consultations_screen.dart';
import 'screens/doctor/doctor_prescriptions_screen.dart';
import 'screens/doctor/doctor_profile_screen.dart';
import 'screens/doctor/doctor_onboarding_screen.dart';

import 'screens/common/forgot_password_screen.dart';
import 'screens/pharmacy/prescription_list_screen.dart';
import 'screens/pharmacy/medicine_availability_screen.dart';
import 'screens/pharmacy/pharmacy_dashboard_screen.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_doctors_screen.dart';
import 'screens/admin/admin_patients_screen.dart';
import 'screens/admin/admin_appointments_screen.dart';
import 'screens/admin/admin_consultations_screen.dart';
import 'screens/admin/admin_prescriptions_screen.dart';
import 'screens/admin/admin_pharmacies_screen.dart';
import 'screens/admin/admin_facilities_screen.dart';
import 'screens/admin/admin_reports_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AuthGuard.init(); // Restore session from secure storage
  ConnectivityService.instance.initialize();
  SyncService.instance.initialize();
  runApp(const RuralCareApp());
}
final _router = GoRouter(
  initialLocation: '/',
  redirect: AuthGuard.redirect,
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(
        path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
    // Patient routes (role: patient)
    GoRoute(
      path: '/main',
      builder: (c, s) => const MainShell(child: HomeScreen()),
      routes: [
        GoRoute(
            path: 'home',
            builder: (c, s) => const MainShell(child: HomeScreen())),
        GoRoute(
            path: 'doctors',
            builder: (c, s) => const MainShell(child: DoctorListScreen())),
        GoRoute(
            path: 'symptoms',
            builder: (c, s) =>
                const MainShell(child: SymptomCheckerScreen())),
        GoRoute(
            path: 'records',
            builder: (c, s) =>
                MainShell(child: PatientRecordsScreen())),
        GoRoute(
            path: 'profile',
            builder: (c, s) => const MainShell(child: ProfileScreen())),
      ],
    ),
    // Doctor routes (role: doctor)
    GoRoute(
      path: '/doctor',
      builder: (c, s) => const DoctorRequestsScreen(),
      routes: [
        GoRoute(
            path: 'requests',
            builder: (c, s) => const DoctorRequestsScreen()),
        GoRoute(
            path: 'consultations',
            builder: (c, s) => const DoctorConsultationsScreen()),
        GoRoute(
            path: 'prescriptions',
            builder: (c, s) => const DoctorPrescriptionsScreen()),
        GoRoute(
            path: 'profile',
            builder: (c, s) => const DoctorProfileScreen()),
        GoRoute(
            path: 'onboarding',
            builder: (c, s) => const DoctorOnboardingScreen()),
      ],
    ),
    // Admin routes (role: admin)
    GoRoute(
      path: '/admin',
      builder: (c, s) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
            path: 'dashboard',
            builder: (c, s) => const AdminDashboardScreen()),
        GoRoute(
            path: 'users', builder: (c, s) => const AdminUsersScreen()),
        GoRoute(
            path: 'doctors',
            builder: (c, s) => const AdminDoctorsScreen()),
        GoRoute(
            path: 'patients',
            builder: (c, s) => const AdminPatientsScreen()),
        GoRoute(
            path: 'appointments',
            builder: (c, s) => const AdminAppointmentsScreen()),
        GoRoute(
            path: 'consultations',
            builder: (c, s) => const AdminConsultationsScreen()),
        GoRoute(
            path: 'prescriptions',
            builder: (c, s) => const AdminPrescriptionsScreen()),
        GoRoute(
            path: 'pharmacies',
            builder: (c, s) => const AdminPharmaciesScreen()),
        GoRoute(
            path: 'healthcare-facilities',
            builder: (c, s) => const AdminFacilitiesScreen()),
        GoRoute(
            path: 'reports',
            builder: (c, s) => const AdminReportsScreen()),
        GoRoute(
            path: 'settings',
            builder: (c, s) => const AdminSettingsScreen()),
      ],
    ),
    // Pharmacy routes (role: pharmacy)
    GoRoute(
      path: '/pharmacy/dashboard',
      builder: (c, s) => const PharmacyDashboardScreen(),
    ),
    // Shared push routes
    GoRoute(
        path: '/notifications',
        builder: (c, s) => const NotificationsScreen()),
    GoRoute(path: '/chatbot', builder: (c, s) => const ChatBotScreen()),
    GoRoute(
      path: '/doctor-details/:id',
      builder: (c, s) {
        final id = s.pathParameters['id'] ?? '1';
        return DoctorDetailsScreen(doctorId: id);
      },
    ),
    GoRoute(
        path: '/teleconsultation-request',
        builder: (c, s) => const TeleconsultationRequestScreen()),
    GoRoute(
        path: '/prescriptions',
        builder: (c, s) => const PrescriptionListScreen()),
    GoRoute(
      path: '/video-call/:id',
      builder: (c, s) {
        final id = s.pathParameters['id'] ?? '1';
        return VideoCallScreen(doctorId: id);
      },
    ),
    GoRoute(
        path: '/emergency',
        builder: (c, s) => const EmergencyHelpScreen()),
    GoRoute(
        path: '/medicine',
        builder: (c, s) {
          final query = s.uri.queryParameters['query'] ?? '';
          return MedicineAvailabilityScreen(medicineQuery: query);
        },
    ),
    GoRoute(
        path: '/health-overview',
        builder: (c, s) => const HealthOverviewScreen()),
  ],
);

class RuralCareApp extends StatelessWidget {
  const RuralCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageController.instance.currentLanguage,
      builder: (context, lang, child) {
        return MaterialApp.router(
          key: ValueKey(lang.code),
          debugShowCheckedModeBanner: false,
          title: 'RuralCare',
          theme: AppTheme.theme,
          routerConfig: _router,
          locale: lang.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
            Locale('gu'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}

