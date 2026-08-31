import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mock authentication service. Replace with real implementation.
class AuthService {
  // In a real app, this would be populated after login.
  static String? currentUserRole; // 'patient', 'doctor', 'admin'

  static bool get isLoggedIn => currentUserRole != null;
}

/// Auth guard used by GoRouter to protect routes based on role.
class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;
    final isPublicRoute = location == '/' || location == '/onboarding' || location == '/login';

    // If not logged in and trying to access a protected route, go to onboarding.
    if (!AuthService.isLoggedIn && !isPublicRoute) {
      return '/onboarding';
    }

    // If logged in and trying to access login/onboarding, redirect to their dashboard
    if (AuthService.isLoggedIn && (location == '/login' || location == '/onboarding')) {
      return _getDashboardForRole(AuthService.currentUserRole);
    }

    if (AuthService.isLoggedIn) {
      final role = AuthService.currentUserRole;
      
      // Role-based restrictions
      if (location.startsWith('/doctor') && role != 'doctor') {
        return _getDashboardForRole(role);
      }
      if (location.startsWith('/admin') && role != 'admin') {
        return _getDashboardForRole(role);
      }
      if (location.startsWith('/main') && role != 'patient') {
        return _getDashboardForRole(role);
      }
    }

    // No redirection needed.
    return null;
  }

  static String _getDashboardForRole(String? role) {
    if (role == 'admin') return '/admin/dashboard';
    if (role == 'doctor') return '/doctor/dashboard';
    return '/main/home'; // patient default
  }
}
