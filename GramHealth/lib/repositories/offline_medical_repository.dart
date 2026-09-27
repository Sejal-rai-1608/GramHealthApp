import '../models/medical_lexicon_entry.dart';
import '../services/offline_medical_lookup_service.dart';

/// Repository abstraction over [OfflineMedicalLookupService].
///
/// Provides a clean domain API that callers (e.g. the router, symptom
/// checker, AI chat) can use without depending on the lookup-service
/// implementation directly.
class OfflineMedicalRepository {
  OfflineMedicalRepository({
    OfflineMedicalLookupService? lookupService,
  }) : _lookup = lookupService ?? OfflineMedicalLookupService.instance;

  final OfflineMedicalLookupService _lookup;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> initialise() => _lookup.initialise();

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Free-text search: returns up to [OfflineAiConfig.offlineMaxEntries]
  /// entries whose condition, aliases, or symptoms match [query].
  Future<List<MedicalLexiconEntry>> search(String query) =>
      _lookup.search(query);

  /// Exact condition lookup by name or alias.
  Future<MedicalLexiconEntry?> findCondition(String condition) =>
      _lookup.findCondition(condition);

  /// Find entries that match a list of reported symptoms.
  Future<List<MedicalLexiconEntry>> findBySymptoms(
    List<String> symptoms,
  ) =>
      _lookup.findBySymptoms(symptoms);

  // ---------------------------------------------------------------------------
  // Symptom checker integration helper
  // ---------------------------------------------------------------------------

  /// Build a safe contextual message for the symptom checker screen
  /// when the app is offline.
  ///
  /// Deliberately avoids naming a definitive diagnosis.
  Future<String> buildSymptomCheckerContext(
    List<String> symptoms,
  ) async {
    final entries = await findBySymptoms(symptoms);
    if (entries.isEmpty) {
      return 'The offline assistant does not have specific information '
          'about this combination of symptoms. Please consult a healthcare '
          'provider or use GramHealth online when connectivity is available.';
    }

    final sb = StringBuffer();
    sb.writeln(
      'These symptoms can occur with several conditions. '
      'The offline assistant cannot determine the exact cause. '
      'Below is general information only — this is NOT a diagnosis.\n',
    );

    for (final entry in entries.take(2)) {
      sb.writeln('• ${entry.condition}');
      if (entry.warningSigns.isNotEmpty) {
        sb.writeln(
          '  Warning signs: ${entry.warningSigns.take(2).join(', ')}',
        );
      }
      sb.writeln('  ${entry.whenToSeekCare}');
    }

    sb.writeln(
      '\nPlease seek professional medical evaluation for a proper diagnosis.',
    );
    return sb.toString();
  }
}
