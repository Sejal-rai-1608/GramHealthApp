import '../config/offline_ai_config.dart';
import '../models/medical_lexicon_entry.dart';
import '../models/offline_response.dart';
import '../models/local_model_status.dart';
import 'offline_medical_lookup_service.dart';
import 'offline_safety_service.dart';
import 'local_model_manager.dart';
import 'local_llm_service.dart';

/// Routes an offline query through the fallback hierarchy:
///
///   LEVEL 2  Emergency deterministic rules
///   LEVEL 3  Medical lexicon + Qwen LLM
///   LEVEL 4  Medical lexicon only
///   LEVEL 5  Safe "information unavailable" message
///
/// LEVEL 1 (online GramHealth AI) is handled by the caller before this
/// router is ever invoked.
class OfflineAiRouter {
  OfflineAiRouter({
    required this.safetyService,
    required this.lookupService,
    required this.modelManager,
    required this.llmService,
  });

  final OfflineSafetyService safetyService;
  final OfflineMedicalLookupService lookupService;
  final LocalModelManager modelManager;
  final LocalLlmService llmService;

  // ---------------------------------------------------------------------------
  // Main entry point: streaming route
  // ---------------------------------------------------------------------------

  /// Route a query and stream the response tokens.
  ///
  /// The caller gets an [OfflineResponse] synchronously describing the decision,
  /// then tokens arrive via the [Stream<String>] if the LLM is used.
  Future<_RoutingResult> route(String query) async {
    // --- LEVEL 2: Emergency safety ---
    final emergencyTerms = safetyService.matchedEmergencyTerms(query);
    if (emergencyTerms.isNotEmpty) {
      final response = safetyService.buildEmergencyResponse(emergencyTerms);
      return _RoutingResult(
        response: response,
        stream: Stream.value(response.text),
      );
    }

    // --- Lexicon lookup ---
    List<MedicalLexiconEntry> entries = [];
    try {
      entries = await lookupService.search(query);
    } catch (e) {
      _log('Lexicon lookup failed: $e');
    }

    final isModelReady =
        modelManager.status == LocalModelStatus.loaded ||
        modelManager.status == LocalModelStatus.generating;

    // --- LEVEL 3: Lexicon + LLM ---
    if (entries.isNotEmpty && isModelReady) {
      final context = _buildContext(entries);
      final prompt = _buildPrompt(query: query, context: context);
      final matchedTerms = entries.map((e) => e.condition).toList();

      late Stream<String> tokenStream;
      try {
        tokenStream = llmService.generate(
          prompt: prompt,
          systemPrompt: _kSystemPrompt,
        );
      } catch (e) {
        _log('LLM generation failed: $e');
        // fall through to level 4
        return _buildLexiconOnlyResult(entries);
      }

      // Post-process streamed tokens
      final safeStream = tokenStream.map(
        (token) => safetyService.sanitiseGeneratedText(token),
      );

      return _RoutingResult(
        response: OfflineResponse(
          text: '', // filled progressively from stream
          decision: OfflineResponseDecision.medicalLexiconPlusLlm,
          matchedTerms: matchedTerms,
        ),
        stream: safeStream,
      );
    }

    // --- LEVEL 4: Lexicon only ---
    if (entries.isNotEmpty) {
      return _buildLexiconOnlyResult(entries);
    }

    // --- LEVEL 5: Unavailable / unsupported ---
    if (!isModelReady &&
        modelManager.status == LocalModelStatus.unavailable) {
      return _RoutingResult(
        response: OfflineResponse.unavailable(),
        stream: Stream.value(OfflineResponse.unavailable().text),
      );
    }

    return _RoutingResult(
      response: OfflineResponse.noInformation(),
      stream: Stream.value(OfflineResponse.noInformation().text),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  _RoutingResult _buildLexiconOnlyResult(
    List<MedicalLexiconEntry> entries,
  ) {
    final sb = StringBuffer();
    sb.writeln(
      'The offline assistant found the following general information. '
      'This is NOT a diagnosis. Please consult a qualified healthcare '
      'provider for personal medical advice.\n',
    );
    for (final entry in entries) {
      sb.writeln('--- ${entry.condition} ---');
      if (entry.warningSigns.isNotEmpty) {
        sb.writeln(
          'Warning signs: ${entry.warningSigns.take(3).join(', ')}',
        );
      }
      sb.writeln(entry.generalInformation);
      sb.writeln('When to seek care: ${entry.whenToSeekCare}');
      sb.writeln();
    }
    final text = sb.toString().trim();
    final matchedTerms = entries.map((e) => e.condition).toList();

    return _RoutingResult(
      response: OfflineResponse(
        text: text,
        decision: OfflineResponseDecision.lexiconOnly,
        matchedTerms: matchedTerms,
      ),
      stream: Stream.value(text),
    );
  }

  String _buildContext(List<MedicalLexiconEntry> entries) {
    var total = 0;
    final parts = <String>[];
    for (final entry in entries) {
      final snippet = entry.toContextSnippet(
        maxChars: OfflineAiConfig.offlineContextMaxCharacters ~/
            entries.length,
      );
      if (total + snippet.length > OfflineAiConfig.offlineContextMaxCharacters) {
        break;
      }
      parts.add(snippet);
      total += snippet.length;
    }
    return parts.join('\n---\n');
  }

  String _buildPrompt({
    required String query,
    required String context,
  }) {
    return 'USER QUERY:\n$query\n\n'
        'OFFLINE MEDICAL CONTEXT:\n$context';
  }

  void _log(String msg) {
    if (OfflineAiConfig.enableDiagnostics) {
      // ignore: avoid_print
      print('[OfflineAiRouter] $msg');
    }
  }

  // ---------------------------------------------------------------------------
  // System prompt
  // ---------------------------------------------------------------------------

  static const String _kSystemPrompt =
      'You are GramHealth Offline Assistant.\n\n'
      'You are an offline health-information assistant, not a doctor.\n\n'
      'Use only the supplied OFFLINE MEDICAL CONTEXT as factual medical '
      'knowledge. Do not invent facts outside that context.\n\n'
      'Do not diagnose a disease with certainty.\n'
      'Do not prescribe medications or dosages.\n'
      'Do not contradict emergency safety instructions.\n'
      'When the context is insufficient, say that the available offline '
      'information is limited.\n\n'
      'For every medical question provide:\n'
      '1. What the symptom/topic generally means\n'
      '2. Important warning signs\n'
      '3. Safe next step\n'
      '4. When professional medical evaluation is recommended\n\n'
      'Always end with a reminder to seek professional care for '
      'personalised medical advice.';
}

/// Internal result bundling the decision + token stream.
class _RoutingResult {
  const _RoutingResult({
    required this.response,
    required this.stream,
  });
  final OfflineResponse response;
  final Stream<String> stream;
}
