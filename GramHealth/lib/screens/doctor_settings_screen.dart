import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_selector_modal.dart';
import '../theme/app_colors.dart';

class DoctorSettingsScreen extends StatelessWidget {
  const DoctorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('settings'),
      child: ListView(
        children: [
          Text(
            context.tr('settings'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.leafGreenPrimary),
                  title: Text(context.tr('select_language')),
                  subtitle: Text(context.currentLanguage.nativeName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLanguageSelector(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.leafGreenPrimary),
                  title: const Text('Notifications'),
                  trailing: Switch(value: true, onChanged: (v) {}),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.security, color: AppColors.leafGreenPrimary),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.leafGreenPrimary),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
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
