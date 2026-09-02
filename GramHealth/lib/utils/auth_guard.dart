import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

export '../services/auth_service.dart' show AuthService;

/// Auth guard used by GoRouter to protect routes based on role.
///
/// NOTE: GoRouter's redirect callback is synchronous, so we cache the role
/// in a simple in-memory variable that is populated on login and cleared on
/// logout. [AuthGuard.init()] should be called once at app startup to
/// populate it from secure storage.
class AuthGuard {
  AuthGuard._();

  /// In-memory cache of the current user role (populated from secure storage).
  static String? _cachedRole;

  /// Call once at app startup (before [runApp]) to restore session.
  static Future<void> init() async {
    final loggedIn = await AuthService.isLoggedIn;
    if (loggedIn) {
      _cachedRole = await AuthService.getCurrentRole();
    } else {
      _cachedRole = null;
      await AuthService.logout();
    }
  }

  /// Called after a successful login to sync the in-memory cache.
  static void onLogin(String role) {
    _cachedRole = role.toLowerCase();
  }

  /// Called on logout to clear the in-memory cache.
  static void onLogout() {
    _cachedRole = null;
  }

  static bool get isLoggedIn => _cachedRole != null;
  static String? get currentUserRole => _cachedRole;

  /// GoRouter redirect callback (synchronous).
  static String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;
    final publicRoutes = ['/', '/onboarding', '/login'];
    final isPublic = publicRoutes.contains(location);

    if (!isLoggedIn && !isPublic) {
      return '/onboarding';
    }

    if (isLoggedIn && (location == '/login' || location == '/onboarding')) {
      return _dashboardFor(_cachedRole);
    }

    if (isLoggedIn) {
      final role = _cachedRole;
      if (location.startsWith('/doctor') && role != 'doctor') {
        return _dashboardFor(role);
      }
      if (location.startsWith('/admin') && role != 'admin') {
        return _dashboardFor(role);
      }
      if (location.startsWith('/main') && role != 'patient' && role != 'asha') {
        return _dashboardFor(role);
      }
    }

    return null;
  }

  static String _dashboardFor(String? role) {
    if (role == 'admin') return '/admin/dashboard';
    if (role == 'doctor') return '/doctor/dashboard';
    return '/main/home';
  }
}
