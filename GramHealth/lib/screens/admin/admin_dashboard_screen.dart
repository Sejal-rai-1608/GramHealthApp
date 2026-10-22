import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../theme/app_colors.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService.getSystemStats();
  }

  @override
  Widget build(BuildContext context) {
    final title = context.tr('admin_dashboard');

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
            FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(Icons.group, 'Total Users', '—'),
                      _buildStatCard(Icons.medical_services, 'Doctors', '—'),
                      _buildStatCard(Icons.people_alt, 'Patients', '—'),
                      _buildStatCard(Icons.local_hospital, 'Facilities', '—'),
                      _buildStatCard(Icons.local_pharmacy, 'Pharmacies', '—'),
                      _buildStatCard(Icons.calendar_month, 'Appointments', '—'),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState('Failed to load stats');
                }

                final stats = snapshot.data ?? {};
                final kpiData = [
                  {'icon': Icons.group, 'label': 'Total Users', 'value': _formatNumber(stats['totalUsers'] ?? 0)},
                  {'icon': Icons.medical_services, 'label': 'Doctors', 'value': _formatNumber(stats['totalDoctors'] ?? 0)},
                  {'icon': Icons.people_alt, 'label': 'Patients', 'value': _formatNumber(stats['totalPatients'] ?? 0)},
                  {'icon': Icons.local_hospital, 'label': 'Facilities', 'value': _formatNumber(stats['totalFacilities'] ?? 0)},
                  {'icon': Icons.local_pharmacy, 'label': 'Pharmacies', 'value': _formatNumber(stats['totalPharmacies'] ?? 0)},
                  {'icon': Icons.calendar_month, 'label': 'Appointments', 'value': _formatNumber(stats['totalConsultations'] ?? 0)},
                ];

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: kpiData.map((d) => StatCard(
                    icon: d['icon'] as IconData,
                    label: d['label'] as String,
                    value: d['value'] as String,
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent System Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: _buildActivitySection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return StatCard(
      icon: icon,
      label: label,
      value: value,
    );
  }

  Widget _buildActivitySection() {
    return Column(
      children: [
        _buildActivityRow(
          'System started',
          'Just now',
          'Active',
        ),
      ],
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

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}