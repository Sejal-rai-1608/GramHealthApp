import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare_flutter/models/clinical_response.dart';
import 'package:ruralcare_flutter/models/ai_response.dart';
import 'package:ruralcare_flutter/models/offline_response.dart';

void main() {
  group('ClinicalResponse Model Tests', () {
    test('RiskLevel enum parsing and display names', () {
      expect(RiskLevel.fromString('emergency'), RiskLevel.emergency);
      expect(RiskLevel.fromString('high'), RiskLevel.high);
      expect(RiskLevel.fromString('moderate'), RiskLevel.moderate);
      expect(RiskLevel.fromString('low'), RiskLevel.low);
      expect(RiskLevel.fromString('insufficientInformation'), RiskLevel.insufficientInformation);
      expect(RiskLevel.fromString('unknown_val'), RiskLevel.insufficientInformation);
      expect(RiskLevel.fromString(null), RiskLevel.insufficientInformation);

      expect(RiskLevel.emergency.displayName, 'Emergency');
      expect(RiskLevel.high.displayName, 'High Risk');
      expect(RiskLevel.moderate.displayName, 'Moderate Risk');
      expect(RiskLevel.low.displayName, 'Low Risk');
      expect(RiskLevel.insufficientInformation.displayName, 'Insufficient Information');
    });

    test('ClinicalResponse fromJson parses full 9 sections accurately', () {
      final json = {
        'symptom_summary': 'Stomach pain after dinner',
        'assessment': {
          'summary': 'Symptoms started after food intake.',
          'evidence_basis': 'Reported timing',
          'uncertainty': 'Available information is insufficient to determine cause.',
        },
        'possible_conditions': [
          {
            'name': 'Gastroenteritis',
            'reason': 'Symptoms started post-meal.',
            'evidence_status': 'Possible; not confirmed.',
          }
        ],
        'risk_level': 'insufficientInformation',
        'what_you_can_do_now': [
          'Rest and monitor symptoms.',
          'Drink fluids if tolerated.',
        ],
        'warning_signs': [
          'Severe pain or persistent vomiting',
        ],
        'when_to_see_doctor': 'Seek prompt evaluation if pain worsens.',
        'evidence': [
          {
            'title': 'Clinical Reference',
            'source_type': 'Medical RAG',
            'source': 'WHO',
            'citation': 'WHO-GI-01',
            'relevance': 'General gastrointestinal guidelines.',
          }
        ],
        'medical_disclaimer': 'This information is for general health guidance and is not a medical diagnosis.',
        'source_mode': 'Medical RAG',
        'requires_professional_review': true,
        'emergency': false,
      };

      final resp = ClinicalResponse.fromJson(json);

      expect(resp.symptomSummary, 'Stomach pain after dinner');
      expect(resp.assessment.summary, 'Symptoms started after food intake.');
      expect(resp.assessment.evidenceBasis, 'Reported timing');
      expect(resp.assessment.uncertainty, contains('insufficient'));
      expect(resp.possibleConditions.length, 1);
      expect(resp.possibleConditions.first.name, 'Gastroenteritis');
      expect(resp.riskLevel, RiskLevel.insufficientInformation);
      expect(resp.whatYouCanDoNow.length, 2);
      expect(resp.warningSigns.length, 1);
      expect(resp.whenToSeeDoctor, contains('prompt evaluation'));
      expect(resp.evidence.length, 1);
      expect(resp.evidence.first.sourceType, 'Medical RAG');
      expect(resp.sourceMode, 'Medical RAG');
      expect(resp.requiresProfessionalReview, true);
      expect(resp.emergency, false);

      final formatted = resp.toFormattedText();
      expect(formatted, contains('SYMPTOM SUMMARY:'));
      expect(formatted, contains('ASSESSMENT:'));
      expect(formatted, contains('POSSIBLE CONDITIONS:'));
      expect(formatted, contains('RISK LEVEL: INSUFFICIENT INFORMATION'));
      expect(formatted, contains('WHAT YOU CAN DO NOW:'));
      expect(formatted, contains('WARNING SIGNS:'));
      expect(formatted, contains('WHEN TO SEE A DOCTOR:'));
      expect(formatted, contains('EVIDENCE / SOURCE:'));
      expect(formatted, contains('MEDICAL DISCLAIMER:'));
    });

    test('ClinicalResponse clamps possible conditions to maximum 3', () {
      final json = {
        'symptom_summary': 'Multiple symptoms',
        'assessment': {'summary': 'Summary', 'evidence_basis': 'Basis', 'uncertainty': 'Uncertainty'},
        'possible_conditions': [
          {'name': 'C1', 'reason': 'R1', 'evidence_status': 'S1'},
          {'name': 'C2', 'reason': 'R2', 'evidence_status': 'S2'},
          {'name': 'C3', 'reason': 'R3', 'evidence_status': 'S3'},
          {'name': 'C4', 'reason': 'R4', 'evidence_status': 'S4'},
        ],
        'risk_level': 'low',
        'what_you_can_do_now': ['Rest'],
        'warning_signs': ['None'],
        'when_to_see_doctor': 'Monitor',
        'evidence': [],
        'source_mode': 'None',
        'requires_professional_review': false,
        'emergency': false,
      };

      final resp = ClinicalResponse.fromJson(json);
      expect(resp.possibleConditions.length, 3);
      expect(resp.possibleConditions[0].name, 'C1');
      expect(resp.possibleConditions[2].name, 'C3');
    });

    test('ClinicalResponse.emergency factory sets riskLevel=emergency and emergency=true', () {
      final resp = ClinicalResponse.emergency(
        query: 'severe chest pain and difficulty breathing',
        matchedTerms: ['severe chest pain', 'difficulty breathing'],
      );

      expect(resp.emergency, true);
      expect(resp.riskLevel, RiskLevel.emergency);
      expect(resp.sourceMode, 'Deterministic Safety Rule');
      expect(resp.whatYouCanDoNow.any((a) => a.contains('108') || a.contains('112')), true);
      expect(resp.evidence.first.sourceType, 'Deterministic Safety Rule');
    });

    test('ClinicalResponse.offlineLexicon factory sets offline medical fields safely', () {
      final resp = ClinicalResponse.offlineLexicon(
        query: 'headache',
        conditionName: 'Tension Headache',
        generalInfo: 'Common primary headache disorder.',
        warningSigns: ['Sudden severe headache', 'Stiff neck'],
        whenToSeekCare: 'Seek medical care if headache is sudden and explosive.',
        source: 'WHO',
        citation: 'lex-h-01',
      );

      expect(resp.sourceMode, 'Offline Medical Lexicon');
      expect(resp.possibleConditions.first.name, 'Tension Headache');
      expect(resp.evidence.first.sourceType, 'Offline Medical Lexicon');
      expect(resp.evidence.first.citation, 'lex-h-01');
      expect(resp.emergency, false);
    });

    test('AiResponse fromJson deserializes structured_response correctly', () {
      final payload = {
        'query': 'I have fever',
        'intent': 'clinical',
        'agent': 'clinical_agent',
        'answer': 'Fever advice',
        'structured_response': {
          'symptom_summary': 'I have fever',
          'assessment': {
            'summary': 'Elevated body temperature.',
            'evidence_basis': 'Self report',
            'uncertainty': 'Cannot determine cause without examination.',
          },
          'possible_conditions': [],
          'risk_level': 'low',
          'what_you_can_do_now': ['Rest and hydrate'],
          'warning_signs': ['High fever over 103F'],
          'when_to_see_doctor': 'See doctor if fever persists over 3 days.',
          'evidence': [],
          'medical_disclaimer': 'Not a medical diagnosis.',
          'source_mode': 'Medical RAG',
          'requires_professional_review': true,
          'emergency': false,
        }
      };

      final aiResp = AiResponse.fromJson(payload);
      expect(aiResp.structuredResponse, isNotNull);
      expect(aiResp.structuredResponse!.symptomSummary, 'I have fever');
      expect(aiResp.structuredResponse!.riskLevel, RiskLevel.low);
    });

    test('AiResponse fromJson handles null structured_response safely for legacy compatibility', () {
      final payload = {
        'query': 'Hello',
        'intent': 'greeting',
        'answer': 'Hello! How can I assist you today?',
      };

      final aiResp = AiResponse.fromJson(payload);
      expect(aiResp.structuredResponse, isNull);
      expect(aiResp.answer, contains('Hello!'));
    });

    test('OfflineResponse contains structuredResponse', () {
      final offlineResp = OfflineResponse.emergency(query: 'chest pain');
      expect(offlineResp.structuredResponse, isNotNull);
      expect(offlineResp.structuredResponse!.riskLevel, RiskLevel.emergency);
      expect(offlineResp.isEmergency, true);
    });
  });
}
