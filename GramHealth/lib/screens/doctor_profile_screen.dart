import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('profile'),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.leafGreenPale,
                  child: Icon(Icons.person, size: 50, color: AppColors.leafGreenPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dr. Rajesh Sharma',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'General Physician • MBBS, MD',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.badge_outlined, 'Registration No', 'MCI-884920'),
                const Divider(),
                _buildInfoRow(Icons.local_hospital_outlined, 'Hospital / PHC', 'District Health Center'),
                const Divider(),
                _buildInfoRow(Icons.email_outlined, 'Email', 'dr.rajesh@gramhealth.org'),
                const Divider(),
                _buildInfoRow(Icons.phone_outlined, 'Phone', '+91 98765 43210'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.leafGreenPrimary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
        ],
      ),
    );
  }
}
