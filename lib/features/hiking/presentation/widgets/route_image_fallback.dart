import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';

class RouteImageFallback extends StatelessWidget {
  const RouteImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Icon(
            Icons.terrain,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
