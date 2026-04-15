import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

class RouteWaypointsList extends StatelessWidget {
  final HikingRoute route;

  const RouteWaypointsList({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: route.waypoints.asMap().entries.map((entry) {
        final index = entry.key;
        final wp = entry.value;
        final isLast = index == route.waypoints.length - 1;

        final (iconData, iconColor) = switch (wp.type) {
          'start' => (Icons.play_circle, AppColors.success),
          'end' => (Icons.flag, AppColors.secondary),
          'viewpoint' => (Icons.photo_camera, AppColors.info),
          'rest_area' => (Icons.chair, Colors.blue),
          'danger' => (Icons.warning, Colors.red),
          'landmark' => (Icons.account_balance, Colors.purple),
          _ => (Icons.place, AppColors.primary),
        };

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor),
                  ),
                  child: Icon(iconData, color: iconColor, size: 18),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: AppColors.textHint.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wp.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '海拔 ${wp.elevation.toStringAsFixed(0)} m',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                  if (!isLast) const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
