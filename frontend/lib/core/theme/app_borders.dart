// lib/core/theme/app_borders.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppBorders {
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(9999));

  static const BorderSide borderLight = BorderSide(
    color: AppColors.grey300,
    width: 1.0,
  );

  static const BorderSide borderMedium = BorderSide(
    color: AppColors.grey400,
    width: 1.5,
  );

  static const BorderSide borderPrimary = BorderSide(
    color: AppColors.primary,
    width: 2.0,
  );

  static const BorderSide borderError = BorderSide(
    color: AppColors.error,
    width: 2.0,
  );
}