enum LocalBackendMode {
  adbReverse, // http://127.0.0.1:3000 (standard local Android via 'adb reverse tcp:3000 tcp:3000')
  lan,        // http://192.168.0.102:3000 (optional Wi-Fi LAN development mode)
}

/// Centralised application configuration.
///
/// Standardised for production deployment on Render and local development:
/// - In production: Flutter connects to Node.js backend on Render (https://gramhealthapp.onrender.com)
/// - In local dev: Flutter connects to local Node.js backend via ADB reverse (http://127.0.0.1:3000) or LAN
class AppConfig {
  AppConfig._();

  // ── Live Backend URL (Render Production Deployment) ───────────────────
  static const String liveBackendUrl = 'https://gramhealthapp.onrender.com';

  // ── Local Development URLs ─────────────────────────────────────────────
  static const String adbReverseBackendUrl = 'http://127.0.0.1:3000';
  static const String defaultLanBackendUrl = 'http://192.168.0.102:3000';

  /// Active local backend mode. Defaults to adbReverse for standard USB workflow.
  static LocalBackendMode localBackendMode = LocalBackendMode.adbReverse;

  /// Custom LAN backend URL if host IP differs.
  static String lanBackendUrl = defaultLanBackendUrl;

  /// When true, forces connection to live Render deployment.
  static bool useProduction = true;

  /// Returns the active local backend URL based on mode.
  static String get localBackendUrl {
    switch (localBackendMode) {
      case LocalBackendMode.lan:
        return lanBackendUrl;
      case LocalBackendMode.adbReverse:
      default:
        return adbReverseBackendUrl;
    }
  }

  // ── Base URL ──────────────────────────────────────────────────────────
  static String get baseUrl => useProduction ? liveBackendUrl : localBackendUrl;

  // ── API Routes (All routed strictly through Node.js backend) ───────────
  static String get apiHealth         => '$baseUrl/api/health';
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
