import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/stat_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../theme/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.tr('admin_dashboard');
    final kpiData = [
      {'icon': Icons.group, 'label': 'Total Users', 'value': '1,420'},
      {'icon': Icons.medical_services, 'label': 'Doctors', 'value': '48'},
      {'icon': Icons.people_alt, 'label': 'Patients', 'value': '1,372'},
      {'icon': Icons.local_hospital, 'label': 'Facilities', 'value': '12'},
      {'icon': Icons.local_pharmacy, 'label': 'Pharmacies', 'value': '18'},
      {'icon': Icons.calendar_month, 'label': 'Appointments', 'value': '320'},
    ];

    return DashboardLayout(
      title: title,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'GramHealth Telemedicine & Rural Healthcare Portal',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: kpiData.map((d) => StatCard(
                icon: d['icon'] as IconData,
                label: d['label'] as String,
                value: d['value'] as String,
              )).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent System Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActivityRow('Dr. Sharma completed video consultation with Ramesh Patel', '5 mins ago', 'Completed'),
                  const Divider(),
                  _buildActivityRow('New patient registered from Sonkatch Village', '20 mins ago', 'Active'),
                  const Divider(),
                  _buildActivityRow('Emergency SOS trigger in North Zone PHC', '1 hour ago', 'Resolved'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String description, String time, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.leafGreenPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}
