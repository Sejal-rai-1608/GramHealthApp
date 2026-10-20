import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Legacy GlassCard — kept as compatibility shim.
/// New code should use [CareCard]. This wrapper renders the Clear Careway
/// opaque surface so old call-sites do not break visually.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double sigmaX;
  final double sigmaY;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.sigmaX = 10,
    this.sigmaY = 10,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadii.lg;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: 1,
        ),
        boxShadow: boxShadow ?? const [AppColors.shadowLow],
      ),
      child: child,
    );
  }
}
