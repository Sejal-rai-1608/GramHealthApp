import 'dart:async';
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

  /// The backend runs on a free Render tier that sleeps when idle. The first
  /// request after an idle period can return a transient 502/503 while the
  /// instance wakes, so those are retried before the failure is surfaced.
  static const int _maxAttempts = 3;
  static const Duration _requestTimeout = Duration(seconds: 35);

  static bool _isTransient(int statusCode) =>
      statusCode == 502 || statusCode == 503 || statusCode == 504;

  static Future<dynamic> _withRetry(
    Future<http.Response> Function() send, {
    required bool auth,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await send().timeout(_requestTimeout);
        if (_isTransient(response.statusCode) && attempt < _maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 1200 * (attempt + 1)));
          continue;
        }
        _assertSuccess(response);
        return _parseBody(response);
      } on TimeoutException {
        lastError = TimeoutException('Request timed out');
        if (attempt < _maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 1200 * (attempt + 1)));
          continue;
        }
        rethrow;
      } catch (e) {
        lastError = e;
        if (e is ApiException && !_isTransient(e.statusCode)) rethrow;
        if (attempt < _maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 1200 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    throw lastError is Exception
        ? lastError
        : ApiException(message: 'Request failed', statusCode: 0);
  }

  static Future<dynamic> get(String url, {bool auth = true}) async {
    return _withRetry(
      () async => http.get(Uri.parse(url), headers: await _headers(auth: auth)),
      auth: auth,
    );
  }

  static Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _withRetry(
      () async => http.post(
        Uri.parse(url),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ),
      auth: auth,
    );
  }

  static Future<dynamic> patch(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _withRetry(
      () async => http.patch(
        Uri.parse(url),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ),
      auth: auth,
    );
  }

  static Future<dynamic> delete(String url, {bool auth = true}) async {
    return _withRetry(
      () async => http.delete(Uri.parse(url), headers: await _headers(auth: auth)),
      auth: auth,
    );
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
