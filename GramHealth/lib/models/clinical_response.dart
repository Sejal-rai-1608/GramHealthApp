import 'package:flutter/material.dart';

/// Controlled Risk Level enum reflecting urgency based on symptoms,
/// red flags, available evidence, and uncertainty.
enum RiskLevel {
  emergency,
  high,
  moderate,
  low,
  insufficientInformation;

  static RiskLevel fromString(String? value) {
    if (value == null) return RiskLevel.insufficientInformation;
    switch (value.trim().toLowerCase()) {
      case 'emergency':
        return RiskLevel.emergency;
      case 'high':
        return RiskLevel.high;
      case 'moderate':
        return RiskLevel.moderate;
      case 'low':
        return RiskLevel.low;
      case 'insufficientinformation':
      case 'insufficient_information':
      case 'insufficient':
      default:
        return RiskLevel.insufficientInformation;
    }
  }

  String get displayName {
    switch (this) {
      case RiskLevel.emergency:
        return 'Emergency';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.insufficientInformation:
        return 'Insufficient Information';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.emergency:
        return const Color(0xFFD32F2F); // Deep Red
      case RiskLevel.high:
        return const Color(0xFFF57C00); // Orange
      case RiskLevel.moderate:
        return const Color(0xFFFFA000); // Amber
      case RiskLevel.low:
        return const Color(0xFF388E3C); // Green
      case RiskLevel.insufficientInformation:
        return const Color(0xFF757575); // Neutral Grey
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.emergency:
        return Icons.emergency;
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.moderate:
        return Icons.info_outline_rounded;
      case RiskLevel.low:
        return Icons.check_circle_outline_rounded;
      case RiskLevel.insufficientInformation:
        return Icons.help_outline_rounded;
    }
  }
}

/// Clinical assessment distinguishing what is reasonable to say,
/// what evidence was actually retrieved, and what uncertainty remains.
class Assessment {
  final String summary;
  final String evidenceBasis;
  final String uncertainty;

  const Assessment({
    required this.summary,
    required this.evidenceBasis,
    required this.uncertainty,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      summary: json['summary'] as String? ?? 'No clinical summary available.',
      evidenceBasis: json['evidence_basis'] as String? ?? 'No retrieved evidence basis.',
      uncertainty: json['uncertainty'] as String? ?? 'Available information is insufficient to determine causes.',
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'evidence_basis': evidenceBasis,
    'uncertainty': uncertainty,
  };
}

/// Non-diagnostic possibility consideration with transparent reasoning.
class PossibleCondition {
  final String name;
  final String reason;
  final String evidenceStatus;

  const PossibleCondition({
    required this.name,
    required this.reason,
    required this.evidenceStatus,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] as String? ?? 'Possible consideration',
      reason: json['reason'] as String? ?? 'Reported symptoms share clinical characteristics.',
      evidenceStatus: json['evidence_status'] as String? ?? 'Possible consideration; not confirmed.',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'reason': reason,
    'evidence_status': evidenceStatus,
  };
}

/// Itemized provenance item with explicit source type.
class EvidenceItem {
  final String title;
  final String sourceType;
  final String source;
  final String citation;
  final String relevance;

  const EvidenceItem({
    required this.title,
    required this.sourceType,
    required this.source,
    this.citation = '',
    required this.relevance,
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      title: json['title'] as String? ?? 'Evidence reference',
      sourceType: json['source_type'] as String? ?? 'None',
      source: json['source'] as String? ?? 'General clinical knowledge',
      citation: json['citation'] as String? ?? '',
      relevance: json['relevance'] as String? ?? 'General reference.',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'source_type': sourceType,
    'source': source,
    'citation': citation,
    'relevance': relevance,
  };
}

/// Unified 9-section structured healthcare response object.
class ClinicalResponse {
  final String symptomSummary;
  final Assessment assessment;
  final List<PossibleCondition> possibleConditions;
  final RiskLevel riskLevel;
  final List<String> whatYouCanDoNow;
  final List<String> warningSigns;
  final String whenToSeeDoctor;
  final List<EvidenceItem> evidence;
  final String medicalDisclaimer;
  final String sourceMode;
  final bool requiresProfessionalReview;
  final bool emergency;

  static const String standardDisclaimer =
      'This information is for general health guidance and is not a medical diagnosis. '
      'Please consult a qualified healthcare professional for personal medical advice.';

  const ClinicalResponse({
    required this.symptomSummary,
    required this.assessment,
    required this.possibleConditions,
    required this.riskLevel,
    required this.whatYouCanDoNow,
    required this.warningSigns,
    required this.whenToSeeDoctor,
    required this.evidence,
    this.medicalDisclaimer = standardDisclaimer,
    this.sourceMode = 'Medical RAG',
    this.requiresProfessionalReview = true,
    this.emergency = false,
  });

  factory ClinicalResponse.fromJson(Map<String, dynamic> json) {
    final possibleConditionsRaw = json['possible_conditions'] as List<dynamic>? ?? [];
    final conditions = possibleConditionsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => PossibleCondition.fromJson(e))
        .take(3)
        .toList();

