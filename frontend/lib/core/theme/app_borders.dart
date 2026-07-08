// lib/core/theme/app_borders.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppBorders {
  // ============================================================
  // RADIUS
  // ============================================================
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(9999));

  // ============================================================
  // ALIAS (pour les noms utilisés dans le code)
  // ============================================================
  static const BorderRadius cardRadius = radiusMedium;
  static const BorderRadius inputRadius = radiusSmall;
  static const BorderRadius buttonRadius = radiusXLarge;

  // ============================================================
  // BORDER SIDES
  // ============================================================
  static const BorderSide borderLight = BorderSide(
    color: AppColors.border,
    width: 1.0,
  );

  static const BorderSide borderMedium = BorderSide(
    color: AppColors.border,
    width: 1.5,
  );
}