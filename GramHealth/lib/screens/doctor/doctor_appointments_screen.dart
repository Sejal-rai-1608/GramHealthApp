import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_language.dart';
import '../../services/consultation_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../widgets/status_badge.dart';

/// A doctor's consultations grouped by calendar day.
///
/// The backend stores no separate appointment entity, so the schedule is
/// derived from real consultation records rather than a placeholder.
class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('appointments'),
      child: RoleAsyncView<List<ConsultationModel>>(
        loader: () => ConsultationService.listDoctorConsultations(limit: 100),
        builder: (context, items) {
          final grouped = _groupByDay(items);
          final keys = grouped.keys.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RoleSectionHeader(
                title: 'Your schedule',
                subtitle: 'Consultations grouped by the day they were raised.',
              ),
              if (keys.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No consultations yet. Requests will appear here.',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...keys.map((day) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.pill),
                                ),
                                child: Text(
                                  _label(day),
                                  style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.tealDeep),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${grouped[day]!.length} consultation(s)',
                                style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.inkFaint),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...grouped[day]!.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: RoleListRow(
                                  initials: _initials(c.patientName),
                                  title: c.patientName ?? 'Unknown patient',
                                  subtitle: [
                                    c.type,
                                    if (c.symptoms != null &&
                                        c.symptoms!.isNotEmpty)
                                      c.symptoms!,
                                  ].join(' · '),
                                  trailingWidget:
                                      StatusBadge(status: c.status),
                                ),
                              )),
                        ],
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  static Map<String, List<ConsultationModel>> _groupByDay(
      List<ConsultationModel> items) {
    final grouped = <String, List<ConsultationModel>>{};
    for (final c in items) {
      final d = c.createdAt;
      final key = d == null
          ? 'Unscheduled'
          : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(c);
    }
    final sorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sorted) k: grouped[k]!};
  }

  static String _label(String iso) {
    if (iso == 'Unscheduled') return iso;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  static String _initials(String? name) {
    final n = (name ?? '?').trim();
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
