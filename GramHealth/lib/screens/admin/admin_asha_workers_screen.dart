import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../l10n/app_language.dart';

/// ASHA workers, from the admin-only `GET /api/asha-workers` endpoint.
class AdminAshaWorkersScreen extends StatelessWidget {
  const AdminAshaWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_asha_workers'),
      child: RoleAsyncView<List<AdminAshaWorker>>(
        loader: AdminService.getAshaWorkers,
        builder: (context, items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_asha_workers'),
                subtitle: '${items.length} ASHA worker(s) registered.',
              ),
              if (items.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.volunteer_activism_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('No ASHA workers registered yet.',
                            style: GoogleFonts.manrope(
                                fontSize: 13, color: AppColors.inkMuted)),
                      ),
                    ],
                  ),
                )
              else
                ...items.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: w.initials,
                        title: w.name,
                        subtitle: '${w.phone} · ${w.location}',
                        trailing: w.email.isEmpty ? null : w.email,
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
