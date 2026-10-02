import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AdminPrescriptionsScreen extends StatelessWidget {
  const AdminPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> prescriptions = [
      {'patient': 'Ramesh Patel', 'doctor': 'Dr. Alok Sharma', 'meds': 'Paracetamol 500mg, Cetirizine 10mg', 'date': '2026-08-25'},
      {'patient': 'Sita Verma', 'doctor': 'Dr. Priya Mehta', 'meds': 'Amoxicillin 250mg, Ibuprofen 400mg', 'date': '2026-08-26'},
      {'patient': 'Mohan Lal', 'doctor': 'Dr. Alok Sharma', 'meds': 'Metformin 500mg', 'date': '2026-08-27'},
    ];

    return DashboardLayout(
      title: 'Prescriptions Directory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescriptions Record',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor all prescriptions issued in the system',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                        hintText: 'Search prescriptions by patient or medicine...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: prescriptions.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final pres = prescriptions[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.leafGreenPale,
                            child: const Icon(Icons.description_outlined, color: AppColors.leafGreenDeep),
                          ),
                          title: Text(
                            'Prescription for ${pres['patient']}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            'Issued by: ${pres['doctor']} • Date: ${pres['date']}\nMeds: ${pres['meds']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.download_outlined, color: AppColors.textMuted),
                            onPressed: () {},
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
