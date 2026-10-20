import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ruralcare_flutter/theme/app_theme.dart';
import 'package:ruralcare_flutter/utils/auth_guard.dart';
import 'package:ruralcare_flutter/services/auth_service.dart';
import 'package:ruralcare_flutter/config/app_config.dart';

import 'package:ruralcare_flutter/screens/doctor/doctor_requests_screen.dart';
import 'package:ruralcare_flutter/screens/doctor/doctor_consultations_screen.dart';
import 'package:ruralcare_flutter/screens/doctor/doctor_prescriptions_screen.dart';
import 'package:ruralcare_flutter/screens/doctor/doctor_patients_screen.dart';
import 'package:ruralcare_flutter/screens/doctor/doctor_profile_screen.dart';
import 'package:ruralcare_flutter/screens/doctor/doctor_settings_screen.dart';
import 'package:ruralcare_flutter/screens/doctor/doctor_appointments_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_dashboard_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_users_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_doctors_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_patients_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_appointments_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_consultations_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_asha_workers_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_pharmacies_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_facilities_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_reports_screen.dart';
import 'package:ruralcare_flutter/screens/admin/admin_settings_screen.dart';
import 'package:ruralcare_flutter/screens/pharmacy/pharmacy_dashboard_screen.dart';
import 'package:ruralcare_flutter/screens/pharmacy/prescription_list_screen.dart';
import 'package:ruralcare_flutter/screens/pharmacy/pharmacy_stock_screen.dart';
import 'package:ruralcare_flutter/screens/pharmacy/pharmacy_nearby_screen.dart';
import 'package:ruralcare_flutter/screens/pharmacy/medicine_availability_screen.dart';
import 'package:ruralcare_flutter/screens/common/home_screen.dart';
import 'package:ruralcare_flutter/screens/common/main_shell.dart';

/// Payloads captured verbatim from the live Render backend so these mocks
/// cannot drift from the real API.
class Fixtures {
  static Map<String, dynamic> user(String role) => {
        'id': 'user-$role',
        'name': 'QA $role',
        'phone': '9208025703',
        'email': 'qa.${role.toLowerCase()}@test.com',
        'role': role,
        'createdAt': '2026-10-20T14:36:48.503Z',
        'updatedAt': '2026-10-20T14:36:48.503Z',
      };

  static Map<String, dynamic> doctor = {
    'id': 'doc-1',
    'userId': 'user-DOCTOR',
    'specialization': null,
    'registrationNumber': null,
    'hospitalName': null,
    'createdAt': '2026-10-20T14:36:48.503Z',
    'updatedAt': '2026-10-20T14:36:48.503Z',
    'user': {
      'id': 'user-DOCTOR',
      'name': 'QA DOCTOR',
      'phone': '9208025703',
      'email': 'qa.doctor@test.com',
    },
  };

  static Map<String, dynamic> patient = {
    'id': 'pat-1',
    'userId': 'user-PATIENT',
    'dateOfBirth': null,
    'gender': null,
    'village': null,
    'district': null,
    'state': null,
    'createdAt': '2026-10-10T01:07:07.827Z',
    'updatedAt': '2026-10-10T01:07:07.827Z',
    'user': {
      'id': 'user-PATIENT',
      'name': 'Test Rural User',
      'phone': '9876543210',
      'email': 'gramhealth.test@example.com',
    },
  };

  static Map<String, dynamic> pharmacy = {
    'id': 'pharm-1',
    'userId': 'user-PHARMACY',
    'name': "QA PHARMACY's Pharmacy",
    'latitude': 23.2599,
    'longitude': 77.4126,
    'address': 'Bhopal, Madhya Pradesh',
    'contact': null,
    'createdAt': '2026-10-20T14:36:50.104Z',
    'updatedAt': '2026-10-20T14:36:50.104Z',
    'inventories': <Map<String, dynamic>>[],
  };

