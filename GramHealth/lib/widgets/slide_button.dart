import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// SlideButton replicates the React Native SlideButton component.
/// The user drags the thumb right to confirm; if released past 80% it
/// triggers [onComplete], otherwise it snaps back.
class SlideButton extends StatefulWidget {
  final String title;
  final VoidCallback onComplete;

  const SlideButton({
    super.key,
    required this.title,
    required this.onComplete,
  });

  @override
  State<SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<SlideButton>
    with SingleTickerProviderStateMixin {
  static const double _buttonHeight = 60;
  static const double _thumbSize = 48;

  double _thumbX = 0;
  bool _completed = false;

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;
  double _snapFrom = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _snapTo(double target) {
    _snapFrom = _thumbX;
    _snapAnimation = Tween<double>(begin: _snapFrom, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    )..addListener(() {
        setState(() => _thumbX = _snapAnimation.value);
      });
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth - 48;
    final maxX = buttonWidth - _thumbSize - 12;
    final progress = _thumbX / maxX;

    return Semantics(
      button: true,
      label: widget.title,
      child: SizedBox(
        width: buttonWidth,
        height: _buttonHeight,
        child: GestureDetector(
          onHorizontalDragUpdate: (d) {
            if (_completed) return;
            setState(() {
              _thumbX = (_thumbX + d.delta.dx).clamp(0.0, maxX);
            });
          },
          onHorizontalDragCancel: () {
            if (_completed) return;
            _snapTo(0);
          },
          onHorizontalDragEnd: (_) {
            if (_completed) return;
            if (_thumbX > maxX * 0.8) {
              setState(() => _completed = true);
              _snapTo(maxX);
              Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
            } else {
              _snapTo(0);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(_buttonHeight / 2),
            ),
            padding: const EdgeInsets.all(6),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Opacity(
                    opacity: (1 - progress * 2).clamp(0.0, 1.0),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(_thumbX, 0),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(_thumbSize / 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.13), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward, color: AppColors.ink, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
