import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// PrimaryButton matches the React Native PrimaryButton component
/// with spring-like scale animation on press.
class PrimaryButton extends StatefulWidget {
  final String title;
  final VoidCallback onPress;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPress,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
    this.width,
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
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPress();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          padding: widget.padding ??
              const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.primaryAccent,
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
            boxShadow: [
              BoxShadow(
                color: (widget.backgroundColor ?? AppColors.primaryAccent)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.title.toUpperCase(),
            style: TextStyle(
              color: widget.textColor ?? AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
