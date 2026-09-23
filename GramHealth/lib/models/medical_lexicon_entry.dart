/// A single entry in the offline medical knowledge lexicon.
///
/// Every entry must carry provenance (source, source_url, license)
/// so content can be audited and updated.
class MedicalLexiconEntry {
  final String condition;
  final List<String> aliases;
  final List<String> symptoms;
  final List<String> warningSigns;
  final String generalInformation;
  final String whenToSeekCare;
  final bool isEmergencyFlag;
  final String source;
  final String sourceUrl;
  final String license;
  final String? lastReviewed;

  const MedicalLexiconEntry({
    required this.condition,
    required this.aliases,
    required this.symptoms,
    required this.warningSigns,
    required this.generalInformation,
    required this.whenToSeekCare,
    this.isEmergencyFlag = false,
    required this.source,
    required this.sourceUrl,
    required this.license,
    this.lastReviewed,
  });

  factory MedicalLexiconEntry.fromJson(Map<String, dynamic> json) {
    return MedicalLexiconEntry(
      condition: json['condition'] as String,
      aliases: List<String>.from((json['aliases'] as List?) ?? []),
      symptoms: List<String>.from((json['symptoms'] as List?) ?? []),
      warningSigns: List<String>.from((json['warning_signs'] as List?) ?? []),
      generalInformation: json['general_information'] as String? ?? '',
      whenToSeekCare: json['when_to_seek_care'] as String? ?? '',
      isEmergencyFlag: json['is_emergency_flag'] as bool? ?? false,
      source: json['source'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      license: json['license'] as String? ?? '',
      lastReviewed: json['last_reviewed'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'aliases': aliases,
        'symptoms': symptoms,
        'warning_signs': warningSigns,
        'general_information': generalInformation,
        'when_to_seek_care': whenToSeekCare,
        'is_emergency_flag': isEmergencyFlag,
        'source': source,
        'source_url': sourceUrl,
        'license': license,
        'last_reviewed': lastReviewed,
      };

  /// All searchable text for this entry (lowercased).
  String get searchableText =>
      '${condition.toLowerCase()} '
      '${aliases.join(' ').toLowerCase()} '
      '${symptoms.join(' ').toLowerCase()}';

  /// Concise context snippet for LLM injection (respects token budget).
  String toContextSnippet({int maxChars = 800}) {
    final sb = StringBuffer();
    sb.writeln('Condition: $condition');
    if (warningSigns.isNotEmpty) {
      sb.writeln('Warning signs: ${warningSigns.take(4).join(', ')}');
    }
    sb.writeln('General info: $generalInformation');
    sb.writeln('When to seek care: $whenToSeekCare');
    final result = sb.toString();
    return result.length > maxChars
        ? '${result.substring(0, maxChars)}...'
        : result;
  }

  @override
  String toString() => 'MedicalLexiconEntry($condition)';
}
