import '../config/app_config.dart';
import '../services/api_client.dart';

/// Mirrors the backend MedicalRecord model (+ joined doctor name).
class MedicalRecordModel {
  final String id;
  final String date;
  final String doctor;
  final String illness;
  final String diagnosis;
  final String prescription;

  MedicalRecordModel({
    required this.id,
    required this.date,
    required this.doctor,
    required this.illness,
    required this.diagnosis,
    required this.prescription,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    // Try to get doctor name from joined doctor.user.name
    final doctorObj = json['doctor'] as Map<String, dynamic>?;
    final doctorUserObj = doctorObj?['user'] as Map<String, dynamic>?;
    final doctorName =
        doctorUserObj?['name']?.toString() ?? 'Unknown Doctor';

    return MedicalRecordModel(
      id: json['id']?.toString() ?? '',
      date: _formatDate(json['createdAt']?.toString()),
      doctor: doctorName,
      illness: json['title']?.toString() ?? json['illness']?.toString() ?? '—',
      diagnosis: json['diagnosis']?.toString() ?? '—',
      prescription: json['notes']?.toString() ?? '—',
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class MedicalRecordService {
  MedicalRecordService._();

  /// Returns the logged-in patient's health records.
  static Future<List<MedicalRecordModel>> getRecords({
    int page = 1,
    int limit = 20,
  }) async {
    final url = '${AppConfig.apiMedicalRecords}/me?page=$page&limit=$limit';
    final response = await ApiClient.get(url);
    final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => MedicalRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
