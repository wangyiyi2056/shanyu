import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';

/// Topographic contour line painter for decorative backgrounds
class TopographicPainter extends CustomPainter {
  final Color? color;
  final double lineWidth;
  final int lineCount;

  const TopographicPainter({
    this.color,
    this.lineWidth = 1.5,
    this.lineCount = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (color ?? AppColors.forest).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    for (var i = 0; i < lineCount; i++) {
      final y = 6.0 + i * 5;
      final path = ui.Path();
      for (var x = 0.0; x <= size.width; x += 8) {
        final dy = y + (x % 16 < 8 ? -2 : 2);
        if (x == 0) {
          path.moveTo(x, dy);
        } else {
          path.lineTo(x, dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}