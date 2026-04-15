import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/shared/utils/color_utils.dart';

class NearbyRouteItem extends StatelessWidget {
  final HikingRoute route;
  final VoidCallback onTap;

  const NearbyRouteItem({
    super.key,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyColor = hexToColor(route.difficultyColor);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: difficultyColor.withValues(alpha: 0.2),
          child: Icon(Icons.terrain, color: difficultyColor, size: 20),
        ),
        title: Text(route.name),
        subtitle: Row(
          children: [
            const Icon(Icons.straighten, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('${route.distance} km'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: difficultyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                route.difficultyLabel,
                style: TextStyle(fontSize: 10, color: difficultyColor),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }
}
