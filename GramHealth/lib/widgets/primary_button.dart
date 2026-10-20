import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Primary action — Clear Careway.
/// Single dominant action per screen: Teal #007A6E, 48h, 10r, white text.
class PrimaryButton extends StatefulWidget {
  final String title;
  final VoidCallback onPress;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPress,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.loading = false,
    this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.state,
      reverseDuration: AppMotion.state,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.standard),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.width,
        constraints: const BoxConstraints(minHeight: 48),
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.teal,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppRadii.md),
        ),
        alignment: Alignment.center,
        child: widget.loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: widget.textColor ?? Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: widget.textColor ?? Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                ],
              ),
      ),
    );
    final gesture = GestureDetector(
      onTapDown: widget.loading ? null : (_) => _ctrl.forward(),
      onTapUp: widget.loading ? null : (_) { _ctrl.reverse(); widget.onPress(); },
      onTapCancel: () => _ctrl.reverse(),
      child: child,
    );
    if (widget.loading) return gesture;
    return Semantics(
      button: true,
      enabled: !widget.loading,
      label: widget.title,
      child: gesture,
    );
  }
}

/// Tonal button — supportive secondary, Mint wash.
class TonalButton extends StatelessWidget {
  final String title;
  final VoidCallback onPress;
  final IconData? icon;
  final double? width;

  const TonalButton({
    super.key,
    required this.title,
    required this.onPress,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: width,
      child: FilledButton(
        onPressed: onPress,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.tealDeep,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.tealDeep),
              const SizedBox(width: 8),
            ],
            Text(title, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.tealDeep)),
          ],
        ),
      ),
    );
    return Semantics(button: true, label: title, child: btn);
  }
}

/// Emergency button — reserved for SOS only.
class EmergencyButton extends StatelessWidget {
  final String title;
  final VoidCallback onPress;
  final double? width;

  const EmergencyButton({
    super.key,
    required this.title,
    required this.onPress,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: width,
      child: FilledButton.icon(
        onPressed: onPress,
        icon: const Icon(Icons.emergency, size: 18, color: Colors.white),
        label: Text(title, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emergency,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          elevation: 0,
        ),
      ),
    );
    return Semantics(button: true, label: title, child: btn);
  }
}
