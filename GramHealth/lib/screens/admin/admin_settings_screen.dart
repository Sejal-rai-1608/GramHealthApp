import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_config.dart';
import '../../l10n/app_language.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/language_selector_modal.dart';
import '../../widgets/role_async_view.dart';

/// Admin console settings. All values are real: the session, the live backend
/// host, and the active language.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_settings'),
      child: RoleAsyncView<Map<String, dynamic>?>(
        loader: AuthService.getUser,
        builder: (context, user) {
          final lang = LanguageController.instance.currentLanguage.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('nav_settings'),
                subtitle: context.tr('console_overview_sub'),
              ),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_signed_in_as'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 12),
                    _row(Icons.badge_outlined, 'Name',
                        (user?['name'] ?? '—').toString()),
                    _row(Icons.mail_outline_rounded, 'Email',
                        (user?['email'] ?? '—').toString()),
                    _row(Icons.phone_outlined, 'Phone',
                        (user?['phone'] ?? '—').toString()),
                    _row(Icons.shield_outlined, 'Role',
                        (user?['role'] ?? 'ADMIN').toString()),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_preferences'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      onTap: () => showLanguageSelector(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.language_rounded,
                                size: 20, color: AppColors.teal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(context.tr('console_language'),
                                      style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink)),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.nativeName,
                                    style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 20, color: AppColors.inkFaint),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_connection'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 12),
                    _row(Icons.cloud_outlined, 'Backend', AppConfig.baseUrl),
                    _row(Icons.storage_outlined, 'Environment',
                        AppConfig.useProduction ? 'Production' : 'Development'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    AuthGuard.onLogout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(context.tr('console_sign_out')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergency,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.emergencyPale),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.inkFaint),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.inkMuted, height: 1.4)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
