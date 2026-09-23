import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_response.dart';
import 'auth_service.dart';
import 'offline_ai_service.dart';

class AiService {
  /// Development flag to prevent offline fallback from concealing online failures.
  /// When true, OfflineAiService will NOT be called on failure, letting the real error surface.
  static const bool debugForceOnlineAi = true;

  static Future<AiResponse> query(String queryText, {String? patientId}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    // ── 1. Node.js Backend AI Route (POST /api/ai/query) ───────────────────
    final backendUri = Uri.parse('${AppConfig.apiAi}/query');
    final backendBody = <String, dynamic>{
      'query': queryText,
      if (patientId != null) 'patientId': patientId,
    };

    final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}-${(queryText.hashCode.abs() % 100000).toString().padLeft(5, '0')}';
    final bool hasAuth = token.isNotEmpty;
    final int queryLen = queryText.length;

    print('[Flutter AI]');
    print('Request ID: $requestId');
    print('POST URL: $backendUri');
    print('query length: $queryLen');
    print('Authorization present: $hasAuth');

    bool isNetworkOrBackendUnavailable = false;
    String? lastError;

    try {
      final backendResponse = await http
          .post(
            backendUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Request-ID': requestId,
            },
            body: jsonEncode(backendBody),
          )
          .timeout(const Duration(seconds: 120));

      final contentType = backendResponse.headers['content-type'] ?? 'unknown';
      print('[Flutter AI]');
      print('HTTP status: ${backendResponse.statusCode}');
      print('response content type: $contentType');

      if (backendResponse.statusCode == 200) {
        final decoded = jsonDecode(backendResponse.body);
        final bool successExists = decoded is Map<String, dynamic> && decoded.containsKey('success');
        final bool dataExists = decoded is Map<String, dynamic> && decoded['data'] != null;

        Map<String, dynamic>? dataMap;
        if (dataExists && decoded['data'] is Map<String, dynamic>) {
          dataMap = decoded['data'] as Map<String, dynamic>;
        } else if (decoded is Map<String, dynamic> && decoded['query'] != null) {
          dataMap = decoded;
        }

        final bool answerExists = dataMap != null && dataMap['answer'] != null && dataMap['answer'].toString().trim().isNotEmpty;
        final String intent = dataMap?['intent']?.toString() ?? 'none';
        final String agent = dataMap?['agent']?.toString() ?? 'none';
        final String routingMethod = dataMap?['routing_method']?.toString() ?? 'none';

        print('whether success exists: $successExists');
        print('whether data exists: $dataExists');
        print('whether answer exists: $answerExists');
        print('intent: $intent');
        print('agent: $agent');
        print('routing_method: $routingMethod');

        if (answerExists && dataMap != null) {
          final rawAnswer = dataMap['answer'].toString();
          final preview = rawAnswer.length > 80 ? '${rawAnswer.substring(0, 80)}...' : rawAnswer;
          print('answer preview: $preview');

          // Strict verification: Do not disguise generic "AI unavailable" messages as success
          if (rawAnswer.contains('AI reasoning service is currently unavailable') ||
              rawAnswer.contains('AI response generation failed')) {
            throw Exception('Backend returned fallback error: $rawAnswer');
          }

          return AiResponse.fromJson(dataMap);
        } else {
          throw Exception('Backend returned 200 OK but payload is missing a valid answer field');
        }
      }

      // Check if the backend gave a 502/503/504 error response
      if (backendResponse.statusCode == 502 ||
          backendResponse.statusCode == 503 ||
          backendResponse.statusCode == 504) {
        isNetworkOrBackendUnavailable = true;
        lastError = 'Backend AI service unavailable (${backendResponse.statusCode}): ${backendResponse.body}';
      } else {
        // Validation error or client error (e.g. 400, 401, 403, 500)
        try {
          final error = jsonDecode(backendResponse.body);
          if (error is Map && error['message'] != null) {
            throw Exception(error['message']);
          }
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        }
        throw Exception('AI request failed with status ${backendResponse.statusCode}: ${backendResponse.body}');
      }
    } on SocketException catch (e) {
      isNetworkOrBackendUnavailable = true;
      lastError = 'Network connection failed: $e';
    } on TimeoutException catch (e) {
      isNetworkOrBackendUnavailable = true;
      lastError = 'Request timed out: $e';
    } on http.ClientException catch (e) {
      isNetworkOrBackendUnavailable = true;
      lastError = 'Client network exception: $e';
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('failed to fetch') ||
          str.contains('network') ||
          str.contains('connection') ||
          str.contains('clientexception')) {
        isNetworkOrBackendUnavailable = true;
        lastError = e.toString();
      } else {
        rethrow;
      }
    }

    // ── 2. Offline AI Fallback ───────────────────────────────────────────────
    // Phase 1: If debugForceOnlineAi is true, bypass offline fallback so actual online error surfaces
    if (debugForceOnlineAi) {
      print('[AiService] debugForceOnlineAi is TRUE: Bypassing OfflineAiService so online error surfaces.');
      throw Exception(
        lastError ?? 'Online AI service failed. (Silent offline fallback disabled for diagnostics)',
      );
    }

    // When Node.js backend or network is unreachable, route locally via
    // OfflineAiRouter -> Offline safety -> local lexicon -> local Qwen model.
    if (isNetworkOrBackendUnavailable) {
      print('[AiService] Online request failed ($lastError). Falling back to Offline AI.');

      try {
        await OfflineAiService.instance.initialise();

        final bool isEmergency = OfflineAiService.instance.isEmergency(queryText);
        final stream = OfflineAiService.instance.queryOffline(queryText);
        final buffer = StringBuffer();

        await for (final tokenChunk in stream) {
          buffer.write(tokenChunk);
        }

        final offlineText = buffer.toString().trim();
        if (offlineText.isNotEmpty) {
          return AiResponse(
            query: queryText,
            intent: 'offline_medical',
            agent: 'offline_ai_router',
            answer: offlineText,
            grounded: true,
            confidence: 'medium',
            urgency: isEmergency ? 'emergency' : 'routine',
            requiresProfessionalReview: true,
            routingMethod: 'offline_ai_safety_and_lexicon',
          );
        }
      } catch (offlineErr) {
        print('[AiService] Offline AI fallback failed: $offlineErr');
      }
    }

    throw Exception(
      lastError ?? 'AI service is currently unavailable. Please check your connection.',
    );
  }
}
