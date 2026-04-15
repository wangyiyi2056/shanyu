import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Rich Emerald
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF047857);

  // Secondary Palette - Warm Amber/Solar Gold
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFCD34D);
  static const Color secondaryDark = Color(0xFFD97706);

  // Neutral Palette - Warm Gray
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F2);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5EBE8);
  static const Color overlay = Color(0x801A211E);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A211E);
  static const Color textSecondary = Color(0xFF4A554F);
  static const Color textHint = Color(0xFF8A958F);

  // Semantic Colors
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF059669);
  static const Color info = Color(0xFF0EA5E9);

  // Chat Colors
  static const Color userBubble = Color(0xFF059669);
  static const Color aiBubble = Color(0xFFF0F4F2);
  static const Color systemBubble = Color(0xFFFFF7ED);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F1412);
  static const Color darkSurface = Color(0xFF1A211E);
  static const Color darkSurfaceVariant = Color(0xFF252D2A);
  static const Color darkSurfaceElevated = Color(0xFF2A3330);
  static const Color darkDivider = Color(0xFF3A4540);
  static const Color darkTextPrimary = Color(0xFFF0F4F2);
  static const Color darkTextSecondary = Color(0xFFB8C4BE);
  static const Color darkTextHint = Color(0xFF6B7872);
  static const Color darkAiBubble = Color(0xFF252D2A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Difficulty Colors
  static const Color difficultyEasy = Color(0xFF22C55E);
  static const Color difficultyModerate = Color(0xFFEAB308);
  static const Color difficultyHard = Color(0xFFF97316);
  static const Color difficultyExpert = Color(0xFFEF4444);
}
