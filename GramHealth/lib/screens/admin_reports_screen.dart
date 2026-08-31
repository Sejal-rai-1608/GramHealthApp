import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'System Reports',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports & Analytics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'View performance metrics and download healthcare analytical reports',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Analytics Sheets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  _buildReportTile('Monthly Consultations Report', 'Summary of all video/chat sessions in August 2026', 'PDF'),
                  const Divider(),
                  _buildReportTile('Demographic Patient Intake', 'Distribution of patients across various rural villages', 'XLSX'),
                  const Divider(),
                  _buildReportTile('Medicine Demand Analysis', 'Most requested and out-of-stock medicines list', 'CSV'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick System Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Server Status', '99.9%', Colors.green),
                  _buildStatColumn('API Latency', '124 ms', Colors.teal),
                  _buildStatColumn('Active Sockets', '48', Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(String title, String subtitle, String format) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.leafGreenPale,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.analytics_outlined, color: AppColors.leafGreenDeep),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryBg,
          foregroundColor: AppColors.leafGreenDeep,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('Download $format', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
