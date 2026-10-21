import 'package:flutter/material.dart';
import '../models/clinical_response.dart';
import '../theme/app_colors.dart';

class StructuredClinicalResponseCard extends StatelessWidget {
  final ClinicalResponse response;
  final String? sourceLabel;
  final bool isChatBubble;

  const StructuredClinicalResponseCard({
    super.key,
    required this.response,
    this.sourceLabel,
    this.isChatBubble = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: response.emergency
              ? const Color(0xFFFFCDD2)
              : AppColors.primaryAccent.withValues(alpha: 0.2),
          width: response.emergency ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isChatBubble ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── TOP: Source Mode & Emergency Banner ──────────────────────────────
          if (sourceLabel != null || response.sourceMode.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sourceLabel?.contains('Offline') ?? false ? Icons.cloud_off : Icons.cloud_done,
                        size: 11,
                        color: AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sourceLabel ?? response.sourceMode,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRiskBadge(response.riskLevel),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── 🚨 EMERGENCY BANNER (If emergency, rendered at TOP) ─────────────
          if (response.emergency || response.riskLevel == RiskLevel.emergency) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency, color: Color(0xFFC62828), size: 20),
                      SizedBox(width: 6),
                      Text(
                        'EMERGENCY ALERT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC62828),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'These symptoms may require urgent medical attention. Call local emergency services (108 / 112) or go to the nearest emergency department immediately.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB71C1C),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── 1. SYMPTOM SUMMARY ──────────────────────────────────────────────
          _buildSectionHeader('SYMPTOM SUMMARY', Icons.person_search_outlined),
          const SizedBox(height: 4),
          Text(
            response.symptomSummary,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          const Divider(height: 24, thickness: 0.8),

          // ── 2. ASSESSMENT ───────────────────────────────────────────────────
          _buildSectionHeader('ASSESSMENT', Icons.assignment_outlined),
          const SizedBox(height: 4),
          Text(
            response.assessment.summary,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          _buildSubItem('Evidence basis', response.assessment.evidenceBasis, Icons.fact_check_outlined),
          const SizedBox(height: 4),
          _buildSubItem('Uncertainty', response.assessment.uncertainty, Icons.help_outline_rounded),
          const Divider(height: 24, thickness: 0.8),

          // ── 3. POSSIBLE CONDITIONS ─────────────────────────────────────────
          _buildSectionHeader('POSSIBLE CONDITIONS', Icons.medical_services_outlined),
          const SizedBox(height: 6),
          if (response.possibleConditions.isEmpty)
            const Text(
              'No specific condition can be identified safely from the available information.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            )
          else
            ...response.possibleConditions.map((cond) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.leafGreenPale),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 7, color: AppColors.primaryAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cond.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Why considered: ${cond.reason}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMedium,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Evidence status: ${cond.evidenceStatus}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                )),
          const Divider(height: 24, thickness: 0.8),

          // ── 4. WHAT YOU CAN DO NOW ──────────────────────────────────────────
          _buildSectionHeader('WHAT YOU CAN DO NOW', Icons.task_alt_outlined),
          const SizedBox(height: 6),
          ...response.whatYouCanDoNow.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.arrow_right, size: 16, color: AppColors.primaryAccent),
                    ),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24, thickness: 0.8),

          // ── 5. WARNING SIGNS ────────────────────────────────────────────────
          _buildSectionHeader('WARNING SIGNS', Icons.warning_amber_rounded, color: const Color(0xFFD32F2F)),
          const SizedBox(height: 6),
          ...response.warningSigns.map((sign) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFD32F2F)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sign,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC62828),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24, thickness: 0.8),

          // ── 6. WHEN TO SEE A DOCTOR ─────────────────────────────────────────
          _buildSectionHeader('WHEN TO SEE A DOCTOR', Icons.local_hospital_outlined),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.leafBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.leafGreenPale),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety_outlined, size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.whenToSeeDoctor,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 0.8),

          // ── 7. EVIDENCE / SOURCE ───────────────────────────────────────────
          _buildSectionHeader('EVIDENCE / SOURCE', Icons.library_books_outlined),
          const SizedBox(height: 6),
          ...response.evidence.map((ev) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.bookmark_border, size: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 11, color: AppColors.textDark, height: 1.3),
                          children: [
                            TextSpan(
                              text: '[${ev.sourceType}] ',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryAccent),
                            ),
                            TextSpan(
                              text: '${ev.title} (${ev.source})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (ev.citation.isNotEmpty)
                              TextSpan(
                                text: ' [${ev.citation}]',
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                            if (ev.relevance.isNotEmpty)
                              TextSpan(
                                text: '\n${ev.relevance}',
                                style: const TextStyle(color: AppColors.textMedium, fontSize: 10.5),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20, thickness: 0.8),

          // ── 8. MEDICAL DISCLAIMER ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    response.medicalDisclaimer,
                    style: const TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    final headerColor = color ?? AppColors.textDark;
    return Row(
      children: [
        Icon(icon, size: 14, color: headerColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: headerColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 12, color: AppColors.textMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMedium, height: 1.35),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskBadge(RiskLevel risk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: risk.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: risk.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(risk.icon, size: 11, color: risk.color),
          const SizedBox(width: 4),
          Text(
            risk.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: risk.color,
            ),
          ),
        ],
      ),
    );
  }
}
