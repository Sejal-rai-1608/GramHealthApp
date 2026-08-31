import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/loading_state.dart';
import '../widgets/empty_state.dart';
import '../l10n/app_language.dart';

/// Doctor Dashboard – shows overview KPI cards and a quick list of today's appointments.
class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.tr('doctor_dashboard');
    // Mock data – replace with real service calls later.
    final kpiData = [
      {'icon': Icons.event_available, 'label': context.tr('today_appointments'), 'value': '3'},
      {'icon': Icons.pending_actions, 'label': context.tr('pending_requests'), 'value': '2'},
      {'icon': Icons.people, 'label': context.tr('total_patients'), 'value': '128'},
      {'icon': Icons.check_circle, 'label': context.tr('completed_consultations'), 'value': '45'},
    ];

    return DashboardLayout(
      title: title,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting header
            Text(
              context.tr('good_morning_doctor'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('dashboard_subtitle'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // KPI cards grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: kpiData.map((d) => StatCard(
                icon: d['icon'] as IconData,
                label: d['label'] as String,
                value: d['value'] as String,
              )).toList(),
            ),
            const SizedBox(height: 32),
            // Placeholder for Today's Appointments section
            Text(context.tr('todays_appointments'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // In a real app this would be a list built from a service.
            LoadingState(),
          ],
        ),
      ),
    );
  }
}
