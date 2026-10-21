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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hintText != null ? Text(hintText!, style: Theme.of(context).textTheme.bodySmall) : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.teal),
          isDense: true,
        ),
      ),
    );
  }
}
