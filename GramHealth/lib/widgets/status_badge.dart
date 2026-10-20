import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const StatusBadge({
    required this.status,
    this.backgroundColor,
    this.textColor,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = backgroundColor ?? AppColors.mint;
    Color fg = textColor ?? AppColors.tealDeep;
    final lower = status.toLowerCase();
    if (backgroundColor == null) {
      if (lower.contains('pending') || lower.contains('wait')) {
        bg = AppColors.amberWash;
        fg = AppColors.amberDeep;
      } else if (lower.contains('complete') || lower.contains('approved') || lower.contains('active')) {
        bg = AppColors.mint;
        fg = AppColors.tealDeep;
      } else if (lower.contains('cancel') || lower.contains('reject') || lower.contains('inactive')) {
        bg = AppColors.coralWash;
        fg = AppColors.coralDeep;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(status, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
