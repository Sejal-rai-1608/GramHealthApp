import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/care_card.dart';
import '../../widgets/language_selector_modal.dart';
import '../../theme/app_colors.dart';

class DoctorSettingsScreen extends StatelessWidget {
  const DoctorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('settings'),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(
            context.tr('settings'),
            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          CareCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.language, color: AppColors.teal, size: 18),
                  ),
                  title: Text(context.tr('select_language'), style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                  subtitle: Text(context.currentLanguage.nativeName, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint, size: 18),
                  onTap: () => showLanguageSelector(context),
                ),
                const Divider(color: AppColors.borderLight, height: 1),
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.teal, size: 18),
                  ),
                  title: Text('Notifications', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                  trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppColors.teal),
                ),
                const Divider(color: AppColors.borderLight, height: 1),
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.security, color: AppColors.teal, size: 18),
                  ),
                  title: Text('Privacy & Security', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint, size: 18),
                  onTap: () {},
                ),
                const Divider(color: AppColors.borderLight, height: 1),
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.help_outline, color: AppColors.teal, size: 18),
                  ),
                  title: Text('Help & Support', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
