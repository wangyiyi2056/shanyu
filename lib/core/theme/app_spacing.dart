import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Base spacing values (8pt grid)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radius2Xl = 28.0;
  static const double radiusFull = 999.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Chat specific
  static const double chatBubbleMaxWidth = 280.0;
  static const double chatBubblePadding = 12.0;
  static const double chatBubbleRadius = 16.0;
  static const double chatInputHeight = 56.0;

  // Card
  static const double cardPadding = 16.0;
  static const double cardRadius = 16.0;

  // Bottom navigation
  static const double bottomNavHeight = 80.0;

  // App bar
  static const double appBarHeight = 56.0;
}

extension SpacingExtension on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());
  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: toDouble());
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: toDouble());
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  EdgeInsets get padding => mediaQuery.padding;
}
