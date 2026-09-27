import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../data/local_database.dart';

/// Matches the backend Prescription model (+ joined doctor/patient info).
class PrescriptionModel {
  final String id;
  final String doctorName;
  final String specialization;
  final String patientName;
  final String date;
  final String diagnosis;
  final List<Map<String, dynamic>> medicines;

  PrescriptionModel({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.patientName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final doctorObj = json['doctor'] as Map<String, dynamic>?;
    final doctorUserObj = doctorObj?['user'] as Map<String, dynamic>?;
    
    final patientObj = json['patient'] as Map<String, dynamic>?;
    final patientUserObj = patientObj?['user'] as Map<String, dynamic>?;

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
      patientName: patientUserObj?['name']?.toString() ?? 'Unknown Patient',
      date: _formatDate(json['createdAt']?.toString()),
      diagnosis: json['diagnosis']?.toString() ?? '—',
      medicines: medicines,
    );
  }

  /// Convert back to Map for the existing PrescriptionDetailScreen widget.
  Map<String, dynamic> toDisplayMap() => {
        'id': id,
        'doctorName': doctorName,
        'patientName': patientName,
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
    if (ConnectivityService.instance.currentStatus != NetworkStatus.online) {
      final cached = await LocalDatabase.instance.getAllCachedData('cached_prescriptions');
      return cached.map((e) => PrescriptionModel.fromJson(e)).toList();
    }
    
    final url = '${AppConfig.apiPrescriptions}/me?page=$page&limit=$limit';
    try {
      final response = await ApiClient.get(url);
      final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
      
      // Cache the response locally
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          await LocalDatabase.instance.cacheData('cached_prescriptions', item['id'].toString(), item);
        }
      }

      final apiPrescriptions = items
          .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
          
      final cached = await LocalDatabase.instance.getAllCachedData('cached_prescriptions');
      final drafts = cached.where((e) => e['diagnosis'] == 'Sync Pending...').map((e) => PrescriptionModel.fromJson(e));
      
      return [...drafts, ...apiPrescriptions];
    } catch (e) {
      // Fallback to offline cache
      final cached = await LocalDatabase.instance.getAllCachedData('cached_prescriptions');
      return cached
          .map((e) => PrescriptionModel.fromJson(e))
          .toList();
    }
  }

  /// List prescriptions written by the logged-in doctor.
  static Future<List<PrescriptionModel>> getDoctorPrescriptions({
    int page = 1,
    int limit = 20,
  }) async {
    if (ConnectivityService.instance.currentStatus != NetworkStatus.online) {
      final cached = await LocalDatabase.instance.getAllCachedData('cached_prescriptions');
      return cached.map((e) => PrescriptionModel.fromJson(e)).toList();
    }

    final url = '${AppConfig.apiDoctors}/prescriptions?page=$page&limit=$limit';
    try {
      final response = await ApiClient.get(url);
      final List<dynamic> items = response['data'] as List<dynamic>? ?? [];

      // Cache the response locally
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          await LocalDatabase.instance.cacheData('cached_prescriptions', item['id'].toString(), item);
        }
      }

      final apiPrescriptions = items
          .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final cached = await LocalDatabase.instance.getAllCachedData('cached_prescriptions');
      final drafts = cached.where((e) => e['diagnosis'] == 'Sync Pending...').map((e) => PrescriptionModel.fromJson(e));
      
      return [...drafts, ...apiPrescriptions];
    } catch (e) {
      // Fallback to offline cache
      final cached = await LocalDatabase.instance.getAllCachedData('cached_prescriptions');
      return cached
          .map((e) => PrescriptionModel.fromJson(e))
          .toList();
    }
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

    final response = await SyncService.instance.push(
      entityType: 'prescription',
      operation: 'POST',
      endpoint: AppConfig.apiPrescriptions,
      payload: body,
    );

    if (response['status'] == 'PENDING_SYNC') {
      final draftJson = {
        'id': response['id'],
        'doctor': {
          'user': {'name': 'Local Draft'},
          'specialization': '-',
        },
        'patient': {
          'user': {'name': 'Local Draft'},
        },
        'createdAt': DateTime.now().toIso8601String(),
        'diagnosis': 'Sync Pending...',
        'medicines': medicines,
      };
      
      await LocalDatabase.instance.cacheData('cached_prescriptions', draftJson['id'] as String, draftJson);

      return PrescriptionModel.fromJson(draftJson);
    }

    return PrescriptionModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
