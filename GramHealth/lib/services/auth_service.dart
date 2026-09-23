import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_client.dart';

/// Real authentication service that talks to the GramHealth backend.
///
/// Stores the JWT token in [SharedPreferences] and cached user data
/// (role, name, id) in the same store so they survive app restarts.
class AuthService {
  AuthService._();

  // ── Token & User Helpers ──────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConfig.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  static Future<bool> get isLoggedIn async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
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

  /// Authenticates with the backend via POST /api/auth/login.
  /// Returns the user map on success.
  /// Throws [ApiException] on failure.
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    print('[AUTH]');
    print('POST ${AppConfig.apiAuth}/login');
    print('Base URL: ${AppConfig.baseUrl}');

    try {
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

      print('Network reachable: true');
      print('Response status: 200');
      print('Token received: ${token.isNotEmpty}');

      return user;
    } on SocketException catch (e) {
      print('Network reachable: false');
      print('Error: SocketException: $e');
      print('Token received: false');
      throw const ApiException(
        message: 'Backend unreachable. Please verify network connection or ADB reverse (tcp:3000 tcp:3000).',
        statusCode: 503,
      );
    } on TimeoutException catch (e) {
      print('Network reachable: false');
      print('Error: TimeoutException: $e');
      print('Token received: false');
      throw const ApiException(
        message: 'Connection timed out. Backend is not responding.',
        statusCode: 504,
      );
    } catch (e) {
      if (e is ApiException) {
        print('Network reachable: true');
        print('Response status: ${e.statusCode}');
        print('Token received: false');
        rethrow;
      }
      final str = e.toString().toLowerCase();
      final bool isNet = str.contains('socketexception') ||
          str.contains('connection refused') ||
          str.contains('failed to fetch') ||
          str.contains('clientexception');
      print('Network reachable: ${!isNet}');
      print('Token received: false');
      print('Error: $e');
      if (isNet) {
        throw const ApiException(
          message: 'Backend unreachable. Please verify network connection or ADB reverse.',
          statusCode: 503,
        );
      }
      rethrow;
    }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.userKey);
  }
}
