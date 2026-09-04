import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';

class ConsultationModel {
  final String id;
  final String status;
  final String type; // VIDEO, AUDIO, etc
  final String reason;
  final String? symptoms;
  final String? scheduledTime;
  final String? doctorId;
  final String? patientId;
  final String? patientName;
  final String? voiceNoteUrl;

  ConsultationModel({
    required this.id,
    required this.status,
    required this.type,
    required this.reason,
    this.symptoms,
    this.scheduledTime,
    this.doctorId,
    this.patientId,
    this.patientName,
    this.voiceNoteUrl,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    final patientObj = json['patient'] as Map<String, dynamic>?;
    final patientUser = patientObj?['user'] as Map<String, dynamic>?;
    final patientName = patientUser?['name'] as String?;

    return ConsultationModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      type: json['type']?.toString() ?? 'VIDEO',
      reason: json['reason']?.toString() ?? json['notes']?.toString() ?? '',
      symptoms: json['symptoms']?.toString(),
      scheduledTime: json['scheduledTime']?.toString(),
      doctorId: json['doctorId']?.toString(),
      patientId: json['patientId']?.toString(),
      patientName: patientName,
      voiceNoteUrl: json['voiceNoteUrl']?.toString(),
    );
  }
}

class ConsultationService {
  ConsultationService._();

  /// List consultations for the logged-in user.
  static Future<List<ConsultationModel>> listConsultations({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    String url = '${AppConfig.apiConsultations}?page=$page&limit=$limit';
    if (status != null) url += '&status=$status';
    final response = await ApiClient.get(url);
    final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// List consultations for the logged-in doctor (via /api/doctors/consultations).
  static Future<List<ConsultationModel>> listDoctorConsultations({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    String url = '${AppConfig.apiDoctors}/consultations?page=$page&limit=$limit';
    if (status != null) url += '&status=$status';
    final response = await ApiClient.get(url);
    final List<dynamic> items = response['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new teleconsultation request.
  /// [type] must be one of: VIDEO, AUDIO, CHAT, OFFLINE.
  static Future<ConsultationModel> createConsultation({
    required String reason,
    String type = 'VIDEO',
    String? symptoms,
    String? scheduledTime,
    String? doctorId,
    String? voiceNoteUrl,
  }) async {
    // Map frontend fields to backend: type is required, reason goes into notes
    final notes = [
      reason,
      if (scheduledTime != null) 'Preferred time: $scheduledTime',
    ].join('\n');

    final body = <String, dynamic>{
      'type': type,
      'notes': notes,
    };
    if (symptoms != null && symptoms.isNotEmpty) body['symptoms'] = symptoms;
    if (doctorId != null) body['doctorId'] = doctorId;
    if (voiceNoteUrl != null) body['voiceNoteUrl'] = voiceNoteUrl;

    final response = await SyncService.instance.push(
      entityType: 'consultation',
      operation: 'POST',
      endpoint: AppConfig.apiConsultations,
      payload: body,
    );
    if (response['status'] == 'PENDING_SYNC') {
      return ConsultationModel(
        id: response['id'],
        status: 'PENDING_SYNC',
        type: type,
        reason: reason,
        symptoms: symptoms,
        scheduledTime: scheduledTime,
        doctorId: doctorId,
      );
    }
    return ConsultationModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Get a single consultation by ID.
  static Future<ConsultationModel> getConsultationById(String id) async {
    final response =
        await ApiClient.get('${AppConfig.apiConsultations}/$id');
    return ConsultationModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Doctor accepts a pending consultation.
  static Future<ConsultationModel> acceptConsultation(String id, {String? notes}) async {
    final body = <String, dynamic>{};
    if (notes != null) body['notes'] = notes;
    
    final response = await SyncService.instance.push(
      entityType: 'consultation_$id',
      operation: 'PATCH',
      endpoint: '${AppConfig.apiConsultations}/$id/accept',
      payload: body,
    );
    
    if (response['status'] == 'PENDING_SYNC') {
       return ConsultationModel(id: id, status: 'ACCEPTED_OFFLINE', type: 'VIDEO', reason: notes ?? '');
    }
    return ConsultationModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Doctor completes an active consultation.
  static Future<ConsultationModel> completeConsultation(String id,
      {String? notes, String? riskLevel}) async {
    final body = <String, dynamic>{};
    if (notes != null) body['notes'] = notes;
    if (riskLevel != null) body['riskLevel'] = riskLevel;

    final response = await SyncService.instance.push(
      entityType: 'consultation_$id',
      operation: 'PATCH',
      endpoint: '${AppConfig.apiConsultations}/$id/complete',
      payload: body,
    );
    
    if (response['status'] == 'PENDING_SYNC') {
       return ConsultationModel(id: id, status: 'COMPLETED_OFFLINE', type: 'VIDEO', reason: notes ?? '');
    }
    return ConsultationModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Assign a doctor to a consultation.
  static Future<ConsultationModel> assignDoctor(String consultationId, String doctorId) async {
    final response = await ApiClient.patch(
        '${AppConfig.apiConsultations}/$consultationId/assign-doctor',
        {'doctorId': doctorId});
    return ConsultationModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
