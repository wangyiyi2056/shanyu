import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Emerald Forest
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryLighter = Color(0xFFD1FAE5);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryDarker = Color(0xFF065F46);

  // Secondary Palette - Sunset Amber
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFCD34D);
  static const Color secondaryDark = Color(0xFFD97706);

  // Accent Colors
  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color accentRose = Color(0xFFFB7185);
  static const Color accentViolet = Color(0xFF8B5CF6);

  // Neutral Palette - Warm
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0FDF4);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFFD1D5DB);

  // Semantic Colors
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF0EA5E9);

  // Chat Colors
  static const Color userBubble = Color(0xFF059669);
  static const Color aiBubble = Color(0xFFF3F4F6);
  static const Color systemBubble = Color(0xFFFEF3C7);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkSurfaceVariant = Color(0xFF374151);
  static const Color darkSurfaceElevated = Color(0xFF4B5563);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextHint = Color(0xFF9CA3AF);
  static const Color darkAiBubble = Color(0xFF374151);

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
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Difficulty Colors
  static const Color difficultyEasy = Color(0xFF10B981);
  static const Color difficultyModerate = Color(0xFFF59E0B);
  static const Color difficultyHard = Color(0xFFF97316);
  static const Color difficultyExpert = Color(0xFFEF4444);

  // Shadow Colors
  static Color shadowLight = const Color(0xFF000000).withValues(alpha: 0.06);
  static Color shadowMedium = const Color(0xFF000000).withValues(alpha: 0.1);
  static Color shadowDark = const Color(0xFF000000).withValues(alpha: 0.15);
}
