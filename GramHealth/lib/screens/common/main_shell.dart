import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _tabs = const [
    '/main/home',
    '/main/doctors',
    '/main/symptoms',
    '/main/records',
    '/main/profile',
  ];

  int _indexForLocation(String loc) {
    if (loc.startsWith('/main/doctors')) return 1;
    if (loc.startsWith('/main/symptoms')) return 2;
    if (loc.startsWith('/main/records')) return 3;
    if (loc.startsWith('/main/profile')) return 4;
    return 0;
  }

  void _onTap(int i) => context.go(_tabs[i]);

  List<NavigationDestination> _destinations(BuildContext context) => [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: context.tr('tab_home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_alt_outlined),
          selectedIcon: const Icon(Icons.people_alt_rounded),
          label: context.tr('tab_doctors'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.biotech_outlined),
          selectedIcon: const Icon(Icons.biotech_rounded),
          label: context.tr('tab_symptoms'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder_rounded),
          label: context.tr('tab_records'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: context.tr('tab_profile'),
        ),
      ];

  List<NavigationRailDestination> _railDestinations(BuildContext context) => [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text(context.tr('tab_home')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.people_alt_outlined),
          selectedIcon: const Icon(Icons.people_alt_rounded),
          label: Text(context.tr('tab_doctors')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.biotech_outlined),
          selectedIcon: const Icon(Icons.biotech_rounded),
          label: Text(context.tr('tab_symptoms')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder_rounded),
          label: Text(context.tr('tab_records')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: Text(context.tr('tab_profile')),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageController.instance.currentLanguage,
      builder: (context, lang, _) {
        final loc = GoRouterState.of(context).uri.path;
        final currentIndex = _indexForLocation(loc);
        final isWide = MediaQuery.sizeOf(context).width >= 700;

        if (isWide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: _onTap,
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: AppColors.surface,
                    indicatorColor: AppColors.mint,
                    selectedIconTheme: const IconThemeData(color: AppColors.teal),
                    unselectedIconTheme: const IconThemeData(color: AppColors.inkMuted),
                    selectedLabelTextStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealDeep),
                    unselectedLabelTextStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                    destinations: _railDestinations(context),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.borderLight),
                  Expanded(
                    child: SafeArea(
                      // Inner SafeArea ensures IME-aware padding without double-counting.
                      bottom: true,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: widget.child,
          ),
          bottomNavigationBar: SafeArea(
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: _onTap,
              destinations: _destinations(context),
            ),
          ),
        );
      },
    );
  }
}

/// Optional helper for consistent in-app page scaffolding.
class CarePageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const CarePageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            if (subtitle != null)
              Text(subtitle!, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
          ],
        ),
        actions: action != null ? [Padding(padding: const EdgeInsets.only(right: 12), child: action!)] : null,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding is EdgeInsets ? (padding as EdgeInsets).left : 20,
            padding is EdgeInsets ? (padding as EdgeInsets).top : 12,
            padding is EdgeInsets ? (padding as EdgeInsets).right : 20,
            (padding is EdgeInsets ? (padding as EdgeInsets).bottom : 24) + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}
