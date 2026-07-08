// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_spacing.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? AppColors.primary;
    final textCol = textColor ?? Colors.white;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
        label: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          minimumSize: const Size(double.infinity, 48), // 48px de hauteur
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.buttonRadius, // Capsule 24px
          ),
          textStyle: AppTextStyles.button,
        ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textCol,
        minimumSize: const Size(double.infinity, 48), // 48px de hauteur
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.buttonRadius, // Capsule 24px
        ),
        elevation: 2,
        shadowColor: AppColors.shadow,
        disabledBackgroundColor: AppColors.textHint,
      ),
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textCol,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: textCol,
                  ),
                ),
              ],
            ),
    );
  }
}