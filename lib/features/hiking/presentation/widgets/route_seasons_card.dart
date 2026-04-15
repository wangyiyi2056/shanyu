import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

class RouteSeasonsCard extends StatelessWidget {
  final HikingRoute route;

  const RouteSeasonsCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '最佳季节: ${route.bestSeasons.join('、')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
