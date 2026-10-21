import '../config/app_config.dart';
import 'api_client.dart';

/// Admin-facing API access against the live Render backend.
///
/// Verified route table (backend/src/app.js):
///   GET /api/users             ADMIN   paginated, ?role= & ?search=
///   GET /api/patients          ADMIN   paginated
///   GET /api/doctors           many    paginated, ?specialization=
///   GET /api/consultations     ADMIN   paginated, ?status= & ?type=
///   GET /api/pharmacy/list     auth    all pharmacies (not paginated)
///   GET /api/asha-workers      ADMIN   paginated
///
/// There is **no** admin endpoint for prescriptions, appointments or
/// facilities, so those views are derived from real records instead of
/// being invented. See [AdminService.facilitiesFromDoctors] and
/// [AdminService.appointmentsFromConsultations].
class AdminUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'PATIENT',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class AdminPatient {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String? gender;
  final String? village;
  final String? district;
  final String? state;
  final DateTime? createdAt;

  const AdminPatient({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.gender,
    this.village,
    this.district,
    this.state,
    this.createdAt,
  });

  factory AdminPatient.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return AdminPatient(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: user['name']?.toString() ?? 'Unknown patient',
      phone: user['phone']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      gender: json['gender']?.toString(),
      village: json['village']?.toString(),
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get location {
    final parts = [village, district, state]
        .where((p) => p != null && p!.isNotEmpty)
        .map((p) => p!)
        .toList();
    return parts.isEmpty ? 'Location not set' : parts.join(' · ');
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class AdminDoctor {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String? specialization;
  final String? registrationNumber;
  final String? hospitalName;
  final DateTime? createdAt;

  const AdminDoctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.specialization,
    this.registrationNumber,
    this.hospitalName,
    this.createdAt,
  });

  factory AdminDoctor.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return AdminDoctor(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: user['name']?.toString() ?? 'Unknown doctor',
      phone: user['phone']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      specialization: json['specialization']?.toString(),
      registrationNumber: json['registrationNumber']?.toString(),
      hospitalName: json['hospitalName']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get displaySpecialization =>
      (specialization == null || specialization!.isEmpty) ? 'General Physician' : specialization!;

  /// Doctors who never completed onboarding have no registration number.
  bool get isOnboarded =>
      specialization != null && specialization!.isNotEmpty && registrationNumber != null && registrationNumber!.isNotEmpty;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class AdminPharmacy {
  final String id;
  final String userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int medicineCount;
  final int inStockCount;
  final String? contact;

  const AdminPharmacy({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.medicineCount,
    required this.inStockCount,
    this.contact,
  });

  factory AdminPharmacy.fromJson(Map<String, dynamic> json) {
    final inv = json['inventories'] as List<dynamic>? ?? const [];
    var total = 0;
    var inStock = 0;
    for (final item in inv) {
      if (item is Map) {
        total++;
        if (item['inStock'] == true) inStock++;
      }
    }
    return AdminPharmacy(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed pharmacy',
      address: json['address']?.toString() ?? 'Address not set',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      medicineCount: total,
      inStockCount: inStock,
      contact: json['contact']?.toString(),
    );
  }
}

class AdminAshaWorker {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String? village;
  final String? district;
  final String? state;
  final DateTime? createdAt;

  const AdminAshaWorker({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.village,
    this.district,
    this.state,
    this.createdAt,
  });

  factory AdminAshaWorker.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return AdminAshaWorker(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: user['name']?.toString() ?? 'Unknown worker',
      phone: user['phone']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      village: json['village']?.toString(),
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get location {
    final parts = [village, district, state]
        .where((p) => p != null && p!.isNotEmpty)
        .map((p) => p!)
        .toList();
    return parts.isEmpty ? 'Location not set' : parts.join(' · ');
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A practice location derived from the hospital doctors actually registered
/// against. The backend has no facilities collection, so this is the only
/// honest source of facility data.
class DerivedFacility {
  final String name;
  final int doctorCount;
  final String specialties;

  const DerivedFacility({
    required this.name,
    required this.doctorCount,
    required this.specialties,
  });
}

/// A consultation enriched with the names the API nests under `user`.
class AdminConsultation {
  final String id;
  final String status;
  final String type;
  final String? symptoms;
  final String? notes;
  final String? riskLevel;
  final String? patientName;
  final String? patientPhone;
  final String? doctorName;
  final String? doctorPhone;
  final DateTime? createdAt;
  final bool hasDoctor;

  const AdminConsultation({
    required this.id,
    required this.status,
    required this.type,
    this.symptoms,
    this.notes,
    this.riskLevel,
    this.patientName,
    this.patientPhone,
    this.doctorName,
    this.doctorPhone,
    this.createdAt,
    required this.hasDoctor,
  });

  factory AdminConsultation.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    final patientUser = patient?['user'] as Map<String, dynamic>?;
    final doctor = json['doctor'] as Map<String, dynamic>?;
    final doctorUser = doctor?['user'] as Map<String, dynamic>?;
    return AdminConsultation(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      type: json['type']?.toString() ?? 'VIDEO',
      symptoms: json['symptoms']?.toString(),
      notes: json['notes']?.toString(),
      riskLevel: json['riskLevel']?.toString(),
      patientName: patientUser?['name']?.toString() ?? 'Unassigned patient',
      patientPhone: patientUser?['phone']?.toString(),
      doctorName: doctorUser?['name']?.toString(),
      doctorPhone: doctorUser?['phone']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      hasDoctor: doctor != null,
    );
  }

  String get patientInitials {
    final n = patientName ?? '?';
    final parts = n.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Aggregated counters for the admin dashboard — every number is derived from
/// a live collection, never hardcoded.
class AdminOverview {
  final int users;
  final int patients;
  final int doctors;
  final int pharmacies;
  final int consultations;
  final int pending;
  final int active;
  final int completed;
  final int cancelled;
  final int ashaWorkers;
  final int onboardedDoctors;
  final List<AdminConsultation> recent;

  const AdminOverview({
    required this.users,
    required this.patients,
    required this.doctors,
    required this.pharmacies,
    required this.consultations,
    required this.pending,
    required this.active,
    required this.completed,
    required this.cancelled,
    required this.ashaWorkers,
    required this.onboardedDoctors,
    required this.recent,
  });
}

class AdminService {
  AdminService._();

  static List<dynamic> _dataOf(dynamic response) {
    if (response is Map && response['data'] is List) return response['data'] as List;
    if (response is List) return response;
    return const [];
  }

  static int _totalOf(dynamic response) {
    if (response is Map) {
      final meta = response['meta'];
      if (meta is Map && meta['total'] is int) return meta['total'] as int;
    }
    return 0;
  }

  // ── Users ───────────────────────────────────────────────────────────

  static Future<List<AdminUser>> getUsers({
    String? role,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    var url = '${AppConfig.apiUsers}?page=$page&limit=$limit';
    if (role != null) url += '&role=$role';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    final response = await ApiClient.get(url);
    return _dataOf(response)
        .whereType<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();
  }

  static Future<int> getUserTotal() async {
    final response = await ApiClient.get('${AppConfig.apiUsers}?page=1&limit=1');
    return _totalOf(response);
  }

  // ── Patients ────────────────────────────────────────────────────────

  static Future<List<AdminPatient>> getPatients({int page = 1, int limit = 100}) async {
    final response = await ApiClient.get('${AppConfig.apiPatients}?page=$page&limit=$limit');
    return _dataOf(response)
        .whereType<Map<String, dynamic>>()
        .map(AdminPatient.fromJson)
        .toList();
  }

  static Future<int> getPatientTotal() async {
    final response = await ApiClient.get('${AppConfig.apiPatients}?page=1&limit=1');
    return _totalOf(response);
  }

  // ── Doctors ─────────────────────────────────────────────────────────

  static Future<List<AdminDoctor>> getDoctors({int page = 1, int limit = 100}) async {
    final response = await ApiClient.get('${AppConfig.apiDoctors}?page=$page&limit=$limit');
    return _dataOf(response)
        .whereType<Map<String, dynamic>>()
        .map(AdminDoctor.fromJson)
        .toList();
  }

  static Future<int> getDoctorTotal() async {
    final response = await ApiClient.get('${AppConfig.apiDoctors}?page=1&limit=1');
    return _totalOf(response);
  }

  // ── Pharmacies ──────────────────────────────────────────────────────

  static Future<List<AdminPharmacy>> getPharmacies() async {
    final response = await ApiClient.get(AppConfig.apiPharmacyList);
    return _dataOf(response)
        .whereType<Map<String, dynamic>>()
        .map(AdminPharmacy.fromJson)
        .toList();
  }

  // ── ASHA workers ────────────────────────────────────────────────────

  static Future<List<AdminAshaWorker>> getAshaWorkers() async {
    final response = await ApiClient.get('${AppConfig.apiAshaWorkers}?page=1&limit=100');
    return _dataOf(response)
        .whereType<Map<String, dynamic>>()
        .map(AdminAshaWorker.fromJson)
        .toList();
  }

  // ── Consultations ───────────────────────────────────────────────────

  static Future<List<AdminConsultation>> getConsultations({String? status}) async {
    var url = '${AppConfig.apiConsultations}?page=1&limit=100';
    if (status != null) url += '&status=$status';
    final response = await ApiClient.get(url);
    return _dataOf(response)
        .whereType<Map<String, dynamic>>()
        .map(AdminConsultation.fromJson)
        .toList();
  }

  /// Loads every collection the dashboard needs and derives the counters.
  ///
  /// The requests run **in parallel** and each response is reused for both
  /// the list and its total. The backend is hosted on a free Render tier
  /// that sleeps between calls, so sequential requests regularly exceeded
  /// the client timeout and silently zeroed the dashboard.
  static Future<AdminOverview> getOverview() async {
    final results = await Future.wait([
      _safe(() => getUsers(limit: 100), const <AdminUser>[]),
      _safe(() => getPatients(limit: 100), const <AdminPatient>[]),
      _safe(() => getDoctors(limit: 100), const <AdminDoctor>[]),
      _safe(() => getPharmacies(), const <AdminPharmacy>[]),
      _safe(() => getConsultations(), const <AdminConsultation>[]),
      _safe(() => getAshaWorkers(), const <AdminAshaWorker>[]),
    ]);

    final users = results[0] as List<AdminUser>;
    final patients = results[1] as List<AdminPatient>;
    final doctors = results[2] as List<AdminDoctor>;
    final pharmacies = results[3] as List<AdminPharmacy>;
    final consultations = results[4] as List<AdminConsultation>;
    final asha = results[5] as List<AdminAshaWorker>;

    int countWhere(String s) => consultations.where((c) => c.status == s).length;

    return AdminOverview(
      users: users.length,
      patients: patients.length,
      doctors: doctors.length,
      pharmacies: pharmacies.length,
      consultations: consultations.length,
      pending: countWhere('PENDING'),
      active: countWhere('ACTIVE'),
      completed: countWhere('COMPLETED'),
      cancelled: countWhere('CANCELLED'),
      ashaWorkers: asha.length,
      onboardedDoctors: doctors.where((d) => d.isOnboarded).length,
      recent: consultations.take(6).toList(),
    );
  }

  /// Runs a request, degrading to [fallback] instead of failing the screen.
  static Future<T> _safe<T>(Future<T> Function() call, T fallback) async {
    try {
      return await call();
    } catch (_) {
      return fallback;
    }
  }

  /// Derives practice locations from the hospitals doctors registered against.
  static List<DerivedFacility> facilitiesFromDoctors(List<AdminDoctor> doctors) {
    final byHospital = <String, List<AdminDoctor>>{};
    for (final d in doctors) {
      final key = (d.hospitalName == null || d.hospitalName!.isEmpty)
          ? 'Practice not registered'
          : d.hospitalName!.trim();
      byHospital.putIfAbsent(key, () => []).add(d);
    }
    final out = byHospital.entries.map((e) {
      final specialties = e.value.map((d) => d.displaySpecialization).toSet().toList()..sort();
      return DerivedFacility(
        name: e.key,
        doctorCount: e.value.length,
        specialties: specialties.isEmpty ? 'General' : specialties.join(', '),
      );
    }).toList();
    out.sort((a, b) => b.doctorCount.compareTo(a.doctorCount));
    return out;
  }

  /// Groups real consultations by calendar day. The backend has no
  /// appointments collection, so this is the appointment view.
  static Map<String, List<AdminConsultation>> appointmentsFromConsultations(
      List<AdminConsultation> consultations) {
    final grouped = <String, List<AdminConsultation>>{};
    for (final c in consultations) {
      final d = c.createdAt;
      final key = d == null
          ? 'Unscheduled'
          : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(c);
    }
    final sorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sorted) k: grouped[k]!};
  }
}
