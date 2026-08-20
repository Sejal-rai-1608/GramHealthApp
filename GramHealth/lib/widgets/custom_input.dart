import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CustomInput replicates the React Native Input component with an
/// animated border that transitions to primaryAccent when focused.
class CustomInput extends StatefulWidget {
  final String label;
  final String? placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;

  const CustomInput({
    super.key,
    required this.label,
    this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _ctrl;
  late Animation<Color?> _borderColor;
  late Animation<double> _borderWidth;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _borderColor = ColorTween(
      begin: const Color(0x1A000000),
      end: AppColors.primaryAccent,
    ).animate(_ctrl);
    _borderWidth = Tween<double>(begin: 1, end: 2).animate(_ctrl);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0x99030315),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor.value ?? const Color(0x1A000000),
                width: _borderWidth.value,
              ),
            ),
            child: child,
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
