import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

/// 首页天气 Provider
final homeWeatherProvider = FutureProvider<WeatherData>((ref) async {
  final location = ref.watch(chatNotifierProvider).currentLocation;
  final weatherService = ref.watch(weatherApiServiceProvider);
  return weatherService.getWeather(
    location?.latitude ?? 39.9042,
    location?.longitude ?? 116.4074,
  );
});

/// 首页推荐路线 Provider
final homeRoutesProvider =
    FutureProvider<List<RouteRecommendation>>((ref) async {
  final datasource = RouteLocalDatasource();
  final useCase = RouteRecommendationUseCase(datasource);
  final location = ref.watch(chatNotifierProvider).currentLocation;
  return useCase.getRecommendationsSync(
    preferences: RoutePreferences(
      userLatitude: location?.latitude,
      userLongitude: location?.longitude,
    ),
    limit: 2,
  );
});

/// 最近轨迹 Provider（限制 2 条）
final recentTracksProvider = FutureProvider<List<HikingTrack>>((ref) async {
  final tracks = await ref.watch(tracksProvider.future);
  return tracks.take(2).toList();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('爬山助手'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Icon(
                        Icons.terrain,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('暂无新通知')),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 天气卡片
                const _WeatherCard(),

                const SizedBox(height: AppSpacing.lg),

                // 快捷入口
                Text(
                  '快捷功能',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickActionsGrid(),

                const SizedBox(height: AppSpacing.lg),

                // 推荐路线
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '推荐路线',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/map'),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const _RecommendedRoutesList(),

                const SizedBox(height: AppSpacing.lg),

                // 最近活动
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '最近活动',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/tracks'),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const _RecentActivitiesList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(homeWeatherProvider);

    return weatherAsync.when(
      data: (weather) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                weather.iconEmoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      weather.hikingAdvice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: weather.isGoodForHiking
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.air,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    '${weather.windSpeed.toStringAsFixed(0)} km/h',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny, size: 48, color: AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '天气加载失败',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '请检查网络连接',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        _QuickActionItem(
          icon: Icons.route,
          label: '找路线',
          color: AppColors.primary,
          onTap: () => context.go('/chat'),
        ),
        _QuickActionItem(
          icon: Icons.navigation,
          label: '导航',
          color: AppColors.info,
          onTap: () => context.go('/map'),
        ),
        _QuickActionItem(
          icon: Icons.play_circle_outline,
          label: '记录',
          color: AppColors.secondary,
          onTap: () => context.go('/map'),
        ),
        _QuickActionItem(
          icon: Icons.photo_camera,
          label: '识植物',
          color: AppColors.success,
          onTap: () => context
              .go('/chat?message=我在爬山时看到一种不认识的植物，请帮我描述一下常见野外植物的识别方法和注意事项'),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedRoutesList extends ConsumerWidget {
  const _RecommendedRoutesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(homeRoutesProvider);

    return routesAsync.when(
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return const _EmptyCard(message: '暂无推荐路线');
        }
        return Column(
          children: recommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RouteCard(
                route: rec.route,
                onTap: () =>
                    context.push('/route/${rec.route.id}', extra: rec.route),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _EmptyCard(message: '推荐路线加载失败'),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final HikingRoute route;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.onTap,
  });

  Color get _difficultyColor {
    return switch (route.difficultyLabel) {
      '简单' => AppColors.difficultyEasy,
      '中等' => AppColors.difficultyModerate,
      '较难' => AppColors.difficultyHard,
      _ => AppColors.difficultyExpert,
    };
  }

  Widget _fallbackRouteImage() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(
        Icons.terrain,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: route.imageUrl.isNotEmpty
                      ? Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _fallbackRouteImage(),
                        )
                      : _fallbackRouteImage(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            route.difficultyLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: _difficultyColor,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          route.rating.toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.distance} km · ${route.estimatedDuration} 分钟',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivitiesList extends ConsumerWidget {
  const _RecentActivitiesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(recentTracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _EmptyCard(message: '暂无活动记录，开始你的第一次爬山之旅吧！');
        }
        return Column(
          children: tracks.map((track) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/track/${track.id}'),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.timeline,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${track.distanceText} · ${track.durationText}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _EmptyCard(message: '活动记录加载失败'),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
