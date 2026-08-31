import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';

class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('patients'),
      child: ListView(
        children: [
          Text(
            context.tr('patients'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          _buildPatientCard(
            name: 'Ramesh Patel',
            age: '45 yrs',
            village: 'Gram Sonkatch',
            condition: 'Hypertension',
            lastVisit: '2 days ago',
          ),
          _buildPatientCard(
            name: 'Sunita Sharma',
            age: '38 yrs',
            village: 'Gram Pipaliya',
            condition: 'Type 2 Diabetes',
            lastVisit: '5 days ago',
          ),
          _buildPatientCard(
            name: 'Vikram Singh',
            age: '52 yrs',
            village: 'Gram Khajuri',
            condition: 'Joint Pain / Arthritis',
            lastVisit: '1 week ago',
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required String name,
    required String age,
    required String village,
    required String condition,
    required String lastVisit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.leafGreenPale,
              child: Text(
                name.isNotEmpty ? name[0] : 'P',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.leafGreenPrimary,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name ($age)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    village,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.leafGreenPale,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      condition,
                      style: const TextStyle(color: AppColors.leafGreenPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              lastVisit,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