    final evidenceRaw = json['evidence'] as List<dynamic>? ?? [];
    final evidenceItems = evidenceRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => EvidenceItem.fromJson(e))
        .toList();

    final whatRaw = json['what_you_can_do_now'] as List<dynamic>? ?? [];
    final whatList = whatRaw.map((e) => e.toString()).toList();

    final warningRaw = json['warning_signs'] as List<dynamic>? ?? [];
    final warningList = warningRaw.map((e) => e.toString()).toList();

    final emergencyFlag = json['emergency'] as bool? ?? false;
    final parsedRisk = RiskLevel.fromString(json['risk_level'] as String?);
    final effectiveRisk = emergencyFlag ? RiskLevel.emergency : parsedRisk;

    return ClinicalResponse(
      symptomSummary: json['symptom_summary'] as String? ?? 'Symptoms as reported by user.',
      assessment: json['assessment'] is Map<String, dynamic>
          ? Assessment.fromJson(json['assessment'] as Map<String, dynamic>)
          : const Assessment(
              summary: 'Information is limited.',
              evidenceBasis: 'None',
              uncertainty: 'Available information is insufficient to determine causes.',
            ),
      possibleConditions: conditions,
      riskLevel: effectiveRisk,
      whatYouCanDoNow: whatList.isNotEmpty
          ? whatList
          : const ['Rest and monitor symptoms.', 'Consult a doctor if symptoms persist.'],
      warningSigns: warningList.isNotEmpty
          ? warningList
          : const ['No specific warning signs were identified from the available information.'],
      whenToSeeDoctor: json['when_to_see_doctor'] as String? ??
          'Monitor and seek medical care if symptoms worsen or persist.',
      evidence: evidenceItems.isNotEmpty
          ? evidenceItems
          : const [
              EvidenceItem(
                title: 'No retrieved evidence',
                sourceType: 'None',
                source: 'No retrieved medical evidence',
                citation: '',
                relevance: 'Response is limited by insufficient evidence.',
              )
            ],
      medicalDisclaimer: json['medical_disclaimer'] as String? ?? standardDisclaimer,
      sourceMode: json['source_mode'] as String? ?? 'Medical RAG',
      requiresProfessionalReview: json['requires_professional_review'] as bool? ?? true,
      emergency: emergencyFlag || effectiveRisk == RiskLevel.emergency,
    );
  }

  Map<String, dynamic> toJson() => {
    'symptom_summary': symptomSummary,
    'assessment': assessment.toJson(),
    'possible_conditions': possibleConditions.map((e) => e.toJson()).toList(),
    'risk_level': riskLevel.name,
    'what_you_can_do_now': whatYouCanDoNow,
    'warning_signs': warningSigns,
    'when_to_see_doctor': whenToSeeDoctor,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'medical_disclaimer': medicalDisclaimer,
    'source_mode': sourceMode,
    'requires_professional_review': requiresProfessionalReview,
    'emergency': emergency,
  };

  /// Deterministic emergency factory constructor
  factory ClinicalResponse.emergency({
    required String query,
    List<String> matchedTerms = const [],
  }) {
    return ClinicalResponse(
      symptomSummary: 'Reported symptoms with emergency indicators: $query',
      assessment: const Assessment(
        summary: 'Emergency indicators or critical red-flag symptoms have been identified. Immediate medical attention may be required.',
        evidenceBasis: 'Deterministic Safety Rule',
        uncertainty: 'Acute medical emergencies cannot be evaluated or managed remotely.',
      ),
      possibleConditions: const [],
      riskLevel: RiskLevel.emergency,
      whatYouCanDoNow: const [
        'Call local emergency services immediately (108 / 112).',
        'Go to the nearest hospital emergency room right now.',
        'Do not wait or attempt to treat severe symptoms at home.',
        'Ensure someone stays with the patient while seeking immediate medical help.',
      ],
      warningSigns: const [
        'Severe chest pain, pressure, or tightness',
        'Severe shortness of breath or difficulty breathing',
        'Loss of consciousness or fainting',
        'Sudden weakness, numbness, or difficulty speaking',
        'Severe uncontrolled bleeding',
      ],
      whenToSeeDoctor: 'Seek emergency medical attention IMMEDIATELY. Call 108 / 112 or visit the nearest emergency department.',
      evidence: const [
        EvidenceItem(
          title: 'Emergency Safety Protocol',
          sourceType: 'Deterministic Safety Rule',
          source: 'GramHealth Emergency Protocol',
          citation: 'EMERGENCY-01',
          relevance: 'Deterministic safety triage triggered by reported red flags.',
        )
      ],
      medicalDisclaimer: standardDisclaimer,
      sourceMode: 'Deterministic Safety Rule',
      requiresProfessionalReview: true,
      emergency: true,
    );
  }

