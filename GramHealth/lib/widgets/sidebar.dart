import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../l10n/app_language.dart';
import '../utils/auth_guard.dart';

/// Sidebar navigation used by Doctor and Admin dashboards.
/// The list of items is built based on the current user role.
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  List<_NavItem> _items(BuildContext context) {
    final role = AuthService.currentUserRole;
    if (role == 'doctor') {
      return [
        _NavItem('dashboard', Icons.dashboard, context.tr('doctor_dashboard')),
        _NavItem('requests', Icons.list_alt, context.tr('consultation_requests')),
        _NavItem('appointments', Icons.calendar_today, context.tr('appointments')),
        _NavItem('patients', Icons.people, context.tr('patients')),
        _NavItem('consultations', Icons.receipt_long, context.tr('consultations')),
        _NavItem('prescriptions', Icons.article, context.tr('prescriptions')),
        _NavItem('profile', Icons.person, context.tr('profile')),
        _NavItem('settings', Icons.settings, context.tr('settings')),
      ];
    } else if (role == 'admin') {
      return [
        _NavItem('dashboard', Icons.dashboard, context.tr('admin_dashboard')),
        _NavItem('users', Icons.group, context.tr('users')),
        _NavItem('doctors', Icons.medical_services, context.tr('doctors')),
        _NavItem('patients', Icons.people_alt, context.tr('patients')),
        _NavItem('appointments', Icons.calendar_month, context.tr('appointments')),
        _NavItem('consultations', Icons.notes, context.tr('consultations')),
        _NavItem('prescriptions', Icons.article, context.tr('prescriptions')),
        _NavItem('pharmacies', Icons.local_pharmacy, context.tr('pharmacies')),
        _NavItem('healthcare-facilities', Icons.local_hospital, context.tr('facilities')),
        _NavItem('reports', Icons.insights, context.tr('reports')),
        _NavItem('settings', Icons.settings, context.tr('settings')),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return Container(
      color: AppColors.secondaryBg,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Navigation list
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (c, i) {
                final item = items[i];
                return ListTile(
                  leading: Icon(item.icon, color: AppColors.textDark),
                  title: Text(item.label, style: const TextStyle(color: AppColors.textDark)),
                  onTap: () => context.go('/${AuthService.currentUserRole}/${item.route}'),
                );
              },
            ),
          ),
          // Bottom profile section
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/avatar_placeholder.png')),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. Jane Doe', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Cardiologist', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () {
                    AuthService.currentUserRole = null;
                    context.go('/onboarding');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  const _NavItem(this.route, this.icon, this.label);
}
