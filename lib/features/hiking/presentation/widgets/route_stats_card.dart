import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

class RouteStatsCard extends StatelessWidget {
  final HikingRoute route;

  const RouteStatsCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'icon': Icons.straighten,
        'label': '距离',
        'value': '${route.distance} km',
      },
      {
        'icon': Icons.timer,
        'label': '预计时长',
        'value': '${route.estimatedDuration} 分钟',
      },
      {
        'icon': Icons.trending_up,
        'label': '爬升',
        'value': '${route.elevationGain} m',
      },
      {
        'icon': Icons.landscape,
        'label': '最高点',
        'value': '${route.maxElevation} m',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                children: [
                  Icon(stat['icon'] as IconData,
                      color: AppColors.primary, size: 24),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    stat['value'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    stat['label'] as String,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
