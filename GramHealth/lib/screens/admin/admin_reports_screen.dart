import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../l10n/app_language.dart';

/// Platform reporting built entirely from live collections.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_reports'),
      child: RoleAsyncView<AdminOverview>(
        loader: AdminService.getOverview,
        builder: (context, data) {
          final byType = <String, int>{};
          for (final c in data.recent) {
            byType[c.type] = (byType[c.type] ?? 0) + 1;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_reports'),
                subtitle: context.tr('console_overview_sub'),
              ),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_reach'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 14),
                    _line('Registered users', '${data.users}'),
                    _line('Patient profiles', '${data.patients}'),
                    _line('Doctor profiles', '${data.doctors}'),
                    _line('Doctor profiles complete', '${data.onboardedDoctors}'),
                    _line('Pharmacy outlets', '${data.pharmacies}'),
                    _line('ASHA workers', '${data.ashaWorkers}'),
                    _line('Consultations', '${data.consultations}'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_outcomes'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 14),
                    _line('Pending', '${data.pending}'),
                    _line('Active', '${data.active}'),
                    _line('Completed', '${data.completed}'),
                    _line('Cancelled', '${data.cancelled}'),
                    const SizedBox(height: 10),
                    _completionRate(context, data),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_recent_types'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 12),
                    if (byType.isEmpty)
                      Text('No consultations to break down yet.',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted))
                    else
                      ...byType.entries.map((e) => _line(e.key, '${e.value}')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.inkSoft, height: 1.35)),
          ),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _completionRate(BuildContext context, AdminOverview data) {
    final decided = data.completed + data.cancelled;
    final rate = decided == 0 ? 0.0 : (data.completed / decided) * 100;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.tealPale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('console_completion_rate'),
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealDeep)),
                const SizedBox(height: 2),
                Text(context.tr('console_of_decided'),
                    style: GoogleFonts.manrope(
                        fontSize: 11, color: AppColors.inkMuted)),
              ],
            ),
          ),
          Text('${rate.toStringAsFixed(0)}%',
              style: GoogleFonts.manrope(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.tealDeep)),
        ],
      ),
    );
  }
}
