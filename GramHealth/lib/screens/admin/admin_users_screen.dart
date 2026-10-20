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

/// All registered accounts, straight from `GET /api/users`.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _role = 'ALL';
  String _query = '';

  static final _roles = [
    ('ALL', 'All roles'),
    ('PATIENT', 'Patients'),
    ('DOCTOR', 'Doctors'),
    ('ADMIN', 'Admins'),
    ('PHARMACY', 'Pharmacy'),
    ('ASHA', 'ASHA'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_users'),
      child: RoleAsyncView<List<AdminUser>>(
        loader: () => AdminService.getUsers(
          role: _role == 'ALL' ? null : _role,
          search: _query.isEmpty ? null : _query,
        ),
        isEmpty: false,
        builder: (context, users) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_registered_accounts'),
                subtitle: context.tr('console_registered_accounts_sub'),
              ),
              Row(
                children: [
                  Expanded(
                    child: CareSearchField(
                      controller: _searchCtrl,
                      hint: context.tr('console_search_name'),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final r = _roles[i];
                    final selected = _role == r.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _role = r.$1),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.mint : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(
                            color: selected ? AppColors.tealPale : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          r.$2,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.tealDeep : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (users.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.person_search_rounded,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _query.isEmpty
                              ? 'No accounts registered yet.'
                              : 'No accounts match "$_query".',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...users.map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: u.initials,
                        title: u.name,
                        subtitle: '${u.email.isEmpty ? 'No email' : u.email} · ${u.phone}',
                        trailingWidget: _roleChip(u.role),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _roleChip(String role) {
    final color = switch (role) {
      'ADMIN' => AppColors.coralDeep,
      'DOCTOR' => AppColors.tealDeep,
      'PHARMACY' => AppColors.amberDeep,
      'ASHA' => AppColors.tealBright,
      _ => AppColors.inkSoft,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        role,
        style: GoogleFonts.manrope(
            fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
