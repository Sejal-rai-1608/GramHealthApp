import '../config/app_config.dart';
import '../services/api_client.dart';

/// Matches the backend Prescription model (+ joined doctor/patient info).
class PrescriptionModel {
  final String id;
  final String doctorName;
  final String specialization;
  final String date;
  final String diagnosis;
  final List<Map<String, dynamic>> medicines;

  PrescriptionModel({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.date,
    required this.diagnosis,
    required this.medicines,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final doctorObj = json['doctor'] as Map<String, dynamic>?;
    final doctorUserObj = doctorObj?['user'] as Map<String, dynamic>?;

    final rawMeds = json['medicines'] as List<dynamic>? ?? [];
    final medicines = rawMeds.map((m) {
      if (m is Map<String, dynamic>) return m;
      return <String, dynamic>{'name': m.toString()};
    }).toList();

    return PrescriptionModel(
      id: json['id']?.toString() ?? '',
      doctorName: doctorUserObj?['name']?.toString() ?? 'Unknown Doctor',
      specialization:
          doctorObj?['specialization']?.toString() ?? 'General Physician',
      date: _formatDate(json['createdAt']?.toString()),
      diagnosis: json['diagnosis']?.toString() ?? '—',
      medicines: medicines,
    );
  }

  /// Convert back to Map for the existing PrescriptionDetailScreen widget.
  Map<String, dynamic> toDisplayMap() => {
        'id': id,
        'doctorName': doctorName,
        'specialization': specialization,
        'date': date,
        'diagnosis': diagnosis,
        'medicines': medicines,
      };

  static String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class PrescriptionService {
  PrescriptionService._();

  /// List prescriptions for the logged-in patient.
  static Future<List<PrescriptionModel>> getPrescriptions({
    int page = 1,
    int limit = 20,
  }) async {
    final url = '${AppConfig.apiPrescriptions}/me?page=$page&limit=$limit';
    final response = await ApiClient.get(url);
    final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// List prescriptions written by the logged-in doctor.
  static Future<List<PrescriptionModel>> getDoctorPrescriptions({
    int page = 1,
    int limit = 20,
  }) async {
    final url = '${AppConfig.apiDoctors}/prescriptions?page=$page&limit=$limit';
    final response = await ApiClient.get(url);
    final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Doctor creates a prescription for a consultation.
  static Future<PrescriptionModel> createPrescription({
    required String consultationId,
    required List<Map<String, dynamic>> medicines,
    String? instructions,
  }) async {
    final body = <String, dynamic>{
      'consultationId': consultationId,
      'medicines': medicines,
    };
    if (instructions != null) body['instructions'] = instructions;
    final response = await ApiClient.post(AppConfig.apiPrescriptions, body);
    return PrescriptionModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
