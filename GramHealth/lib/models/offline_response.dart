import 'clinical_response.dart';

/// The decision made by [OfflineAiRouter] before processing a query.
enum OfflineResponseDecision {
  /// Query contains emergency symptoms — return deterministic emergency response.
  emergency,

  /// Medical keyword found; use lexicon context + local LLM.
  medicalLexiconPlusLlm,

  /// Local LLM unavailable; return lexicon-only structured response.
  lexiconOnly,

  /// No medical context found; return safe "information unavailable" message.
  unsupported,

  /// Offline AI itself is unavailable (model not downloaded, device incompatible).
  unavailable,
}

/// The final offline response returned to the UI.
class OfflineResponse {
  final String text;
  final OfflineResponseDecision decision;
  final bool isStreaming;
  final bool isEmergency;
  final List<String> matchedTerms;
  final String? diagnosticsJson;
  final ClinicalResponse? structuredResponse;

  const OfflineResponse({
    required this.text,
    required this.decision,
    this.isStreaming = false,
    this.isEmergency = false,
    this.matchedTerms = const [],
    this.diagnosticsJson,
    this.structuredResponse,
  });

  /// Emergency response with deterministic text and 9-section structured model.
  factory OfflineResponse.emergency({
    String? query,
    String? customText,
    List<String> matchedTerms = const [],
  }) {
    final structured = ClinicalResponse.emergency(
      query: query ?? (matchedTerms.isNotEmpty ? matchedTerms.join(', ') : 'Reported emergency symptoms'),
      matchedTerms: matchedTerms,
    );
    return OfflineResponse(
      text: customText ?? structured.toFormattedText(),
      decision: OfflineResponseDecision.emergency,
      isEmergency: true,
      matchedTerms: matchedTerms,
      structuredResponse: structured,
    );
  }

  /// Safe "offline unavailable" response.
  factory OfflineResponse.unavailable({String? query}) {
    final structured = ClinicalResponse.offlineUnknown(query: query ?? 'Query');
    return OfflineResponse(
      text:
          'Offline AI is not available on this device. '
          'Please use GramHealth online for medical questions.',
      decision: OfflineResponseDecision.unavailable,
      structuredResponse: structured,
    );
  }

  /// Safe "no information found" response.
  factory OfflineResponse.noInformation({String? query}) {
    final structured = ClinicalResponse.offlineUnknown(query: query ?? 'Medical question');
    return OfflineResponse(
      text:
          'The offline assistant does not have specific information about '
          'this topic. For medical questions, please consult a qualified '
          'healthcare provider or use GramHealth online when connectivity '
          'is available.',
      decision: OfflineResponseDecision.unsupported,
      structuredResponse: structured,
    );
  }

  @override
  String toString() =>
      'OfflineResponse(decision=$decision, emergency=$isEmergency, '
      'terms=$matchedTerms)';
}
