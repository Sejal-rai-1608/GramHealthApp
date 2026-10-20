import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/app_language.dart';

/// Admin console home.
///
/// Every number on this screen is derived from a live collection on the
/// Render backend — there are no placeholder metrics.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_dashboard'),
      child: RoleAsyncView<AdminOverview>(
        loader: AdminService.getOverview,
        builder: (context, data) {
          final maxStatus = [
            data.pending,
            data.active,
            data.completed,
            data.cancelled,
          ].reduce((a, b) => a > b ? a : b);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_overview'),
                subtitle: context.tr('console_overview_sub'),
              ),

              // ── Primary metrics ────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  final tileWidth =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric(context, context.tr('console_total_users'), '${data.users}',
                          Icons.people_alt_rounded, AppColors.teal,
                          context.tr('console_total_users_sub'), tileWidth, '/admin/users'),
                      _metric(context, context.tr('console_patients'), '${data.patients}',
                          Icons.personal_injury_rounded, AppColors.tealBright,
                          context.tr('console_patients_sub'), tileWidth, '/admin/patients'),
                      _metric(context, context.tr('console_doctors'), '${data.doctors}',
                          Icons.medical_services_rounded, AppColors.amberDeep,
                          '${data.onboardedDoctors} profile(s) complete',
                          tileWidth, '/admin/doctors'),
                      _metric(context, context.tr('console_pharmacies'), '${data.pharmacies}',
                          Icons.local_pharmacy_rounded, AppColors.coralDeep,
                          context.tr('console_pharmacies_sub'), tileWidth, '/admin/pharmacies'),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Consultation pipeline ──────────────────────────────────
              RoleSectionHeader(
                title: context.tr('console_pipeline'),
                subtitle: context.tr('console_pipeline_sub'),
              ),
              CareCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(context.tr('console_total_consultations'),
                              style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkSoft)),
                        ),
                        Text('${data.consultations}',
                            style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _statusBar(context, 'Pending', data.pending, maxStatus, AppColors.amber),
                    const SizedBox(height: 10),
                    _statusBar(context, 'Active', data.active, maxStatus, AppColors.teal),
                    const SizedBox(height: 10),
                    _statusBar(context, 'Completed', data.completed, maxStatus, AppColors.tealBright),
                    const SizedBox(height: 10),
                    _statusBar(context, 'Cancelled', data.cancelled, maxStatus, AppColors.coral),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/admin/consultations'),
                            icon: const Icon(Icons.list_alt_rounded, size: 18),
                            label: Text(context.tr('console_view_all')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.tealDeep,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: AppColors.tealPale),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/admin/appointments'),
                            icon: const Icon(Icons.calendar_month_rounded, size: 18),
                            label: Text(context.tr('console_by_date')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.tealDeep,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: AppColors.tealPale),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Recent activity ────────────────────────────────────────
              RoleSectionHeader(
                title: context.tr('console_recent'),
                subtitle: context.tr('console_recent_sub'),
                trailing: TextButton(
                  onPressed: () => context.go('/admin/consultations'),
                  child: Text('See all',
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal)),
                ),
              ),
              if (data.recent.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(context.tr('console_no_consultations_yet'),
                            style: GoogleFonts.manrope(
                                fontSize: 13, color: AppColors.inkMuted)),
                      ),
                    ],
                  ),
                )
              else
                ...data.recent.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: c.patientInitials,
                        title: c.patientName ?? 'Unknown patient',
                        subtitle:
                            '${c.type} · ${c.hasDoctor ? (c.doctorName ?? 'Assigned doctor') : 'Waiting for a doctor'}'
                            '${c.symptoms != null && c.symptoms!.isNotEmpty ? ' · ${c.symptoms}' : ''}',
                        trailingWidget: StatusBadge(status: c.status),
                        onTap: () => context.go('/admin/consultations'),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color accent,
    String caption,
    double width,
    String route,
  ) {
    return SizedBox(
      width: width,
      child: RoleMetricTile(
        label: label,
        value: value,
        icon: icon,
        accent: accent,
        caption: caption,
        onTap: () => context.go(route),
      ),
    );
  }

  Widget _statusBar(
    BuildContext context,
    String label,
    int count,
    int max,
    Color color,
  ) {
    final ratio = max == 0 ? 0.0 : count / max;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceDim,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text('$count',
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ),
      ],
    );
  }
}
