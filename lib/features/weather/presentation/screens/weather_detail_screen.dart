import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

class WeatherDetailScreen extends ConsumerWidget {
  final WeatherData weather;
  final String locationName;

  const WeatherDetailScreen({
    super.key,
    required this.weather,
    this.locationName = '当前位置',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天气详情'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 位置信息
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.inkMuted, size: 20),
                const SizedBox(width: 8),
                Text(
                  locationName,
                  style: AppTypography.body.copyWith(color: AppColors.inkLight),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 当前天气
            _CurrentWeatherCard(weather: weather),
            const SizedBox(height: AppSpacing.lg),

            // 爬山建议
            _HikingAdviceCard(weather: weather),
            const SizedBox(height: AppSpacing.lg),

            // 未来天气预报
            if (weather.forecast != null && weather.forecast!.length > 1) ...[
              Text(
                '未来天气',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...weather.forecast!.skip(1).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ForecastDayCard(forecast: f),
              )),
            ],

            // 温度范围
            if (weather.maxTemp != null || weather.minTemp != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                '今日温度范围',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TemperatureRangeCard(
                maxTemp: weather.maxTemp ?? weather.temperature,
                minTemp: weather.minTemp ?? weather.temperature,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;

  const _CurrentWeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF2E7D62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.description,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${weather.temperature.toStringAsFixed(0)}°C',
                  style: AppTypography.display.copyWith(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.air, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '风速 ${weather.windSpeed.toStringAsFixed(0)} km/h',
                      style: AppTypography.body.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            weather.iconData,
            color: Colors.white.withValues(alpha: 0.9),
            size: 64,
          ),
        ],
      ),
    );
  }
}

class _HikingAdviceCard extends StatelessWidget {
  final WeatherData weather;

  const _HikingAdviceCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final isGood = weather.isGoodForHiking;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isGood
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isGood ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGood ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.thumb_up : Icons.warning,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGood ? '适宜爬山' : '不建议爬山',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isGood ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.hikingAdvice,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  final DailyForecast forecast;

  const _ForecastDayCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final dayName = _getDayName(forecast.date);
    final isGood = forecast.isGoodForHiking;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppColors.softShadow(blur: 8, dy: 2),
      ),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 60,
            child: Text(
              dayName,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Weather icon
          Icon(
            forecast.iconData,
            color: forecast.iconColor,
            size: 28,
          ),
          const SizedBox(width: 8),
          // Description
          Expanded(
            child: Text(
              forecast.description,
              style: AppTypography.body.copyWith(
                color: AppColors.inkLight,
              ),
            ),
          ),
          // Temperature
          Row(
            children: [
              Text(
                '${forecast.maxTemp.toStringAsFixed(0)}°',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ${forecast.minTemp.toStringAsFixed(0)}°',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Hiking indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isGood ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.check : Icons.close,
              color: Colors.white,
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == 2) return '后天';
    return '${date.month}/${date.day}';
  }
}

class _TemperatureRangeCard extends StatelessWidget {
  final double maxTemp;
  final double minTemp;

  const _TemperatureRangeCard({
    required this.maxTemp,
    required this.minTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppColors.softShadow(blur: 8, dy: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.arrow_upward, color: AppColors.warning, size: 24),
              const SizedBox(height: 4),
              Text(
                '${maxTemp.toStringAsFixed(0)}°C',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              Text(
                '最高',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.arrow_downward, color: AppColors.info, size: 24),
              const SizedBox(height: 4),
              Text(
                '${minTemp.toStringAsFixed(0)}°C',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              Text(
                '最低',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}