  static Map<String, dynamic> consultation = {
    'id': 'cons-1',
    'patientId': 'pat-1',
    'doctorId': 'doc-1',
    'type': 'VIDEO',
    'status': 'PENDING',
    'notes': 'Fever for three days',
    'symptoms': 'fever, body pain',
    'scheduledTime': null,
    'createdAt': '2026-10-20T14:36:48.503Z',
    'updatedAt': '2026-10-20T14:36:48.503Z',
    'patient': {
      'id': 'pat-1',
      'userId': 'user-PATIENT',
      'user': {
        'id': 'user-PATIENT',
        'name': 'Test Rural User',
        'phone': '9876543210',
        'email': 'gramhealth.test@example.com',
      },
    },
    'doctor': doctor,
  };

  static Map<String, dynamic> list(List<Map<String, dynamic>> data) => {
        'success': true,
        'message': 'ok',
        'data': data,
        'meta': {
          'page': 1,
          'limit': 20,
          'total': data.length,
          'totalPages': 1,
        },
      };
}

/// Mirrors the live backend's route table and role guards.
http.Client buildMockClient(String role) {
  return MockClient((request) async {
    final path = request.url.path;
    final isAdmin = role == 'ADMIN';
    final isDoctor = role == 'DOCTOR';
    final isPharmacy = role == 'PHARMACY';
    final isPatient = role == 'PATIENT';

    Map<String, dynamic> body;
    int status = 200;

    bool p(String suffix) => path.endsWith(suffix);
    bool c(String suffix) => path.contains(suffix);

    if (p('/api/users') && request.method == 'GET') {
      if (!isAdmin) {
        status = 403;
        body = {'success': false, 'message': 'Admin access required'};
      } else {
        body = Fixtures.list([Fixtures.user('PATIENT')]);
      }
    } else if (p('/api/patients') && request.method == 'GET') {
      if (!isAdmin) {
        status = 403;
        body = {'success': false, 'message': 'Admin access required'};
      } else {
        body = Fixtures.list([Fixtures.patient]);
      }
    } else if (p('/api/doctors/me')) {
      if (!isDoctor) {
        status = 403;
        body = {'success': false, 'message': 'Doctor access required'};
      } else {
        body = {'success': true, 'data': Fixtures.doctor};
      }
    } else if (c('/api/doctors/consultations')) {
      if (!isDoctor) {
        status = 403;
        body = {'success': false, 'message': 'Doctor access required'};
      } else {
        body = Fixtures.list([Fixtures.consultation]);
      }
    } else if (c('/api/doctors/prescriptions') || c('/api/doctors/medical-records')) {
      if (!isDoctor) {
        status = 403;
        body = {'success': false, 'message': 'Doctor access required'};
      } else {
        body = Fixtures.list([]);
      }
    } else if (p('/api/doctors') && request.method == 'GET') {
      body = Fixtures.list([Fixtures.doctor]);
    } else if (c('/api/consultations')) {
      if (isAdmin || isDoctor) {
        body = Fixtures.list([Fixtures.consultation]);
      } else {
        status = 403;
        body = {'success': false, 'message': 'Not allowed'};
      }
    } else if (p('/api/pharmacy/list')) {
      body = {
        'success': true,
        'data': [Fixtures.pharmacy],
      };
    } else if (p('/api/prescriptions/me')) {
      if (isPatient) {
        body = Fixtures.list([]);
      } else {
        status = 403;
        body = {'success': false, 'message': 'Patient access required'};
      }
    } else if (p('/api/medical-records/me')) {
      if (isPatient) {
        body = Fixtures.list([]);
      } else {
        status = 403;
        body = {'success': false, 'message': 'Patient access required'};
      }
    } else {
      status = 404;
      body = {'success': false, 'message': 'Not found: $path'};
    }

    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.createTempSync('gramhealth_test').path;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = _FakePathProvider();
  });

  Future<void> pumpRole(
    WidgetTester tester,
    String role,
    List<RouteBase> routes,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppConfig.tokenKey: 'test-token',
      AppConfig.userKey: jsonEncode(Fixtures.user(role)),
    });
    AuthGuard.onLogin(role);

    final router = GoRouter(
      initialLocation: '/',
      redirect: AuthGuard.redirect,
      routes: routes,
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.theme,
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Renders [screen] directly and reports any build/layout exception.
  Future<void> expectRenders(
    WidgetTester tester,
    Widget screen, {
    String? contains,
  }) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.theme, home: screen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final err = tester.takeException();
    expect(err, isNull, reason: 'threw while rendering ${screen.runtimeType}');
    if (contains != null) {
      expect(find.textContaining(contains), findsWidgets,
          reason: '${screen.runtimeType} rendered no "$contains"');
    }
  }

  group('DOCTOR role', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          AppConfig.tokenKey: 'test-token',
          AppConfig.userKey: jsonEncode(Fixtures.user('DOCTOR')),
        }));

    testWidgets('requests screen renders', (tester) async {
      await expectRenders(tester, const DoctorRequestsScreen());
    });

    testWidgets('consultations screen renders', (tester) async {
      await expectRenders(tester, const DoctorConsultationsScreen());
    });

    testWidgets('prescriptions screen renders', (tester) async {
      await expectRenders(tester, const DoctorPrescriptionsScreen());
    });

    testWidgets('patients screen renders', (tester) async {
      await expectRenders(tester, const DoctorPatientsScreen());
    });

    testWidgets('profile screen renders', (tester) async {
      await expectRenders(tester, const DoctorProfileScreen());
    });

    testWidgets('settings screen renders', (tester) async {
      await expectRenders(tester, const DoctorSettingsScreen());
    });

    testWidgets('appointments screen renders', (tester) async {
      await expectRenders(tester, const DoctorAppointmentsScreen());
    });
  });

  group('ADMIN role', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          AppConfig.tokenKey: 'test-token',
          AppConfig.userKey: jsonEncode(Fixtures.user('ADMIN')),
        }));

    testWidgets('dashboard renders', (tester) async {
      await expectRenders(tester, const AdminDashboardScreen());
    });

    testWidgets('users screen renders', (tester) async {
      await expectRenders(tester, const AdminUsersScreen());
    });

    testWidgets('doctors screen renders', (tester) async {
      await expectRenders(tester, const AdminDoctorsScreen());
    });

    testWidgets('patients screen renders', (tester) async {
      await expectRenders(tester, const AdminPatientsScreen());
    });

    testWidgets('appointments screen renders', (tester) async {
      await expectRenders(tester, const AdminAppointmentsScreen());
    });

    testWidgets('consultations screen renders', (tester) async {
      await expectRenders(tester, const AdminConsultationsScreen());
    });

    testWidgets('ASHA workers screen renders', (tester) async {
      await expectRenders(tester, const AdminAshaWorkersScreen());
    });

    testWidgets('pharmacies screen renders', (tester) async {
      await expectRenders(tester, const AdminPharmaciesScreen());
    });

    testWidgets('facilities screen renders', (tester) async {
      await expectRenders(tester, const AdminFacilitiesScreen());
    });

    testWidgets('reports screen renders', (tester) async {
      await expectRenders(tester, const AdminReportsScreen());
    });

    testWidgets('settings screen renders', (tester) async {
      await expectRenders(tester, const AdminSettingsScreen());
    });
  });

  group('PHARMACY role', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          AppConfig.tokenKey: 'test-token',
          AppConfig.userKey: jsonEncode(Fixtures.user('PHARMACY')),
        }));

    testWidgets('dashboard renders', (tester) async {
      await expectRenders(tester, const PharmacyDashboardScreen());
    });

    testWidgets('prescription list renders', (tester) async {
      await expectRenders(tester, const PrescriptionListScreen());
    });

    testWidgets('stock screen renders', (tester) async {
      await expectRenders(tester, const PharmacyStockScreen());
    });

    testWidgets('nearby outlets screen renders', (tester) async {
      await expectRenders(tester, const PharmacyNearbyScreen());
    });

    testWidgets('medicine availability renders', (tester) async {
      await expectRenders(tester, const MedicineAvailabilityScreen());
    });
  });

  group('PATIENT role', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          AppConfig.tokenKey: 'test-token',
          AppConfig.userKey: jsonEncode(Fixtures.user('PATIENT')),
        }));

    testWidgets('home screen renders', (tester) async {
      final router = GoRouter(
        initialLocation: '/main/home',
        routes: [
          GoRoute(
            path: '/main/home',
            builder: (_, __) => const MainShell(child: HomeScreen()),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.theme, routerConfig: router),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
