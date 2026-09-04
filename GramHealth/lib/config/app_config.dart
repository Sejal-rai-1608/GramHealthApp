import 'package:flutter/foundation.dart';

/// Centralised application configuration.
///
/// Automatically resolves the correct backend URL:
///   - Web / Desktop / iOS Simulator : 'http://localhost:5000'
///   - Android Emulator             : 'http://10.0.2.2:5000'
class AppConfig {
  AppConfig._();

  // ── Base URL ─────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://gramhealthapp.onrender.com';
    }
    return 'http://localhost:5000';
  }

  // ── API Routes ───────────────────────────────────────────────────────────
  static String get apiAuth           => '$baseUrl/api/auth';
  static String get apiDoctors        => '$baseUrl/api/doctors';
  static String get apiPatients       => '$baseUrl/api/patients';
  static String get apiConsultations  => '$baseUrl/api/consultations';
  static String get apiMedicalRecords => '$baseUrl/api/medical-records';
  static String get apiPrescriptions  => '$baseUrl/api/prescriptions';
  static String get apiUsers          => '$baseUrl/api/users';

  // ── Token key stored in secure storage ───────────────────────────────────
  static const String tokenKey = 'gram_health_token';
  static const String userKey  = 'gram_health_user';
  static const String roleKey  = 'gram_health_role';
}
