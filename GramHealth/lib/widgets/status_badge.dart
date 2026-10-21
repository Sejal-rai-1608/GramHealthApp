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
    Color bg = backgroundColor ?? AppColors.leafGreenPale;
    Color fg = textColor ?? AppColors.leafGreenPrimary;

    final lower = status.toLowerCase();
    if (backgroundColor == null) {
      if (lower.contains('pending') || lower.contains('wait')) {
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
      } else if (lower.contains('complete') || lower.contains('approved') || lower.contains('active')) {
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
      } else if (lower.contains('cancel') || lower.contains('reject') || lower.contains('inactive')) {
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
