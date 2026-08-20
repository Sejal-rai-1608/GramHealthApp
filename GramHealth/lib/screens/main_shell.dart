import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _tabs = const [
    '/main/home',
    '/main/doctors',
    '/main/symptoms',
    '/main/records',
    '/main/profile',
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageController.instance.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          body: widget.child,
          extendBody: true,
          bottomNavigationBar: Container(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTap,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: AppColors.primaryAccent,
                unselectedItemColor: const Color(0xFFAAAAAA),
                selectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 10),
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: context.tr('tab_home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people_outline),
                    activeIcon: const Icon(Icons.people),
                    label: context.tr('tab_doctors'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.search),
                    label: context.tr('tab_symptoms'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.description_outlined),
                    activeIcon: const Icon(Icons.description),
                    label: context.tr('tab_records'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: context.tr('tab_profile'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
