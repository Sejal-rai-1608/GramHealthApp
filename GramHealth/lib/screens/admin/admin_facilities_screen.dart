import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../l10n/app_language.dart';

/// Practice locations derived from the hospitals doctors actually registered
/// against. The backend has no facilities collection, so this view is built
/// from real doctor records rather than a separate, invented table.
class AdminFacilitiesScreen extends StatelessWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_facilities'),
      child: RoleAsyncView<List<AdminDoctor>>(
        loader: AdminService.getDoctors,
        builder: (context, doctors) {
          final facilities = AdminService.facilitiesFromDoctors(doctors);
          final named = facilities.where((f) => f.name != 'Practice not registered').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_practice_locations'),
                subtitle:
                    '$named named location(s) derived from doctor registrations.',
              ),
              if (facilities.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_rounded,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('No doctors registered yet.',
                            style: GoogleFonts.manrope(
                                fontSize: 13, color: AppColors.inkMuted)),
                      ),
                    ],
                  ),
                )
              else
                ...facilities.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CareCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                              child: const Icon(Icons.apartment_rounded,
                                  size: 20, color: AppColors.teal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    f.name,
                                    style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    f.specialties,
                                    style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                        height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.groundAlt,
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                '${f.doctorCount} doctor(s)',
                                style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
