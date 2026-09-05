import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../data/local_database.dart';
import '../models/medical_record.dart';

class MedicalRecordService {
  Future<List<MedicalRecord>> getMyRecords() async {
    if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
      final cached = await LocalDatabase.instance.getAllCachedData('cached_records');
      return cached.map((json) => MedicalRecord.fromJson(json)).toList();
    }

    final token = await AuthService.getToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiMedicalRecords}/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> items = data['data'];

      for (var item in items) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          await LocalDatabase.instance.cacheData('cached_records', item['id'].toString(), item);
        }
      }

      return items.map((json) => MedicalRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load medical records');
    }
  }
  
  Future<List<MedicalRecord>> getDoctorRecords(String patientId) async {
    if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
      final cached = await LocalDatabase.instance.getAllCachedData('cached_records');
      var models = cached.map((json) => MedicalRecord.fromJson(json)).toList();
      return models.where((r) => r.patientId == patientId).toList();
    }

    final token = await AuthService.getToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiMedicalRecords}/patient/$patientId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> items = data['data'];

      for (var item in items) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          await LocalDatabase.instance.cacheData('cached_records', item['id'].toString(), item);
        }
      }

      return items.map((json) => MedicalRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch patient history: ${response.body}');
    }
  }

  Future<MedicalRecord> uploadManualRecord(String title, String type, String fileUrl) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('User not authenticated');

    if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
      final tempId = 'offline_temp_${DateTime.now().millisecondsSinceEpoch}';
      
      final recordData = {
        'id': tempId,
        'patientId': 'self',
        'title': title,
        'documentType': type,
        'fileUrl': fileUrl,
        'issuedDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'source': 'MANUAL',
      };
      
      await LocalDatabase.instance.cacheData('cached_records', tempId, recordData);
      
      await SyncService.instance.push(
        entityType: 'medical_record_$tempId',
        operation: 'POST',
        endpoint: '${AppConfig.apiMedicalRecords}/upload',
        payload: {
          'title': title,
          'documentType': type,
          'fileUrl': fileUrl,
          'issuedDate': recordData['issuedDate'],
        },
      );
      
      return MedicalRecord.fromJson(recordData);
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiMedicalRecords}/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'documentType': type,
        'fileUrl': fileUrl,
        'issuedDate': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return MedicalRecord.fromJson(data['data']);
    } else {
      throw Exception('Failed to upload record: ${response.statusCode} - ${response.body}');
    }
  }
}
