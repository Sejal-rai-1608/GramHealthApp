import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 48dp-minimum touch target for a compact icon action.
///
/// The visual icon can be small, but the tappable area is always at least
/// 48×48dp per the Clear Careway accessibility contract. Screen readers get
/// a real button role plus the supplied label.
class CareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double iconSize;
  final double? size;

  const CareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.iconSize = 20,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? AppColors.borderLight),
          ),
          child: Icon(icon, size: iconSize, color: iconColor ?? AppColors.ink),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Compact icon action that keeps a 48dp touch area while drawing a smaller
/// visual chip — used for inline actions inside cards and rows.
class CareInlineIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double visualSize;
  final double iconSize;

  const CareInlineIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.visualSize = 36,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.mint,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor ?? AppColors.tealPale),
              ),
              child: Icon(icon, size: iconSize, color: iconColor ?? AppColors.teal),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
