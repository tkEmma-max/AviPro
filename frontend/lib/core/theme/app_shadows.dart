// lib/core/theme/app_shadows.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  // ============================================================
  // SHADOWS
  // ============================================================
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================================
  // ALIAS (pour les noms utilisés dans le code)
  // ============================================================
  static const List<BoxShadow> shadowCard = shadowSmall;
  static const List<BoxShadow> cardShadow = shadowSmall; // <--- AJOUTÉ
  static const List<BoxShadow> buttonShadow = shadowSmall;
}