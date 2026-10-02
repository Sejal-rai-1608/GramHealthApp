import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> appointments = [
      {'patient': 'Ramesh Patel', 'doctor': 'Dr. Alok Sharma', 'date': '2026-08-28', 'time': '10:00 AM', 'status': 'Scheduled'},
      {'patient': 'Sita Verma', 'doctor': 'Dr. Priya Mehta', 'date': '2026-08-28', 'time': '11:30 AM', 'status': 'Completed'},
      {'patient': 'Mohan Lal', 'doctor': 'Dr. Alok Sharma', 'date': '2026-08-29', 'time': '09:15 AM', 'status': 'Pending'},
      {'patient': 'Gita Bai', 'doctor': 'Dr. Priya Mehta', 'date': '2026-08-29', 'time': '02:00 PM', 'status': 'Cancelled'},
    ];

    return DashboardLayout(
      title: 'Appointments Management',
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
                    'Appointments Registry',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitor schedules and statuses of consultations',
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
                        hintText: 'Search by patient or doctor name...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: appointments.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final appt = appointments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.leafGreenPale,
                            child: const Icon(Icons.calendar_month, color: AppColors.leafGreenDeep),
                          ),
                          title: Text(
                            '${appt['patient']} ↔ ${appt['doctor']}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          subtitle: Text(
                            'Date: ${appt['date']} • Time: ${appt['time']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: appt['status']!),
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
