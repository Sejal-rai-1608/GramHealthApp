import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../theme/app_colors.dart';

class DoctorConsultationsScreen extends StatelessWidget {
  const DoctorConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('consultations'),
      child: ListView(
        children: [
          Text(
            context.tr('consultations'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          _buildConsultationCard(
            patientName: 'Ramesh Patel',
            type: 'Video Call',
            date: 'Today, 10:30 AM',
            status: 'Completed',
            symptoms: 'Fever, cough for 3 days',
          ),
          _buildConsultationCard(
            patientName: 'Anjali Verma',
            type: 'Audio Call',
            date: 'Today, 11:15 AM',
            status: 'Scheduled',
            symptoms: 'Headache & dizziness',
          ),
          _buildConsultationCard(
            patientName: 'Kamla Bai',
            type: 'Video Call',
            date: 'Yesterday, 04:00 PM',
            status: 'Completed',
            symptoms: 'Follow-up on joint medication',
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard({
    required String patientName,
    required String type,
    required String date,
    required String status,
    required String symptoms,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.videocam_outlined, size: 16, color: AppColors.leafGreenPrimary),
                const SizedBox(width: 6),
                Text(type, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Symptoms: $symptoms',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
