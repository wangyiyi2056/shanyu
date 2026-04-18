import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

class RouteWeatherCard extends StatelessWidget {
  final AsyncValue<WeatherData> weatherAsync;
  final String? locationName;

  const RouteWeatherCard({
    super.key,
    required this.weatherAsync,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return weatherAsync.when(
      data: (weather) {
        final isGood = weather.isGoodForHiking;
        final maxTemp = weather.maxTemp;
        final minTemp = weather.minTemp;
        return GestureDetector(
          onTap: () => context.push('/weather-detail', extra: {
            'weather': weather,
            'locationName': locationName ?? '当前位置',
          }),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isGood
                  ? AppColors.info.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isGood
                    ? AppColors.info.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isGood
                            ? AppColors.info.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        weather.iconData,
                        size: 24,
                        color: weather.iconColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${weather.temperature.toStringAsFixed(0)}°C · ${weather.description}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppColors.inkMuted,
                              ),
                            ],
                          ),
                          if (maxTemp != null && minTemp != null)
                            Text(
                              '最高 ${maxTemp.toStringAsFixed(0)}°C / 最低 ${minTemp.toStringAsFixed(0)}°C · 风速 ${weather.windSpeed.toStringAsFixed(0)} km/h',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textHint,
                                      ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  weather.hikingAdvice,
                  style: TextStyle(
                    fontSize: 12,
                    color: isGood ? AppColors.info : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Center(child: Text('天气加载失败: $error')),
      ),
    );
  }
}