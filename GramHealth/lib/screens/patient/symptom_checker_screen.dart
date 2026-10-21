import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/structured_clinical_response_card.dart';
import '../../models/clinical_response.dart';
import '../../services/ai_service.dart';
import '../../services/offline_ai_service.dart';
import '../../repositories/offline_medical_repository.dart';

class SymptomResult {
  final String condition;
  final String advice;
  final String action;
  final String source;
  SymptomResult({required this.condition, required this.advice, required this.action, this.source = 'Online AI'});
}

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _symptoms = const ['Fever', 'Headache', 'Cough', 'Chest Pain', 'Fatigue', 'Stomach Ache', 'Nausea'];
  final _selected = <String>{};
  bool _isAnalyzing = false;
  bool _isRecording = false;
  ClinicalResponse? _clinicalResult;
  String? _resultSource;
  SymptomResult? _result;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final symptomsToAnalyze = _selected.toList();
    if (_otherCtrl.text.trim().isNotEmpty) symptomsToAnalyze.add(_otherCtrl.text.trim());
    if (symptomsToAnalyze.isEmpty) return;

    final combinedQuery = symptomsToAnalyze.join(', ');

    if (OfflineAiService.instance.isEmergency(combinedQuery)) {
      if (mounted) {
        final er = OfflineAiService.instance.buildEmergencyResponse(combinedQuery);
        setState(() {
          _isAnalyzing = false;
          _clinicalResult = er.structuredResponse ?? ClinicalResponse.emergency(query: combinedQuery);
          _resultSource = 'Emergency Triage';
          _result = SymptomResult(
            condition: 'Emergency Indicator Detected',
            advice: er.text,
            action: 'Please contact local emergency services (108 / 112) or go to the nearest emergency department immediately.',
            source: 'Emergency Triage',
          );
        });
      }
      return;
    }

    setState(() { _isAnalyzing = true; _result = null; _clinicalResult = null; });

    try {
      final aiResponse = await AiService.query("I have the following symptoms: $combinedQuery. What could this mean?").timeout(const Duration(seconds: 45));
      if (mounted) {
        String conditionText = 'Symptom Assessment';
        if (aiResponse.structuredResponse?.primaryCondition != null && aiResponse.structuredResponse!.primaryCondition!.isNotEmpty) {
          conditionText = aiResponse.structuredResponse!.primaryCondition!;
        } else if (aiResponse.answer != null && aiResponse.answer!.contains('Condition:')) {
          final m = RegExp(r'Condition:\s*([^\n]+)').firstMatch(aiResponse.answer!);
          if (m != null) conditionText = m.group(1)!.trim();
        } else if (combinedQuery.toLowerCase().contains('pet') || combinedQuery.toLowerCase().contains('stomach') || combinedQuery.toLowerCase().contains('infection')) {
          conditionText = 'Stomach Infection / Gastroenteritis';
        } else if (aiResponse.intent != null && !['symptom_analysis', 'general_health', 'offline_medical'].contains(aiResponse.intent)) {
          conditionText = aiResponse.intent!;
        }
        setState(() {
          _isAnalyzing = false;
          _clinicalResult = aiResponse.structuredResponse;
          _resultSource = 'Online AI';
          _result = SymptomResult(
            condition: conditionText,
            advice: aiResponse.answer ?? 'No detailed advice available.',
            action: (aiResponse.requiresProfessionalReview == true || aiResponse.urgency == 'emergency')
                ? 'Please consult a doctor if symptoms persist or worsen.'
                : 'Monitor your symptoms and maintain hydration.',
            source: 'Online AI',
          );
        });
      }
    } catch (e) {
      if (AiService.debugForceOnlineAi) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _result = SymptomResult(condition: 'Online AI Request Error', advice: e.toString(), action: 'Please check backend connectivity or try again.', source: 'Online AI (Error)');
          });
        }
        return;
      }
      await OfflineAiService.instance.initialise();
      final stream = OfflineAiService.instance.queryOffline("I have symptoms: $combinedQuery");
      final buf = StringBuffer();
      await for (final t in stream) {
        buf.write(t);
      }
      final offlineText = buf.toString().trim();
      final repo = OfflineMedicalRepository();
      await repo.initialise();
      final fallback = await repo.buildSymptomCheckerContext(symptomsToAnalyze);
      final advice = offlineText.isNotEmpty ? offlineText : fallback;
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _clinicalResult = null;
          _resultSource = 'Offline AI';
          _result = SymptomResult(
            condition: 'These symptoms can occur with several conditions. The offline assistant cannot determine the exact cause.',
            advice: advice,
            action: 'Please seek professional medical evaluation for an accurate diagnosis.',
            source: 'Offline AI',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('symptom_checker_title'),
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text('Select what you feel — get clear, safe next steps.',
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('symptom_question'),
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symptoms.map((s) {
                      final sel = _selected.contains(s);
                      return CareChip(
                        label: s,
                        selected: sel,
                        onTap: () => setState(() => sel ? _selected.remove(s) : _selected.add(s)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.groundAlt,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _otherCtrl,
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                            decoration: InputDecoration(
                              hintText: context.tr('other_symptoms'),
                              hintStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkFaint),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _isRecording = !_isRecording),
                            child: AnimatedContainer(
                              duration: AppMotion.state,
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isRecording ? AppColors.teal : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _isRecording ? AppColors.teal : AppColors.borderLight),
                              ),
                              child: Icon(Icons.mic_rounded, size: 16, color: _isRecording ? AppColors.surface : AppColors.inkMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(context.tr('listening'),
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    title: _isAnalyzing ? context.tr('analyzing') : context.tr('analyze_symptoms'),
                    onPress: _isAnalyzing ? () {} : _analyze,
                    width: double.infinity,
                    loading: _isAnalyzing,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.inkFaint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Not a diagnosis — guidance only. See a clinician for personal advice.',
                            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkFaint, height: 1.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isAnalyzing) ...[
              const SizedBox(height: 20),
              CareCard(
                child: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(context.tr('ai_processing'),
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                    ),
                  ],
                ),
              ),
            ],
            if ((_clinicalResult != null || _result != null) && !_isAnalyzing) ...[
              const SizedBox(height: 16),
              if (_clinicalResult != null)
                StructuredClinicalResponseCard(response: _clinicalResult!, sourceLabel: _resultSource ?? 'Online AI')
              else
                CareCard(
                  borderColor: AppColors.tealPale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.monitor_heart_rounded, size: 16, color: AppColors.teal),
                          ),
                          const SizedBox(width: 10),
                          Text(context.tr('analysis_result'),
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(6)),
                            child: Text(_result!.source, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkMuted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _row(context.tr('possible_condition'), _result!.condition, large: true),
                      const SizedBox(height: 12),
                      _row(context.tr('advice'), _result!.advice),
                      const SizedBox(height: 12),
                      _row(context.tr('suggested_action'), _result!.action),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_outlined, size: 14, color: AppColors.inkMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(context.tr('medical_disclaimer'),
                                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool large = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkFaint, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontSize: large ? 15 : 13, fontWeight: large ? FontWeight.w700 : FontWeight.w500, color: AppColors.ink, height: 1.5)),
      ],
    );
  }
}
