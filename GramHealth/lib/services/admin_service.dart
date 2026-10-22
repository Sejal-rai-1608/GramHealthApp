import 'api_client.dart';
import '../config/app_config.dart';

class AdminService {
  AdminService._();

  static Future<Map<String, dynamic>> _get(String url) async {
    try {
      final response = await ApiClient.get(url);
      if (response is Map && response['success'] == true) {
        return {
          'items': response['data'] ?? [],
          'meta': response['meta'] ?? {},
        };
      }
      return {'items': [], 'meta': {}};
    } catch (e) {
      return {'items': [], 'meta': {}};
    }
  }

  // System Overview / Dashboard Stats - aggregates from multiple endpoints
  static Future<Map<String, dynamic>> getSystemStats() async {
    final results = await Future.wait([
      _get('${AppConfig.apiUsers}?limit=1').catchError((_) => {'items': [], 'meta': {}}),
      _get('${AppConfig.apiDoctors}?limit=1').catchError((_) => {'items': [], 'meta': {}}),
      _get('${AppConfig.apiPatients}?limit=1').catchError((_) => {'items': [], 'meta': {}}),
      _get('${AppConfig.apiConsultations}?limit=1').catchError((_) => {'items': [], 'meta': {}}),
      _get('${AppConfig.apiPharmacy}/list?limit=1').catchError((_) => {'items': [], 'meta': {}}),
      _get('${AppConfig.apiFacilities}?limit=1').catchError((_) => {'items': [], 'meta': {}}),
    ]);

    return {
      'totalUsers': results[0]['meta']['total'] ?? results[0]['items'].length,
      'totalDoctors': results[1]['meta']['total'] ?? results[1]['items'].length,
      'totalPatients': results[2]['meta']['total'] ?? results[2]['items'].length,
      'totalConsultations': results[3]['meta']['total'] ?? results[3]['items'].length,
      'totalPharmacies': results[4]['meta']['total'] ?? results[4]['items'].length,
      'totalFacilities': results[5]['meta']['total'] ?? results[5]['items'].length,
    };
  }

  // Doctors
  static Future<List<Map<String, dynamic>>> getDoctors({String? search, String? status, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiDoctors}?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (status != null && status.isNotEmpty) url += '&specialization=$status';
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Patients
  static Future<List<Map<String, dynamic>>> getPatients({String? search, String? status, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiPatients}?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Facilities
  static Future<List<Map<String, dynamic>>> getFacilities({String? search, String? type, bool? isActive, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiFacilities}?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (type != null && type.isNotEmpty) url += '&type=$type';
    if (isActive != null) url += '&isActive=${isActive.toString()}';
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Pharmacies
  static Future<List<Map<String, dynamic>>> getPharmacies({String? search, String? status, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiPharmacy}/list?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Appointments (consultations with status filtering)
  static Future<List<Map<String, dynamic>>> getAppointments({String? search, String? status, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiConsultations}?page=$page&limit=$limit';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    if (search != null && search.isNotEmpty) {
      // Search by patient or doctor name - would need backend support
    }
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Consultations
  static Future<List<Map<String, dynamic>>> getConsultations({String? search, String? status, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiConsultations}?page=$page&limit=$limit';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    if (search != null && search.isNotEmpty) {
      // Search would need backend support
    }
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Prescriptions
  static Future<List<Map<String, dynamic>>> getPrescriptions({String? search, String? patientId, String? doctorId, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiPrescriptions}?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (patientId != null && patientId.isNotEmpty) url += '&patientId=$patientId';
    if (doctorId != null && doctorId.isNotEmpty) url += '&doctorId=$doctorId';
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Users
  static Future<List<Map<String, dynamic>>> getUsers({String? search, String? role, int page = 1, int limit = 20}) async {
    var url = '${AppConfig.apiUsers}?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (role != null && role.isNotEmpty) url += '&role=$role';
    final result = await _get(url);
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  // Reports
  static Future<Map<String, dynamic>> getReportOverview() async {
    final response = await ApiClient.get('${AppConfig.apiAdminReports}/overview');
    return response['data'] ?? {};
  }

  static Future<List<Map<String, dynamic>>> getConsultationTrends({int days = 30}) async {
    final response = await ApiClient.get('${AppConfig.apiAdminReports}/consultations?days=$days');
    return (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getDoctorWorkload() async {
    final response = await ApiClient.get('${AppConfig.apiAdminReports}/doctors');
    return (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getPharmacyCoverage() async {
    final response = await ApiClient.get('${AppConfig.apiAdminReports}/pharmacies');
    return (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getUserGrowth({int days = 30}) async {
    final response = await ApiClient.get('${AppConfig.apiAdminReports}/user-growth?days=$days');
    return (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // Reports - placeholder (deprecated)
  static Future<List<Map<String, dynamic>>> getAvailableReports() async {
    return [];
  }
}