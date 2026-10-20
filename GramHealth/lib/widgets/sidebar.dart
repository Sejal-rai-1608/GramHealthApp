import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_language.dart';
import '../utils/auth_guard.dart';

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
        _subtitle = switch (role) {
          'doctor' =>
            (user['specialization'] as String? ?? 'Doctor'),
          'admin' => 'Administrator',
          'pharmacy' => 'Pharmacy',
          'patient' => 'Patient',
          'asha' => 'ASHA worker',
          _ => role,
        };
      });
    }
  }

  /// Navigation is scoped to the signed-in role. Every route listed here is
  /// backed by a live endpoint on the backend.
  List<_NavItem> _items(String role) {
    switch (role) {
      case 'doctor':
        return const [
          _NavItem('requests', Icons.assignment_ind_outlined, 'nav_requests'),
          _NavItem('consultations', Icons.video_camera_front_outlined, 'nav_consultations'),
          _NavItem('prescriptions', Icons.receipt_long_outlined, 'nav_prescriptions'),
          _NavItem('patients', Icons.people_alt_outlined, 'nav_patients'),
          _NavItem('appointments', Icons.calendar_month_outlined, 'nav_schedule'),
          _NavItem('profile', Icons.person_outline_rounded, 'nav_my_profile'),
          _NavItem('settings', Icons.settings_outlined, 'nav_settings'),
        ];
      case 'admin':
        return const [
          _NavItem('dashboard', Icons.dashboard_outlined, 'nav_dashboard'),
          _NavItem('users', Icons.group_outlined, 'nav_users'),
          _NavItem('doctors', Icons.medical_services_outlined, 'nav_doctors'),
          _NavItem('patients', Icons.people_alt_outlined, 'nav_patients'),
          _NavItem('consultations', Icons.forum_outlined, 'nav_consultations'),
          _NavItem('appointments', Icons.calendar_month_outlined, 'nav_schedule'),
          _NavItem('pharmacies', Icons.local_pharmacy_outlined, 'nav_pharmacies'),
          _NavItem('healthcare-facilities', Icons.local_hospital_outlined, 'nav_facilities'),
          _NavItem('asha-workers', Icons.volunteer_activism_outlined, 'nav_asha_workers'),
          _NavItem('reports', Icons.insights_outlined, 'nav_reports'),
          _NavItem('settings', Icons.settings_outlined, 'nav_settings'),
        ];
      case 'pharmacy':
        return const [
          _NavItem('dashboard', Icons.dashboard_outlined, 'nav_dashboard'),
          _NavItem('stock', Icons.inventory_2_outlined, 'nav_stock_list'),
          _NavItem('nearby', Icons.local_pharmacy_outlined, 'nav_nearby_outlets'),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthGuard.currentUserRole ?? '';
    final items = _items(role);
    final loc = GoRouterState.of(context).uri.path;
    final base = '/$role';

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: AppColors.ink, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_rounded,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('GramHealth',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1)),
                      Text('Care console',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No console for this role.',
                        style: GoogleFonts.manrope(
                            fontSize: 13, color: AppColors.inkMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final path = '$base/${item.route}';
                      final active = loc == path || loc.startsWith('$path/');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: active ? AppColors.mint : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go(path);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(item.icon,
                                      size: 18,
                                      color: active
                                          ? AppColors.teal
                                          : AppColors.inkMuted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      context.tr(item.labelKey),
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: active
                                            ? AppColors.tealDeep
                                            : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: AppColors.ink, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                    style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _name.isEmpty ? '—' : _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.inkMuted),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    AuthGuard.onLogout();
                    await AuthService.logout();
                    if (context.mounted) context.go('/login');
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
  final String labelKey;
  const _NavItem(this.route, this.icon, this.labelKey);
}
