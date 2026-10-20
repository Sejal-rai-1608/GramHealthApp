import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../widgets/search_bar.dart';
import '../../l10n/app_language.dart';

/// All doctors, straight from `GET /api/doctors`.
class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_doctors'),
      child: RoleAsyncView<List<AdminDoctor>>(
        loader: AdminService.getDoctors,
        builder: (context, doctors) {
          final filtered = _query.isEmpty
              ? doctors
              : doctors
                  .where((d) =>
                      d.name.toLowerCase().contains(_query.toLowerCase()) ||
                      d.displaySpecialization
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      (d.hospitalName ?? '')
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
                  .toList();

          final onboarded = doctors.where((d) => d.isOnboarded).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_doctors_on_platform'),
                subtitle: '$onboarded of ${doctors.length} have a complete profile.',
              ),
              CareSearchField(
                controller: _searchCtrl,
                hint: context.tr('console_search_doctor'),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          doctors.isEmpty
                              ? 'No doctors registered yet.'
                              : 'No doctors match "$_query".',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: d.initials,
                        title: d.name,
                        subtitle: [
                          d.displaySpecialization,
                          if (d.hospitalName != null && d.hospitalName!.isNotEmpty)
                            d.hospitalName!,
                          d.phone,
                        ].join(' · '),
                        trailingWidget: d.isOnboarded
                            ? _pill('Verified profile', AppColors.tealDeep, AppColors.mint)
                            : _pill('Onboarding pending', AppColors.amberDeep,
                                AppColors.amberChipBg),
                        onTap: () => context.go('/doctor-details/${d.id}'),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
            fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
