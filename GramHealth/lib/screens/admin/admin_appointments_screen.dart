import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/app_language.dart';

/// Consultations grouped by calendar day.
///
/// The backend has no appointments collection, so the appointment view is
/// built from real consultation timestamps rather than invented rows.
class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_schedule'),
      child: RoleAsyncView<List<AdminConsultation>>(
        loader: AdminService.getConsultations,
        builder: (context, items) {
          final grouped = AdminService.appointmentsFromConsultations(items);
          final keys = grouped.keys.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('nav_schedule'),
                subtitle: context.tr('console_pipeline_sub'),
              ),
              if (keys.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(context.tr('console_nothing_scheduled'),
                            style: GoogleFonts.manrope(
                                fontSize: 13, color: AppColors.inkMuted)),
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
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
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
                              Text('${grouped[day]!.length} consultation(s)',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12, color: AppColors.inkFaint)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...grouped[day]!.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: RoleListRow(
                                  initials: c.patientInitials,
                                  title: c.patientName ?? 'Unknown patient',
                                  subtitle:
                                      '${c.type} · ${c.hasDoctor ? (c.doctorName ?? 'Assigned doctor') : 'Waiting for a doctor'}',
                                  trailingWidget: StatusBadge(status: c.status),
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

  String _label(String iso) {
    if (iso == 'Unscheduled') return iso;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}
