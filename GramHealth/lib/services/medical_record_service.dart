import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/medical_record.dart';

class MedicalRecordService {
  Future<List<MedicalRecord>> getMyRecords() async {
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
      return items.map((json) => MedicalRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load medical records');
    }
  }
  
  Future<List<MedicalRecord>> getDoctorRecords(String patientId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('User not authenticated');

    // Assuming there's a route for doctors to fetch a specific patient's record, 
    // but the backend only provides /:id currently. For the MVP, we will simulate
    // fetching the patient's records if we had the route, or just rely on the doctor fetching them.
    // For now we will just use it to view a single record if needed.
    return [];
  }

  Future<MedicalRecord> uploadManualRecord(String title, String type, String fileUrl) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('User not authenticated');

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
