import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';

class DoctorPrescriptionsScreen extends StatelessWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('prescriptions'),
      child: ListView(
        children: [
          Text(
            context.tr('prescriptions'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          _buildPrescriptionItem(
            patientName: 'Ramesh Patel',
            date: '27 Aug 2026',
            medicinesCount: 3,
            diagnosis: 'Acute Bronchitis',
          ),
          _buildPrescriptionItem(
            patientName: 'Kamla Bai',
            date: '26 Aug 2026',
            medicinesCount: 2,
            diagnosis: 'Osteoarthritis Flare',
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem({
    required String patientName,
    required String date,
    required int medicinesCount,
    required String diagnosis,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.leafGreenPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.leafGreenPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text('Diagnosis: $diagnosis', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text('$medicinesCount medicines prescribed • $date', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: AppColors.leafGreenPrimary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
