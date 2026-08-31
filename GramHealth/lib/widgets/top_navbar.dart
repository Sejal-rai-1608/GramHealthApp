import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/auth_guard.dart';
import '../l10n/app_language.dart';

/// Top navigation bar used across dashboards.
/// Shows a title, optional notification icon, and a hamburger button on small screens.
class TopNavbar extends StatelessWidget {
  final String title;
  final bool showDrawerButton;
  const TopNavbar({required this.title, this.showDrawerButton = true, super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentUserRole ?? 'patient';
    return AppBar(
      backgroundColor: AppColors.primaryAccent,
      leading: showDrawerButton
          ? IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())
          : null,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => context.push('/notifications')),
        // Profile avatar / menu
        GestureDetector(
          onTap: () {
            if (role == 'admin') {
              context.go('/admin/settings');
            } else if (role == 'patient') {
              context.go('/main/profile');
            } else {
              context.go('/$role/profile');
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/avatar_placeholder.png')),
          ),
        ),
        // Language selector (reuse existing modal)
       // IconButton(icon: const Icon(Icons.language), onPressed: () => showLanguageSelector(context)),
      ],
    );
  }
}
