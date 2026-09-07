import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_language.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/doctor_list_screen.dart';
import 'screens/doctor_details_screen.dart';
import 'screens/symptom_checker_screen.dart';
import 'screens/patient_records_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/teleconsultation_request_screen.dart';
import 'screens/prescription_list_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/emergency_help_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/doctor_requests_screen.dart';
import 'screens/doctor_appointments_screen.dart';
import 'screens/doctor_patients_screen.dart';
import 'screens/doctor_consultations_screen.dart';
import 'screens/doctor_prescriptions_screen.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/doctor_settings_screen.dart';
import 'screens/doctor_onboarding_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'utils/auth_guard.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_doctors_screen.dart';
import 'screens/admin_patients_screen.dart';
import 'screens/admin_appointments_screen.dart';
import 'screens/admin_consultations_screen.dart';
import 'screens/admin_prescriptions_screen.dart';
import 'screens/admin_pharmacies_screen.dart';
import 'screens/admin_facilities_screen.dart';
import 'screens/admin_reports_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/medicine_availability_screen.dart';
import 'screens/pharmacy_dashboard_screen.dart';
import 'screens/health_overview_screen.dart';
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
      builder: (c, s) => const DoctorDashboardScreen(),
      routes: [
        GoRoute(
            path: 'dashboard',
            builder: (c, s) => const DoctorDashboardScreen()),
        GoRoute(
            path: 'requests',
            builder: (c, s) => const DoctorRequestsScreen()),
        GoRoute(
            path: 'appointments',
            builder: (c, s) => const DoctorAppointmentsScreen()),
        GoRoute(
            path: 'patients',
            builder: (c, s) => const DoctorPatientsScreen()),
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
        GoRoute(
            path: 'settings',
            builder: (c, s) => const DoctorSettingsScreen()),
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

