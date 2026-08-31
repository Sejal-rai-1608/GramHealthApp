import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sidebar.dart';
import 'top_navbar.dart';

/// A responsive layout used by Doctor and Admin dashboards.
///
/// - On wide screens (>= 900dp) shows a permanent [Sidebar] on the left.
/// - On medium screens (600‑899dp) shows a collapsible drawer accessible via the hamburger menu.
/// - On narrow screens (< 600dp) shows only the top navigation bar with a drawer.
class DashboardLayout extends StatelessWidget {
  final String title;
  final Widget child;
  const DashboardLayout({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    final sidebar = Sidebar();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TopNavbar(title: title, showDrawerButton: !isDesktop),
      ),
      drawer: (!isDesktop) ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 250, child: sidebar),
          Expanded(child: Padding(padding: const EdgeInsets.all(16), child: child)),
        ],
      ),
      backgroundColor: AppColors.secondaryBg,
    );
  }
}
