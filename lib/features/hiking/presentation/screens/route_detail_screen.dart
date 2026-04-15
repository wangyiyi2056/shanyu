import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/review_provider.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/difficulty_tag.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_image_fallback.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_map_preview.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_reviews_list.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_seasons_card.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_stats_card.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_warnings_card.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_waypoints_list.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/route_weather_card.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/star_rating_widget.dart';
import 'package:hiking_assistant/features/weather/presentation/providers/weather_provider.dart';
import 'package:hiking_assistant/shared/utils/color_utils.dart';
import 'package:hiking_assistant/shared/utils/map_launcher.dart';

class RouteDetailScreen extends ConsumerWidget {
  final HikingRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(routeReviewsProvider(route.id));
    final isFavoriteAsync = ref.watch(routeFavoriteProvider(route.id));
    final avgRatingAsync = ref.watch(routeAverageRatingProvider(route.id));
    final reviewCountAsync = ref.watch(routeReviewCountProvider(route.id));
    final reviewActions = ref.read(reviewActionsProvider.notifier);

    final avgRating = avgRatingAsync.valueOrNull ?? route.rating;
    final reviewCount = reviewCountAsync.valueOrNull ?? route.reviewCount;

    final weatherAsync = route.waypoints.isNotEmpty
        ? ref.watch(weatherProvider((
            route.waypoints.first.latitude,
            route.waypoints.first.longitude,
          )))
        : ref.watch(defaultWeatherProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部图片区域
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                route.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
              background: route.imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const RouteImageFallback(),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const RouteImageFallback(),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 评分和位置
                  Row(
                    children: [
                      StarRatingWidget(rating: avgRating, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        ' ($reviewCount条评价)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      const Spacer(),
                      Icon(Icons.location_on,
                          color: AppColors.textHint, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        route.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 核心数据卡片
                  RouteStatsCard(route: route),

                  const SizedBox(height: AppSpacing.md),

                  // 天气预报卡片
                  RouteWeatherCard(weatherAsync: weatherAsync),

                  const SizedBox(height: AppSpacing.md),

                  // 难度标签
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      DifficultyTag(
                        text: route.difficultyLabel,
                        color: hexToColor(route.difficultyColor),
                      ),
                      ...route.tags.map((tag) => DifficultyTag(
                            text: tag,
                            color: AppColors.primary,
                          )),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 路线描述
                  Text(
                    '路线介绍',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    route.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 风险提示
                  if (route.warnings.isNotEmpty) ...[
                    RouteWarningsCard(route: route),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 最佳季节
                  RouteSeasonsCard(route: route),

                  const SizedBox(height: AppSpacing.lg),

                  // 路线关键点
                  Text(
                    '路线关键点',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RouteWaypointsList(route: route),

                  const SizedBox(height: AppSpacing.lg),

                  // 小地图
                  Text(
                    '路线地图',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RouteMapPreview(route: route),

                  const SizedBox(height: AppSpacing.lg),

                  // 评价区域
                  Row(
                    children: [
                      Text(
                        '用户评价',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showReviewDialog(context, ref),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('写评价'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RouteReviewsList(reviewsAsync: reviewsAsync),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: isFavoriteAsync.when(
                  data: (isFavorite) => OutlinedButton.icon(
                    onPressed: () async {
                      final result =
                          await reviewActions.toggleFavorite(route.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result ? '已添加到收藏' : '已取消收藏'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    label: Text(isFavorite ? '已收藏' : '收藏'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFavorite ? Colors.red : null,
                    ),
                  ),
                  loading: () => OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('收藏'),
                  ),
                  error: (_, __) => OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('收藏状态加载失败，请稍后重试')),
                      );
                    },
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('收藏'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final waypoints = route.waypoints;
                    if (waypoints.isNotEmpty) {
                      final start = waypoints.first;
                      final success = await launchMapNavigation(
                        latitude: start.latitude,
                        longitude: start.longitude,
                        label: route.name,
                      );
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('无法打开地图应用')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('该路线没有起点信息')),
                      );
                    }
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('开始导航'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReviewInputDialog(routeName: route.name),
    );

    if (result != null) {
      await ref.read(reviewActionsProvider.notifier).submitReview(
            routeId: route.id,
            rating: result['rating'] as double,
            comment: result['comment'] as String,
          );
    }
  }
}
