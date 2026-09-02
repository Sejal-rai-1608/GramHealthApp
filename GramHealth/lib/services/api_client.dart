import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Generic HTTP wrapper that:
/// - Attaches Authorization: Bearer <token> automatically.
/// - Decodes JSON and returns the parsed body.
/// - Throws [ApiException] on non-2xx responses.
class ApiClient {
  ApiClient._();

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _parseBody(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static void _assertSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final parsed = _parseBody(response);
      String message = 'Request failed (${response.statusCode})';
      if (parsed is Map) {
        if (parsed['code'] == 'VALIDATION_ERROR' && parsed['errors'] is List) {
          final errs = parsed['errors'] as List;
          if (errs.isNotEmpty && errs[0] is Map) {
            message = errs[0]['message'] ?? parsed['message'] ?? message;
          } else {
            message = parsed['message'] ?? message;
          }
        } else {
          message = parsed['message'] ?? message;
        }
      }
      throw ApiException(message: message, statusCode: response.statusCode);
    }
  }

  // ── Public Methods ────────────────────────────────────────────────────────

  static Future<dynamic> get(String url, {bool auth = true}) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(auth: auth),
    );
    _assertSuccess(response);
    return _parseBody(response);
  }

  static Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    _assertSuccess(response);
    return _parseBody(response);
  }

  static Future<dynamic> patch(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    _assertSuccess(response);
    return _parseBody(response);
  }

  static Future<dynamic> delete(String url, {bool auth = true}) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: await _headers(auth: auth),
    );
    _assertSuccess(response);
    return _parseBody(response);
  }
}

/// Typed exception thrown by [ApiClient] on non-2xx HTTP responses.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
