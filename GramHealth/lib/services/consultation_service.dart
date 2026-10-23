import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../data/local_database.dart';
class ConsultationModel {
  final String id;
  final String status;
  final String type; // VIDEO, AUDIO, etc
  final String reason;
  final String? symptoms;
  final String? notes;
  final String? scheduledAt;
  final String? scheduledTime;
  final String? doctorId;
  final String? patientId;
  final String? doctorName;
  final String? doctorPhone;
  final String? patientName;
  final String? patientPhone;
  final String? voiceNoteUrl;

  ConsultationModel({
    required this.id,
    required this.status,
    required this.type,
    required this.reason,
    this.symptoms,
    this.notes,
    this.scheduledAt,
    this.scheduledTime,
    this.doctorId,
    this.patientId,
    this.doctorName,
    this.doctorPhone,
    this.patientName,
    this.patientPhone,
    this.voiceNoteUrl,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    final patientObj = json['patient'] as Map<String, dynamic>?;
    final patientUser = patientObj?['user'] as Map<String, dynamic>?;
    final doctorObj = json['doctor'] as Map<String, dynamic>?;
    final doctorUser = doctorObj?['user'] as Map<String, dynamic>?;
    final notes = json['notes']?.toString();
    final scheduledAt = json['scheduledAt']?.toString();

    return ConsultationModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      type: json['type']?.toString() ?? 'VIDEO',
      reason: _reasonFromJson(json['reason']?.toString(), notes),
      symptoms: json['symptoms']?.toString(),
      notes: notes,
      scheduledAt: scheduledAt,
      scheduledTime: _scheduleLabel(scheduledAt) ??
          _scheduleLabelFromNotes(notes) ??
          _preferredTimeFromNotes(notes),
      doctorId: json['doctorId']?.toString(),
      patientId: json['patientId']?.toString(),
      doctorName: doctorUser?['name']?.toString(),
      doctorPhone: doctorUser?['phone']?.toString(),
      patientName: patientUser?['name']?.toString(),
      patientPhone: patientUser?['phone']?.toString(),
      voiceNoteUrl: json['voiceNoteUrl']?.toString(),
    );
  }

  static String _reasonFromJson(String? reason, String? notes) {
    if (reason != null && reason.trim().isNotEmpty) return reason.trim();
    if (notes == null || notes.trim().isEmpty) return '';

    final firstLine = notes.split('\n').first.trim();
    return firstLine.replaceFirst(RegExp(r'^Reason:\s*', caseSensitive: false), '').trim();
  }

  static String? _preferredTimeFromNotes(String? notes) {
    if (notes == null) return null;
    for (final line in notes.split('\n')) {
      if (line.toLowerCase().startsWith('preferred time:')) {
        return line.substring('Preferred time:'.length).trim();
      }
    }
    return null;
  }

  static String? _scheduleLabelFromNotes(String? notes) {
    if (notes == null) return null;

    String? dateText;
    String? preferredTime;
    for (final line in notes.split('\n')) {
      final normalized = line.toLowerCase();
      if (normalized.startsWith('appointment date:')) {
        dateText = line.substring('Appointment date:'.length).trim();
      }
      if (normalized.startsWith('preferred time:')) {
        preferredTime = line.substring('Preferred time:'.length).trim();
      }
    }

    if (dateText == null || dateText.isEmpty) return null;

    try {
      final date = DateTime.parse(dateText).toLocal();
      final hour = switch (preferredTime) {
        'Afternoon (1 PM - 4 PM)' => 13,
        'Evening (5 PM - 8 PM)' => 17,
        _ => 9,
      };
      final scheduled = DateTime(date.year, date.month, date.day, hour);
      return _scheduleLabel(scheduled.toIso8601String());
    } catch (_) {
      return dateText;
    }
  }

  static String? _scheduleLabel(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final date = DateTime.parse(raw).toLocal();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.year}-$month-$day • $hour:$minute $period';
    } catch (_) {
      return null;
    }
  }
}

class ConsultationService {
  ConsultationService._();

