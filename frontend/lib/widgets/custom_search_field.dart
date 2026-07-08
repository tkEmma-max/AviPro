// lib/widgets/custom_search_field.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_spacing.dart';

class CustomSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const CustomSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppBorders.radiusXLarge,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textHint,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}