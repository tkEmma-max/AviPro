// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';
import 'app_borders.dart';
import 'app_shadows.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.success,
        error: AppColors.error,
        surface: AppColors.surface,
      ),

      // ============================================================
      // TYPOGRAPHIE - Inter
      // ============================================================
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.headlineLarge,
        displayMedium: AppTextStyles.headlineMedium,
        displaySmall: AppTextStyles.headlineSmall,
        headlineMedium: AppTextStyles.subtitleLarge,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.subtitleMedium,
        labelMedium: AppTextStyles.label,
      ),

      // ============================================================
      // APPBAR - Deep Farm Blue
      // ============================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // ============================================================
      // BOUTONS CAPSULE - 48px de hauteur, radius 24px
      // ============================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.buttonRadius,
          ),
          textStyle: AppTextStyles.button,
          elevation: 2,
          shadowColor: AppColors.shadow,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.buttonRadius,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ============================================================
      // CHAMPS DE SAISIE - Style Adobe Express
      // ============================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: AppBorders.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorders.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorders.inputRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorders.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTextStyles.bodyMedium,
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textHint,
      ),

      // ============================================================
      // CARTES - Radius 12px, ombre subtile ou bordure
      // ============================================================
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.cardRadius,
        ),
        shadowColor: AppColors.shadow,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // ============================================================
      // SNACKBAR
      // ============================================================
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.cardRadius,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}