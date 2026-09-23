import '../models/offline_response.dart';

/// Deterministic emergency safety layer.
///
/// Runs BEFORE Qwen or any LLM. The LLM must NEVER override this layer.
/// Reuses / extends the GramHealth existing emergency-detection vocabulary.
class OfflineSafetyService {
  OfflineSafetyService._();
  static final OfflineSafetyService instance = OfflineSafetyService._();

  // ---------------------------------------------------------------------------
  // Emergency keyword sets (English + common Hindi transliterations)
  // ---------------------------------------------------------------------------

  static const List<String> _breathingEmergency = [
    'difficulty breathing', 'trouble breathing', 'can\'t breathe',
    'cannot breathe', 'short of breath', 'breathlessness',
    'saans nahi aa raha', 'saans nahi', 'saans lene mein takleef',
    'shwas ghyayla tras', 'shwas ghetana tras', 'shwas lagto',
    'dam lagto', 'shwas yet nahi',
    'choking', 'suffocating',
  ];

  static const List<String> _chestPainEmergency = [
    'chest pain', 'severe chest pain', 'chest tightness',
    'heart attack', 'seena dard', 'seene mein dard',
    'chaati madhe dukhat', 'chaatit dukhat', 'chaatit vedna',
    'crushing chest', 'chest pressure',
  ];

  static const List<String> _strokeEmergency = [
    'stroke', 'face drooping', 'arm weakness', 'speech difficulty',
    'sudden numbness', 'sudden confusion', 'sudden vision',
    'worst headache of life', 'pakshaghat', 'lakwa',
  ];

  static const List<String> _unconsciousEmergency = [
    'unconscious', 'unresponsive', 'fainted', 'passed out',
    'not waking up', 'loss of consciousness', 'behosh',
    'hosh nahi', 'gir gaya', 'beshuddh', 'beshudh',
  ];

  static const List<String> _seizureEmergency = [
    'seizure', 'convulsion', 'fits', 'epilepsy attack',
    'body shaking', 'dauraa', 'mirgi', 'aetke yene', 'aanchki',
  ];

  static const List<String> _bleedingEmergency = [
    'severe bleeding', 'heavy bleeding', 'blood loss',
    'uncontrolled bleeding', 'coughing blood', 'blood in stool',
    'khoon aa raha', 'bahut khoon', 'raktasrav', 'rakta yet aahe',
  ];

  static const List<String> _allergyEmergency = [
    'anaphylaxis', 'allergic reaction', 'throat swelling',
    'tongue swelling', 'hives with breathing',
  ];

  static const List<String> _mentalHealthEmergency = [
    'suicidal', 'suicide', 'self-harm', 'self harm',
    'want to die', 'kill myself', 'hurt myself',
    'khatam karna chahta', 'jeena nahi chahta',
  ];

  static const List<String> _snakeBiteEmergency = [
    'snake bite', 'snakebite', 'saanp ne kaata', 'saanp chaavla',
    'saanp chavla', 'vinchu chavla', 'scorpion sting',
  ];

  static const List<String> _poisoningEmergency = [
    'poisoning', 'swallowed poison', 'overdose',
    'zehr khaya', 'dawa zyada le li', 'vishbaadha', 'vishbadha',
  ];

  // Paediatric emergencies
  static const List<String> _paediatricEmergency = [
    'baby not breathing', 'infant seizure', 'newborn unconscious',
    'child convulsion', 'high fever seizure', 'febrile seizure',
  ];

  static const List<List<String>> _allSets = [
    _breathingEmergency,
    _chestPainEmergency,
    _strokeEmergency,
    _unconsciousEmergency,
    _seizureEmergency,
    _bleedingEmergency,
    _allergyEmergency,
    _mentalHealthEmergency,
    _snakeBiteEmergency,
    _poisoningEmergency,
    _paediatricEmergency,
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns true if the query contains emergency keywords.
  /// This is deterministic – never LLM-based.
  bool isEmergency(String query) {
    final normalised = _normalise(query);
    for (final set in _allSets) {
      for (final kw in set) {
        if (normalised.contains(kw)) return true;
      }
    }
    return false;
  }

  /// Returns matched emergency keywords (for diagnostics only, no patient
  /// content is logged).
  List<String> matchedEmergencyTerms(String query) {
    final normalised = _normalise(query);
    final matched = <String>[];
    for (final set in _allSets) {
      for (final kw in set) {
        if (normalised.contains(kw)) matched.add(kw);
      }
    }
    return matched;
  }

  /// Build the deterministic emergency [OfflineResponse].
  OfflineResponse buildEmergencyResponse(List<String> matchedTerms) {
    return OfflineResponse.emergency(matchedTerms: matchedTerms);
  }

  // ---------------------------------------------------------------------------
  // Post-generation safety filter
  // ---------------------------------------------------------------------------

  /// Strips clearly unsafe patterns from generated text.
  /// The LLM prompt already instructs the model not to diagnose or prescribe,
  /// but this adds a hard post-processing guard.
  String sanitiseGeneratedText(String text) {
    // Remove any claim of definitive diagnosis
    var result = text;
    for (final pattern in _unsafePatterns) {
      result = result.replaceAll(
        RegExp(pattern, caseSensitive: false),
        '[Information removed for safety]',
      );
    }
    return result.trim();
  }

  static const List<String> _unsafePatterns = [
    r'you have (?:been diagnosed with|definitive|confirmed)',
    r'the diagnosis is (?:definitely|certainly|confirmed)',
    r'take (?:\d+\s*mg|\d+ tablet|\d+ pill)',
    r'dosage[:\s]+\d+',
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _normalise(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
