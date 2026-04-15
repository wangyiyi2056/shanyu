import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

class RouteWeatherCard extends StatelessWidget {
  final AsyncValue<WeatherData> weatherAsync;

  const RouteWeatherCard({super.key, required this.weatherAsync});

  @override
  Widget build(BuildContext context) {
    return weatherAsync.when(
      data: (weather) {
        final isGood = weather.isGoodForHiking;
        return Container(
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
                  Text(
                    weather.iconEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(0)}°C · ${weather.description}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (weather.maxTemp != null && weather.minTemp != null)
                        Text(
                          '最高 ${weather.maxTemp!.toStringAsFixed(0)}°C / 最低 ${weather.minTemp!.toStringAsFixed(0)}°C · 风速 ${weather.windSpeed.toStringAsFixed(0)} km/h',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
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
