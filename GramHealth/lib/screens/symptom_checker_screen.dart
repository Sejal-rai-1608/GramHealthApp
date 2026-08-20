import 'package:flutter/material.dart';
import '../data/mock_api.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _symptoms = ['Fever', 'Headache', 'Cough', 'Chest Pain', 'Fatigue', 'Stomach Ache', 'Nausea'];
  final _selected = <String>{};
  bool _isAnalyzing = false;
  bool _isRecording = false;
  SymptomResult? _result;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_selected.isEmpty) return;
    setState(() { _isAnalyzing = true; _result = null; });
    final result = await SymptomService.checkSymptoms(_selected.toList());
    if (mounted) setState(() { _isAnalyzing = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('symptom_checker_title'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('symptom_checker_subtitle'),
              style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('symptom_question'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),

                  // Symptom chips
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _symptoms.map((s) {
                      final isSelected = _selected.contains(s);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) _selected.remove(s); else _selected.add(s);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryAccent : AppColors.secondaryBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryAccent : const Color(0x0D000000),
                            ),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.textDark : const Color(0xFF666666),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Text input with mic
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _otherCtrl,
                            decoration: InputDecoration(
                              hintText: context.tr('other_symptoms'),
                              hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isRecording = !_isRecording),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isRecording)
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryAccent.withValues(alpha: 0.4),
                                  ),
                                ),
                              Icon(Icons.mic,
                                  size: 20,
                                  color: _isRecording ? AppColors.primaryAccent : const Color(0xFF666666)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        context.tr('listening'),
                        style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  PrimaryButton(
                    title: _isAnalyzing ? context.tr('analyzing') : context.tr('analyze_symptoms'),
                    onPress: _analyze,
                    width: double.infinity,
                  ),
                ],
              ),
            ),

            // Loading state
            if (_isAnalyzing) ...[
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.memory, size: 40, color: AppColors.primaryAccent),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('ai_processing'),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
            ],

            // Result card
            if (_result != null && !_isAnalyzing) ...[
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 30, end: 0),
                duration: const Duration(milliseconds: 500),
                builder: (_, val, child) => Transform.translate(offset: Offset(0, val), child: child),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.primaryAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monitor_heart_outlined, size: 24, color: AppColors.primaryAccent),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('analysis_result'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _resultRow(context.tr('possible_condition'), _result!.condition, large: true),
                      const SizedBox(height: 12),
                      _resultRow(context.tr('advice'), _result!.advice),
                      const SizedBox(height: 12),
                      _resultRow(context.tr('suggested_action'), _result!.action),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFF999999)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                context.tr('medical_disclaimer'),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool large = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: large ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.textDark,
              height: 1.4,
            )),
      ],
    );
  }
}
