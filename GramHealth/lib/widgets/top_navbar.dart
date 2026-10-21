import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'connectivity_badge.dart';

class TopNavbar extends StatelessWidget {
  final String title;
  final bool showDrawerButton;
  final Widget? leading;

  const TopNavbar({
    required this.title,
    this.showDrawerButton = true,
    this.leading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      // The Builder is required: `context` inside TopNavbar.build sits above
      // the Scaffold, so Scaffold.of(context) would throw when the drawer
      // button is tapped on a phone.
      leading: leading ??
          (showDrawerButton
              ? Builder(
                  builder: (scaffoldContext) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.ink),
                    tooltip: 'Open navigation',
                    onPressed: () {
                      final scaffold = Scaffold.maybeOf(scaffoldContext);
                      if (scaffold != null && scaffold.hasDrawer) {
                        scaffold.openDrawer();
                      }
                    },
                  ),
                )
              : null),
      title: Text(
        title,
        style: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
      centerTitle: false,
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Center(child: ConnectivityBadge()),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink),
          tooltip: 'Notifications',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
            context.push('/notifications');
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
