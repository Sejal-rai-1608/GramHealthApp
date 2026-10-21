import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sidebar.dart';
import 'top_navbar.dart';

class DashboardLayout extends StatelessWidget {
  final String title;
  final Widget child;
  const DashboardLayout({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final sidebar = const Sidebar();

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TopNavbar(title: title, showDrawerButton: !isDesktop),
      ),
      drawer: !isDesktop ? Drawer(backgroundColor: AppColors.surface, child: sidebar) : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 248,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.borderLight)),
              ),
              child: sidebar,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
