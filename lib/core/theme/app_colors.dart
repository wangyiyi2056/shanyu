import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette — Deep Forest
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryMuted = Color(0xFFD1FAE5); // Emerald 100

  // Accent Palette — Solar Gold / Amber
  static const Color accent = Color(0xFFFBBF24); // Amber 400
  static const Color accentLight = Color(0xFFFCD34D); // Amber 300
  static const Color accentDark = Color(0xFFF59E0B); // Amber 500
  static const Color accentMuted = Color(0xFFFEF3C7); // Amber 100

  // Legacy secondary alias (sunset tones kept for compatibility)
  static const Color secondary = Color(0xFFF97316); // Orange 500
  static const Color secondaryLight = Color(0xFFFB923C); // Orange 400
  static const Color secondaryDark = Color(0xFFEA580C); // Orange 600

  // Neutral Palette
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F3);
  static const Color surfaceElevated = Color(0xFFF6FAF8);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8); // Slate 400

  // Semantic Colors
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Chat Colors
  static const Color userBubble = Color(0xFF059669);
  static const Color aiBubble = Color(0xFFF1F5F4);
  static const Color systemBubble = Color(0xFFFEF3C7);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0B1210);
  static const Color darkSurface = Color(0xFF111A17);
  static const Color darkSurfaceVariant = Color(0xFF1A2622);
  static const Color darkSurfaceElevated = Color(0xFF16211E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextHint = Color(0xFF64748B); // Slate 500
  static const Color darkAiBubble = Color(0xFF1A2622);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldDepthGradient = LinearGradient(
    colors: [Color(0xFF064E3B), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceSheen = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0FDF4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Difficulty Colors
  static const Color difficultyEasy = Color(0xFF10B981);
  static const Color difficultyModerate = Color(0xFFFBBF24);
  static const Color difficultyHard = Color(0xFFF97316);
  static const Color difficultyExpert = Color(0xFFEF4444);
}
