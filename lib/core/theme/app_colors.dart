import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core outdoor palette — forest green dominates
  static const Color paper = Color(0xFFFAFAF8);
  static const Color paperDark = Color(0xFFF2F0EB);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkLight = Color(0xFF4A4A4A);
  static const Color inkMuted = Color(0xFF8A8A8A);

  static const Color forest = Color(0xFF1B4D3E);
  static const Color forestLight = Color(0xFF2E7D62);
  static const Color orange = Color(0xFFEA580C);
  static const Color orangeLight = Color(0xFFF97316);
  static const Color sun = Color(0xFFF59E0B);
  static const Color lavender = Color(0xFF7C3AED);

  // Semantic — muted for tags/labels
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF1B4D3E);
  static const Color warning = Color(0xFFC2781B);

  // Chat
  static const Color userBubble = Color(0xFF1B4D3E);
  static const Color aiBubble = Color(0xFFF2F0EB);

  // Difficulty — desaturated
  static const Color difficultyEasy = Color(0xFF2E7D62);
  static const Color difficultyModerate = Color(0xFFB48A2B);
  static const Color difficultyHard = Color(0xFFD15A27);
  static const Color difficultyExpert = Color(0xFF7C5CCF);

  // Legacy aliases
  static const Color primary = forest;
  static const Color primaryLight = forestLight;
  static const Color secondary = orange;
  static const Color secondaryLight = orangeLight;
  static const Color info = forestLight;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkLight;
  static const Color textHint = inkMuted;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = paperDark;
  static const Color darkSurfaceVariant = Color(0xFF292524);
  static const Color darkTextHint = inkMuted;

  // Soft mobile shadow
  static List<BoxShadow> softShadow({Color? color, double blur = 16, double dy = 4}) {
    return [
      BoxShadow(
        color: (color ?? const Color(0xFF1A1A1A)).withValues(alpha: 0.06),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }

  // Compatibility
  static List<BoxShadow> hardShadow(Color color, {double dx = 4, double dy = 4}) {
    return [
      BoxShadow(
        color: color,
        blurRadius: 0,
        offset: Offset(dx, dy),
      ),
    ];
  }
}
