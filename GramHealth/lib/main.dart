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
import 'screens/health_records_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/teleconsultation_request_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/emergency_help_screen.dart';
import 'screens/medicine_availability_screen.dart';
import 'screens/health_overview_screen.dart';

void main() {
  runApp(const RuralCareApp());
}

class RuralCareApp extends StatelessWidget {
  const RuralCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        // Main shell with bottom tabs
        GoRoute(
          path: '/main',
          builder: (c, s) => const MainShell(child: HomeScreen()),
          routes: [
            GoRoute(path: 'home', builder: (c, s) => const MainShell(child: HomeScreen())),
            GoRoute(path: 'doctors', builder: (c, s) => const MainShell(child: DoctorListScreen())),
            GoRoute(path: 'symptoms', builder: (c, s) => const MainShell(child: SymptomCheckerScreen())),
            GoRoute(path: 'records', builder: (c, s) => const MainShell(child: HealthRecordsScreen())),
            GoRoute(path: 'profile', builder: (c, s) => const MainShell(child: ProfileScreen())),
          ],
        ),
        // Push routes
        GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
        GoRoute(path: '/chatbot', builder: (c, s) => const ChatBotScreen()),
        GoRoute(
          path: '/doctor-details/:id',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '1';
            return DoctorDetailsScreen(doctorId: id);
          },
        ),
        GoRoute(path: '/teleconsultation-request', builder: (c, s) => const TeleconsultationRequestScreen()),
        GoRoute(
          path: '/video-call/:id',
          builder: (c, s) {
            final id = s.pathParameters['id'] ?? '1';
            return VideoCallScreen(doctorId: id);
          },
        ),
        GoRoute(path: '/emergency', builder: (c, s) => const EmergencyHelpScreen()),
        GoRoute(path: '/medicine', builder: (c, s) => const MedicineAvailabilityScreen()),
        GoRoute(path: '/health-overview', builder: (c, s) => const HealthOverviewScreen()),
      ],
    );

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageController.instance.currentLanguage,
      builder: (context, lang, child) {
        return MaterialApp.router(
          key: ValueKey(lang.code),
          debugShowCheckedModeBanner: false,
          title: 'RuralCare',
          theme: AppTheme.theme,
          routerConfig: router,
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