  /// Safe offline lexicon-only factory constructor
  factory ClinicalResponse.offlineLexicon({
    required String query,
    required String conditionName,
    required String generalInfo,
    required List<String> warningSigns,
    required String whenToSeekCare,
    required String source,
    required String citation,
  }) {
    return ClinicalResponse(
      symptomSummary: query,
      assessment: Assessment(
        summary: generalInfo,
        evidenceBasis: 'Offline Medical Lexicon',
        uncertainty: 'Available offline information is for general reference; cannot confirm causes remotely.',
      ),
      possibleConditions: [
        PossibleCondition(
          name: conditionName,
          reason: 'Reported symptoms align with offline public health topic.',
          evidenceStatus: 'Possible consideration; not confirmed.',
        )
      ],
      riskLevel: warningSigns.isNotEmpty ? RiskLevel.moderate : RiskLevel.low,
      whatYouCanDoNow: const [
        'Rest and monitor your symptoms.',
        'Drink fluids if able to tolerate them.',
        'Avoid foods or activities that aggravate symptoms.',
        'Record when symptoms began and how they change.',
      ],
      warningSigns: warningSigns.isNotEmpty
          ? warningSigns
          : const ['No specific warning signs were identified from the available information.'],
      whenToSeeDoctor: whenToSeekCare.isNotEmpty
          ? whenToSeekCare
          : 'Consult a qualified healthcare provider if symptoms persist or worsen.',
      evidence: [
        EvidenceItem(
          title: 'Offline medical reference: $conditionName',
          sourceType: 'Offline Medical Lexicon',
          source: source.isNotEmpty ? source : 'WHO / Clinical Reference',
          citation: citation,
          relevance: 'Used as general medical reference context.',
        )
      ],
      medicalDisclaimer: standardDisclaimer,
      sourceMode: 'Offline Medical Lexicon',
      requiresProfessionalReview: true,
      emergency: false,
    );
  }

  /// Safe offline unknown / unsupported topic factory constructor
  factory ClinicalResponse.offlineUnknown({
    required String query,
  }) {
    return ClinicalResponse(
      symptomSummary: query,
      assessment: const Assessment(
        summary: 'No specific medical conclusion can be made from the available offline information.',
        evidenceBasis: 'None',
        uncertainty: 'The offline assistant does not have verified offline reference data for this specific topic.',
      ),
      possibleConditions: const [],
      riskLevel: RiskLevel.insufficientInformation,
      whatYouCanDoNow: const [
        'Monitor your symptoms closely.',
        'Connect to the internet to query GramHealth Online AI.',
        'Consult a qualified healthcare professional for personalized medical advice.',
      ],
      warningSigns: const ['No specific warning signs were identified from the available information.'],
      whenToSeeDoctor: 'Seek medical care if you feel unwell, symptoms worsen, or concerning signs appear.',
      evidence: const [
        EvidenceItem(
          title: 'No retrieved evidence',
          sourceType: 'None',
          source: 'No retrieved medical evidence',
          citation: '',
          relevance: 'Response is limited by insufficient offline information.',
        )
      ],
      medicalDisclaimer: standardDisclaimer,
      sourceMode: 'Offline Medical Lexicon',
      requiresProfessionalReview: true,
      emergency: false,
    );
  }

  /// Generates a human-readable text representation of the 9 sections
  String toFormattedText() {
    final sb = StringBuffer();
    if (emergency) {
      sb.writeln('🚨 EMERGENCY\nThese symptoms may require urgent medical attention.\n');
    }
    sb.writeln('SYMPTOM SUMMARY:\n$symptomSummary\n');
    sb.writeln('ASSESSMENT:\n${assessment.summary}');
    sb.writeln('Evidence basis: ${assessment.evidenceBasis}');
    sb.writeln('Uncertainty: ${assessment.uncertainty}\n');

    if (possibleConditions.isNotEmpty) {
      sb.writeln('POSSIBLE CONDITIONS:');
      for (final cond in possibleConditions) {
        sb.writeln('• ${cond.name}');
        sb.writeln('  Why considered: ${cond.reason}');
        sb.writeln('  Evidence status: ${cond.evidenceStatus}');
      }
      sb.writeln();
    }

    sb.writeln('RISK LEVEL: ${riskLevel.displayName.toUpperCase()}\n');

    if (whatYouCanDoNow.isNotEmpty) {
      sb.writeln('WHAT YOU CAN DO NOW:');
      for (final act in whatYouCanDoNow) {
        sb.writeln('• $act');
      }
      sb.writeln();
    }

    if (warningSigns.isNotEmpty) {
      sb.writeln('WARNING SIGNS:');
      for (final ws in warningSigns) {
        sb.writeln('⚠ $ws');
      }
      sb.writeln();
    }

    sb.writeln('WHEN TO SEE A DOCTOR:\n$whenToSeeDoctor\n');

    if (evidence.isNotEmpty) {
      sb.writeln('EVIDENCE / SOURCE:');
      for (final ev in evidence) {
        final cit = ev.citation.isNotEmpty ? ' [${ev.citation}]' : '';
        sb.writeln('• ${ev.title} (${ev.sourceType} - ${ev.source})$cit');
      }
      sb.writeln();
    }

    sb.write('MEDICAL DISCLAIMER:\n$medicalDisclaimer');
    return sb.toString().trim();
  }
}
