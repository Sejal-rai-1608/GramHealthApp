import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../widgets/search_bar.dart';
import '../../l10n/app_language.dart';

/// All patients, straight from `GET /api/patients`.
class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
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
      title: context.tr('nav_patients'),
      child: RoleAsyncView<List<AdminPatient>>(
        loader: AdminService.getPatients,
        builder: (context, patients) {
          final filtered = _query.isEmpty
              ? patients
              : patients
                  .where((p) =>
                      p.name.toLowerCase().contains(_query.toLowerCase()) ||
                      p.phone.contains(_query) ||
                      p.email.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_patients_record'),
                subtitle: '${patients.length} patient profile(s) on record.',
              ),
              CareSearchField(
                controller: _searchCtrl,
                hint: context.tr('console_search_patient'),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.personal_injury_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          patients.isEmpty
                              ? 'No patients registered yet.'
                              : 'No patients match "$_query".',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: p.initials,
                        title: p.name,
                        subtitle: '${p.phone} · ${p.location}',
                        trailing: p.gender == null || p.gender!.isEmpty
                            ? null
                            : p.gender,
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
