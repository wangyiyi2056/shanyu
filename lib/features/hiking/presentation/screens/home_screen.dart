import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/route_provider.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';
import 'package:hiking_assistant/shared/utils/color_utils.dart';

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
  final useCase = ref.watch(routeRecommendationUseCaseProvider);
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
            expandedHeight: 220,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '爬山助手',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -20,
                      child: Icon(
                        Icons.terrain,
                        size: 280,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: 40,
                      child: Icon(
                        Icons.forest,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: 60,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      top: 100,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.white,
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
                _SectionHeader(title: '快捷功能', onSeeAll: () {}),
                const SizedBox(height: AppSpacing.sm),
                const _QuickActionsGrid(),

                const SizedBox(height: AppSpacing.lg),

                // 推荐路线
                _SectionHeader(
                  title: '推荐路线',
                  onSeeAll: () => context.go('/map'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const _RecommendedRoutesList(),

                const SizedBox(height: AppSpacing.lg),

                // 最近活动
                _SectionHeader(
                  title: '最近活动',
                  onSeeAll: () => context.push('/tracks'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const _RecentActivitiesList(),

                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('查看全部'),
              SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(homeWeatherProvider);

    return weatherAsync.when(
      data: (weather) => _buildWeatherContent(context, weather),
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard(context),
    );
  }

  Widget _buildWeatherContent(BuildContext context, WeatherData weather) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryLighter.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLighter, AppColors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Center(
                    child: Text(
                      weather.iconEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
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
                      const SizedBox(height: 2),
                      Text(
                        '${weather.temperature.toStringAsFixed(0)}°C',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: weather.isGoodForHiking
                        ? AppColors.primaryLighter
                        : const Color(0xFFFEF3C7),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    weather.hikingAdvice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: weather.isGoodForHiking
                              ? AppColors.primaryDarker
                              : const Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherStatItem(
                  icon: Icons.air,
                  label: '风速',
                  value: '${weather.windSpeed.toStringAsFixed(0)} km/h',
                  iconColor: AppColors.accentSky,
                ),
                _WeatherStatItem(
                  icon: Icons.thermostat,
                  label: '最高温',
                  value: weather.maxTemp != null
                      ? '${weather.maxTemp!.toStringAsFixed(0)}°C'
                      : '--',
                  iconColor: AppColors.secondary,
                ),
                _WeatherStatItem(
                  icon: Icons.ac_unit,
                  label: '最低温',
                  value: weather.minTemp != null
                      ? '${weather.minTemp!.toStringAsFixed(0)}°C'
                      : '--',
                  iconColor: AppColors.accentViolet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Icon(
                Icons.wb_sunny,
                size: 32,
                color: Color(0xFFF59E0B),
              ),
            ),
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
    );
  }
}

class _WeatherStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _WeatherStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.85,
      children: [
        _QuickActionItem(
          icon: Icons.route,
          label: '找路线',
          gradientColors: const [AppColors.primary, AppColors.primaryLight],
          onTap: () => context.go('/chat'),
        ),
        _QuickActionItem(
          icon: Icons.navigation,
          label: '导航',
          gradientColors: const [AppColors.accentSky, Color(0xFF38BDF8)],
          onTap: () => context.go('/map'),
        ),
        _QuickActionItem(
          icon: Icons.play_circle_outline,
          label: '记录',
          gradientColors: const [AppColors.secondary, AppColors.secondaryLight],
          onTap: () => context.go('/map'),
        ),
        _QuickActionItem(
          icon: Icons.photo_camera,
          label: '识植物',
          gradientColors: const [AppColors.accentRose, Color(0xFFFB923C)],
          onTap: () => context.go(
            '/chat?message=我在爬山时看到一种不认识的植物，请帮我描述一下常见野外植物的识别方法和注意事项',
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
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
          return const _EmptyState(message: '暂无推荐路线');
        }
        return Column(
          children: recommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _EmptyState(message: '推荐路线加载失败'),
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

  Widget _fallbackRouteImage() {
    return Container(
      color: AppColors.primaryLighter,
      child: const Icon(
        Icons.terrain,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: route.imageUrl.isNotEmpty
                      ? Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                          cacheHeight: 240,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.primaryLighter,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: hexToColor(route.difficultyColor)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            route.difficultyLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: hexToColor(route.difficultyColor),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          route.rating.toString(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RouteMetaItem(
                          icon: Icons.straighten,
                          value: '${route.distance} km',
                        ),
                        const SizedBox(width: 12),
                        _RouteMetaItem(
                          icon: Icons.schedule,
                          value: '${route.estimatedDuration} 分钟',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteMetaItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _RouteMetaItem({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
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
          return const _EmptyState(
            message: '暂无活动记录，开始你的第一次爬山之旅吧！',
          );
        }
        return Column(
          children: tracks.map((track) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => context.push('/track/${track.id}'),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.secondaryLight
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: const Icon(
                            Icons.timeline,
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
                                track.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${track.distanceText} · ${track.durationText}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            track.formattedDate,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
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
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const _EmptyState(message: '活动记录加载失败'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.terrain_outlined,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.6),
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
