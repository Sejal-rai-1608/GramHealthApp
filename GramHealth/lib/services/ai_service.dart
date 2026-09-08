import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_response.dart';
import 'auth_service.dart';

class AiService {
  static Future<AiResponse> query(String queryText, {String? patientId}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{
      'query': queryText,
    };
    if (patientId != null) {
      body['patientId'] = patientId;
    }

    final uri = Uri.parse('${AppConfig.apiAi}/query');
    final hasAuthHeader = token.isNotEmpty;
    
    // Development-safe logging
    assert(() {
      print('[AiService] Request: POST $uri');
      print('[AiService] Has Authorization Header: $hasAuthHeader');
      print('[AiService] Token Length: ${token.length}');
      return true;
    }());

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    assert(() {
      print('[AiService] Response Status: ${response.statusCode}');
      return true;
    }());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return AiResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to query AI');
      }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to query AI (Status: ${response.statusCode})');
    }
  }
}
