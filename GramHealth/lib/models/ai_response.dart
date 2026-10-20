import 'clinical_response.dart';

class AiResponse {
  final String query;
  final String? intent;
  final String? agent;
  final String? answer;
  final bool? grounded;
  final String? confidence;
  final String? urgency;
  final bool? requiresProfessionalReview;
  final Map<String, dynamic>? evidence;
  final List<String>? sources;
  final String? routingMethod;
  final List<String>? graphPath;
  final ClinicalResponse? structuredResponse;

  AiResponse({
    required this.query,
    this.intent,
    this.agent,
    this.answer,
    this.grounded,
    this.confidence,
    this.urgency,
    this.requiresProfessionalReview,
    this.evidence,
    this.sources,
    this.routingMethod,
    this.graphPath,
    this.structuredResponse,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      query: json['query'] as String,
      intent: json['intent'] as String?,
      agent: json['agent'] as String?,
      answer: json['answer'] as String?,
      grounded: json['grounded'] as bool?,
      confidence: json['confidence'] as String?,
      urgency: json['urgency'] as String?,
      requiresProfessionalReview: json['requires_professional_review'] as bool?,
      evidence: json['evidence'] as Map<String, dynamic>?,
      sources: (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList(),
      routingMethod: json['routing_method'] as String?,
      graphPath: (json['graph_path'] as List<dynamic>?)?.map((e) => e as String).toList(),
      // The backend sends the nine-section clinical payload as
      // `structured_response`. Without parsing it here the clinical card
      // would never render for an online AI answer.
      structuredResponse: _parseStructured(json),
    );
  }

  static ClinicalResponse? _parseStructured(Map<String, dynamic> json) {
    final raw = json['structured_response'] ?? json['structuredResponse'];
    if (raw is ClinicalResponse) return raw;
    if (raw is Map<String, dynamic>) {
      try {
        return ClinicalResponse.fromJson(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
