import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class AdminConsultationsScreen extends StatelessWidget {
  const AdminConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> consultations = [
      {'patient': 'Ramesh Patel', 'doctor': 'Dr. Alok Sharma', 'type': 'Video Call', 'duration': '15 mins', 'status': 'Completed'},
      {'patient': 'Sita Verma', 'doctor': 'Dr. Priya Mehta', 'type': 'Chat', 'duration': '10 mins', 'status': 'Completed'},
      {'patient': 'Mohan Lal', 'doctor': 'Dr. Alok Sharma', 'type': 'In-Person', 'duration': '—', 'status': 'Active'},
    ];

    return DashboardLayout(
      title: 'Consultations Registry',
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
                    'Consultations Record',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View past and active teleconsultation sessions',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
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
                        hintText: 'Search consultations...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: consultations.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final cons = consultations[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.leafGreenPale,
                            child: const Icon(Icons.chat_bubble_outline, color: AppColors.leafGreenDeep),
                          ),
                          title: Text(
                            '${cons['patient']} with ${cons['doctor']}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            'Type: ${cons['type']} • Duration: ${cons['duration']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: cons['status']!),
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
