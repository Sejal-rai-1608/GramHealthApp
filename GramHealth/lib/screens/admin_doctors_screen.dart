import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class AdminDoctorsScreen extends StatelessWidget {
  const AdminDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> doctors = [
      {'name': 'Dr. Alok Sharma', 'specialty': 'General Physician', 'status': 'Verified', 'experience': '12 yrs'},
      {'name': 'Dr. Priya Mehta', 'specialty': 'Pediatrician', 'status': 'Verified', 'experience': '8 yrs'},
      {'name': 'Dr. Rajesh Patel', 'specialty': 'Cardiologist', 'status': 'Pending Verification', 'experience': '15 yrs'},
      {'name': 'Dr. Sunita Rao', 'specialty': 'Dermatologist', 'status': 'Verified', 'experience': '6 yrs'},
    ];

    return DashboardLayout(
      title: 'Doctor Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Doctors Directory',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Verify credentials and manage doctor listings',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leafGreenPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search doctors by name or specialty...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: doctors.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final doc = doctors[index];
                        final isPending = doc['status'] == 'Pending Verification';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isPending ? AppColors.warning.withValues(alpha: 0.2) : AppColors.leafGreenPale,
                            child: const Icon(Icons.medical_services, color: AppColors.leafGreenDeep),
                          ),
                          title: Text(
                            doc['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            '${doc['specialty']} • ${doc['experience']} Exp',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: doc['status']!),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
