import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../l10n/app_language.dart';
import '../utils/auth_guard.dart';

/// Sidebar navigation used by Doctor and Admin dashboards.
/// The list of items is built based on the current user role.
class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _name = '';
  String _subtitle = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      final role = AuthGuard.currentUserRole ?? '';
      final name = user['name'] as String? ?? '';
      setState(() {
        _name = role == 'doctor' ? 'Dr. $name' : name;
        _subtitle = role == 'doctor'
            ? (user['specialization'] as String? ?? 'Doctor')
            : role == 'admin'
                ? 'Administrator'
                : role;
      });
    }
  }

  List<_NavItem> _items(BuildContext context) {
    final role = AuthGuard.currentUserRole;
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
                  onTap: () => context.go('/${AuthGuard.currentUserRole}/${item.route}'),
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryAccent,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name.isNotEmpty ? _name : '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () async {
                    AuthGuard.onLogout();
                    await AuthService.logout();
                    if (context.mounted) context.go('/onboarding');
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
