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

  const OfflineResponse({
    required this.text,
    required this.decision,
    this.isStreaming = false,
    this.isEmergency = false,
    this.matchedTerms = const [],
    this.diagnosticsJson,
  });

  /// Emergency response with deterministic text.
  factory OfflineResponse.emergency({
    String? customText,
    List<String> matchedTerms = const [],
  }) {
    return OfflineResponse(
      text: customText ??
          'These symptoms may require urgent medical attention. '
              'Please contact local emergency services (108) or go to the '
              'nearest emergency department immediately. '
              'Do not wait for an online consultation.',
      decision: OfflineResponseDecision.emergency,
      isEmergency: true,
      matchedTerms: matchedTerms,
    );
  }

  /// Safe "offline unavailable" response.
  factory OfflineResponse.unavailable() {
    return const OfflineResponse(
      text:
          'Offline AI is not available on this device. '
          'Please use GramHealth online for medical questions.',
      decision: OfflineResponseDecision.unavailable,
    );
  }

  /// Safe "no information found" response.
  factory OfflineResponse.noInformation() {
    return const OfflineResponse(
      text:
          'The offline assistant does not have specific information about '
          'this topic. For medical questions, please consult a qualified '
          'healthcare provider or use GramHealth online when connectivity '
          'is available.',
      decision: OfflineResponseDecision.unsupported,
    );
  }

  @override
  String toString() =>
      'OfflineResponse(decision=$decision, emergency=$isEmergency, '
      'terms=$matchedTerms)';
}
