import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'api_client.dart';

/// Real authentication service that talks to the GramHealth backend.
///
/// Stores the JWT token in [FlutterSecureStorage] and cached user data
/// (role, name, id) in the same store so they survive app restarts.
class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Token helpers ─────────────────────────────────────────────────────────

  static Future<String?> getToken() => _storage.read(key: AppConfig.tokenKey);

  static Future<void> _saveToken(String token) =>
      _storage.write(key: AppConfig.tokenKey, value: token);

  static Future<void> _saveUser(Map<String, dynamic> user) =>
      _storage.write(key: AppConfig.userKey, value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: AppConfig.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  static Future<bool> get isLoggedIn async {
    final token = await getToken();
    if (token == null || token.isEmpty || token.startsWith('mock-')) {
      return false;
    }
    return true;
  }

  /// Returns lowercase role string: 'patient' | 'doctor' | 'admin' | 'asha'
  static Future<String?> getCurrentRole() async {
    final logged = await isLoggedIn;
    if (!logged) return null;
    final user = await getUser();
    final role = user?['role'] as String?;
    return role?.toLowerCase();
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Authenticates with the backend.
  /// Returns the user map on success.
  /// Throws [ApiException] on failure.
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await ApiClient.post(
      '${AppConfig.apiAuth}/login',
      {'email': email, 'password': password},
      auth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;

    await _saveToken(token);
    await _saveUser(user);

    return user;
  }

  // ── Register ──────────────────────────────────────────────────────────────

  /// Registers a new user with the backend.
  /// Returns the created user map on success.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await ApiClient.post(
      '${AppConfig.apiAuth}/register',
      {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.toUpperCase(),
      },
      auth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    return data;
  }

  // ── Update cached user ────────────────────────────────────────────────────

  /// Persists an updated user map back to secure storage.
  /// Used after profile edits to keep the cached data in sync.
  static Future<void> updateUser(Map<String, dynamic> updated) =>
      _saveUser(updated);

  // ── Logout ────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }
}
