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
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                '爬山助手',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.emeraldDepthGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -20,
                      child: Icon(
                        Icons.terrain,
                        size: 220,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
                _SectionTitle(title: '快捷功能', actionLabel: null, onAction: null),
                const SizedBox(height: AppSpacing.sm),
                _QuickActionsGrid(),

                const SizedBox(height: AppSpacing.lg),

                // 推荐路线
                _SectionTitle(
                  title: '推荐路线',
                  actionLabel: '查看全部',
                  onAction: () => context.go('/map'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const _RecommendedRoutesList(),

                const SizedBox(height: AppSpacing.lg),

                // 最近活动
                _SectionTitle(
                  title: '最近活动',
                  actionLabel: '查看全部',
                  onAction: () => context.push('/tracks'),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
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
      data: (weather) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Center(
                  child: Text(
                    weather.iconEmoji,
                    style: const TextStyle(fontSize: 40),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weather.hikingAdvice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.air,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${weather.windSpeed.toStringAsFixed(0)} km/h',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => _SkeletonCard(height: 120),
      error: (_, __) => _StatusCard(
        icon: Icons.wb_sunny,
        iconColor: AppColors.warning,
        title: '天气加载失败',
        subtitle: '请检查网络连接',
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.route,
        label: '找路线',
        gradient: const [AppColors.primary, AppColors.primaryLight],
        onTap: () => context.go('/chat'),
      ),
      _QuickActionData(
        icon: Icons.navigation,
        label: '导航',
        gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        onTap: () => context.go('/map'),
      ),
      _QuickActionData(
        icon: Icons.play_circle_outline,
        label: '记录',
        gradient: const [AppColors.accentDark, AppColors.accent],
        onTap: () => context.go('/map'),
      ),
      _QuickActionData(
        icon: Icons.photo_camera,
        label: '识植物',
        gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
        onTap: () => context
            .go('/chat?message=我在爬山时看到一种不认识的植物，请帮我描述一下常见野外植物的识别方法和注意事项'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.9,
      children: actions.map((a) => _QuickActionItem(data: a)).toList(),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}

class _QuickActionItem extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(data.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
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
      loading: () => SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
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

  Widget _fallbackRouteImage() {
    return Container(
      color: AppColors.primaryMuted,
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
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  width: 84,
                  height: 84,
                  child: route.imageUrl.isNotEmpty
                      ? Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                          cacheHeight: 240,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.primaryMuted,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            route.difficultyLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: hexToColor(route.difficultyColor),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          route.rating.toString(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${route.distance} km · ${route.estimatedDuration} 分钟',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
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
                              colors: [AppColors.accentMuted, AppColors.surfaceVariant],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: const Icon(
                            Icons.timeline,
                            color: AppColors.accentDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${track.distanceText} · ${track.durationText}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textHint),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