  static Future<List<ConsultationModel>> _cachedConsultations(String? status) async {
    final cached = await LocalDatabase.instance.getAllCachedData('cached_consultations');
    var models = cached.map((e) => ConsultationModel.fromJson(e)).toList();
    if (status != null) {
      models = models.where((c) => c.status == status).toList();
    }
    return models;
  }

  /// List consultations for the logged-in user.
  static Future<List<ConsultationModel>> listConsultations({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
      return _cachedConsultations(status);
    }

    try {
      String url = '${AppConfig.apiConsultations}?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';
      final response = await ApiClient.get(url);
      final List<dynamic> items = response['data'] as List<dynamic>? ?? [];

      for (var item in items) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          await LocalDatabase.instance.cacheData('cached_consultations', item['id'].toString(), item);
        }
      }

      return items
          .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _cachedConsultations(status);
    }
  }

  /// List consultations for the logged-in doctor (via /api/doctors/consultations).
  static Future<List<ConsultationModel>> listDoctorConsultations({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
      return _cachedConsultations(status);
    }

    try {
      String url = '${AppConfig.apiDoctors}/consultations?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';
      final response = await ApiClient.get(url);
      final List<dynamic> items = response['data'] as List<dynamic>? ?? [];

      for (var item in items) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          await LocalDatabase.instance.cacheData('cached_consultations', item['id'].toString(), item);
        }
      }

      return items
          .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _cachedConsultations(status);
    }
  }

  /// Create a new teleconsultation request.
  /// [type] must be one of: VIDEO, AUDIO, CHAT, OFFLINE.
  static Future<ConsultationModel> createConsultation({
    required String reason,
    String type = 'VIDEO',
    String? symptoms,
    String? scheduledTime,
    String? scheduledAt,
    String? doctorId,
    String? voiceNoteUrl,
    int? voiceNoteDuration,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'reason': reason,
    };
    if (symptoms != null && symptoms.isNotEmpty) body['symptoms'] = symptoms;
    if (scheduledAt != null && scheduledAt.isNotEmpty) {
      body['scheduledAt'] = scheduledAt;
    }
    // Keep a readable legacy representation as well. Older Render deployments
    // ignore the structured fields but still persist notes.
    body['notes'] = [
      reason,
      if (scheduledAt != null && scheduledAt.isNotEmpty)
        'Appointment date: ${DateTime.parse(scheduledAt).toLocal().toIso8601String().split('T').first}',
      if (scheduledTime != null && scheduledTime.isNotEmpty)
        'Preferred time: $scheduledTime',
    ].join('\n');
    if (doctorId != null) body['doctorId'] = doctorId;
    if (voiceNoteUrl != null) body['voiceNoteUrl'] = voiceNoteUrl;
    if (voiceNoteDuration != null) body['voiceNoteDuration'] = voiceNoteDuration;

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
        scheduledAt: scheduledAt,
        scheduledTime: scheduledTime,
        doctorId: doctorId,
        voiceNoteUrl: voiceNoteUrl,
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
  static Future<ConsultationModel> completeConsultation(
    String id, {
    String? symptoms,
    String? notes,
    String? riskLevel,
    List<Map<String, dynamic>>? medicines,
    String? prescriptionInstructions,
    String? followUpDate,
  }) async {
    final body = <String, dynamic>{};
    if (symptoms != null) body['symptoms'] = symptoms;
    if (notes != null) body['notes'] = notes;
    if (riskLevel != null) body['riskLevel'] = riskLevel;
    if (medicines != null) body['medicines'] = medicines;
    if (prescriptionInstructions != null) {
      body['prescriptionInstructions'] = prescriptionInstructions;
    }
    if (followUpDate != null) body['followUpDate'] = followUpDate;

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

  /// Update the status of a consultation directly (allowed for patients).
  static Future<void> updateStatus(String consultationId, String status) async {
    await SyncService.instance.push(
      entityType: 'consultation_$consultationId',
      operation: 'PATCH',
      endpoint: '${AppConfig.apiConsultations}/$consultationId/status',
      payload: {'status': status},
    );
  }
}
