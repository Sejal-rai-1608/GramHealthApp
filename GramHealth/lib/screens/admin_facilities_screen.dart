import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class AdminFacilitiesScreen extends StatelessWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> facilities = [
      {'name': 'Sonkatch Primary Health Centre (PHC)', 'type': 'PHC', 'beds': '15 Beds Available', 'status': 'Active'},
      {'name': 'Ashta Community Health Centre (CHC)', 'type': 'CHC', 'beds': '45 Beds Available', 'status': 'Active'},
      {'name': 'Kannod Sub-Centre', 'type': 'Sub-Centre', 'beds': 'First-Aid / OPD Only', 'status': 'Active'},
    ];

    return DashboardLayout(
      title: 'Healthcare Facilities',
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
                    'Rural Health Facilities',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitor infrastructure, bed availability, and status of health sub-centres',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Facility'),
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
                        hintText: 'Search healthcare facilities...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: facilities.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final fac = facilities[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.leafGreenPale,
                            child: const Icon(Icons.local_hospital, color: AppColors.leafGreenDeep),
                          ),
                          title: Text(
                            fac['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            'Type: ${fac['type']} • Capacity/Info: ${fac['beds']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: fac['status']!),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
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
