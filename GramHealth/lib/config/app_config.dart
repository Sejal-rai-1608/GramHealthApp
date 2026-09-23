/// Centralised application configuration.
///
/// Standardised for production deployment on Render and local development:
/// - In production: Flutter connects to Node.js backend on Render (https://gramhealthapp.onrender.com)
/// - In local dev: Flutter connects to local Node.js backend (http://127.0.0.1:3000)
/// - Node.js backend is the sole gateway to the Python AI service (no direct client-to-AI calls)
class AppConfig {
  AppConfig._();

  // ── Live Backend URL (Render Production Deployment) ───────────────────
  static const String liveBackendUrl = 'https://gramhealthapp.onrender.com';

  // ── Local Backend URL (Local development via ADB reverse or desktop) ──
  static const String localBackendUrl = 'http://127.0.0.1:3000';

  // ── Base URL ──────────────────────────────────────────────────────────
  // For local testing on physical Android device connected via ADB reverse:
  // 'adb reverse tcp:3000 tcp:3000' routes 127.0.0.1:3000 directly to host Node backend.
  static String get baseUrl => localBackendUrl;

  // ── API Routes (All routed strictly through Node.js backend) ───────────
  static String get apiAuth           => '$baseUrl/api/auth';
  static String get apiDoctors        => '$baseUrl/api/doctors';
  static String get apiPatients       => '$baseUrl/api/patients';
  static String get apiConsultations  => '$baseUrl/api/consultations';
  static String get apiMedicalRecords => '$baseUrl/api/medical-records';
  static String get apiPrescriptions  => '$baseUrl/api/prescriptions';
  static String get apiUsers          => '$baseUrl/api/users';
  static String get apiPharmacy       => '$baseUrl/api/pharmacy';
  static String get apiAi             => '$baseUrl/api/ai';

  // ── Token key stored in secure storage ────────────────────────────────
  static const String tokenKey = 'gram_health_token';
  static const String userKey  = 'gram_health_user';
  static const String roleKey  = 'gram_health_role';
}
