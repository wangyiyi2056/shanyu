import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Mountain-shaped marker for hiking route waypoints
class MountainMarker extends StatelessWidget {
  final Color color;
  final double size;

  const MountainMarker({
    super.key,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(24, 20),
          painter: MountainPainter(color: color),
        ),
      ),
    );
  }
}

/// Custom painter for mountain icon
class MountainPainter extends CustomPainter {
  final Color color;

  MountainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Mountain peak snow
    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final snowPath = ui.Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.62, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.38, size.height * 0.45)
      ..close();

    canvas.drawPath(snowPath, snowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}