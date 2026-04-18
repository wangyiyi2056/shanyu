import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.bebasNeue(
        fontSize: 72,
        letterSpacing: -0.5,
        color: AppColors.ink,
        height: 0.9,
      );

  static TextStyle get displaySmall => GoogleFonts.bebasNeue(
        fontSize: 48,
        letterSpacing: -0.5,
        color: AppColors.ink,
        height: 0.95,
      );

  static TextStyle get headline => GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.1,
      );

  static TextStyle get title => GoogleFonts.oswald(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.2,
      );

  static TextStyle get body => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.4,
      );

  static TextStyle get label => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: 0.3,
      );

  static TextStyle get data => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.2,
      );

  static TextStyle get dataSmall => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.2,
      );

  static TextStyle get button => GoogleFonts.oswald(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.paper,
        letterSpacing: 0.5,
      );

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: display,
      displayMedium: displaySmall,
      headlineLarge: headline.copyWith(fontSize: 32),
      headlineMedium: headline,
      headlineSmall: title,
      titleLarge: title,
      titleMedium: body.copyWith(fontWeight: FontWeight.w600),
      titleSmall: label,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: bodySmall,
      labelLarge: button,
      labelMedium: label,
      labelSmall: dataSmall,
    );
  }
}
