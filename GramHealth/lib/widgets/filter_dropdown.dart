import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  const FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hintText != null
              ? Text(hintText!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))
              : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.leafGreenPrimary),
          isDense: true,
        ),
      ),
    );
  }
}
