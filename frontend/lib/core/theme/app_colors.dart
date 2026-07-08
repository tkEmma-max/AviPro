// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // 1. COULEURS DOMINANTES (60%) - Surfaces & Fonds
  // ============================================================
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);

  // ============================================================
  // 2. COULEURS DE STRUCTURE (30%) - Textes & Navigation
  // ============================================================
  static const Color primary = Color(0xFF1E3A8A);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);

  // ============================================================
  // 3. COULEURS D'ACCENT & ALERTES (10%)
  // ============================================================
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);

  // Alias pour les statuts
  static const Color statusGreen = success;
  static const Color statusOrange = warning;
  static const Color statusRed = error;
  static const Color statusBlue = Color(0xFF3B82F6);

  // ============================================================
  // 4. GRIS
  // ============================================================
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ============================================================
  // 5. NEUTRES
  // ============================================================
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
}