import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/route_provider.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';
import 'package:hiking_assistant/shared/utils/color_utils.dart';

final homeWeatherProvider = FutureProvider<WeatherData>((ref) async {
  final location = ref.watch(chatNotifierProvider).currentLocation;
  final weatherService = ref.watch(weatherApiServiceProvider);
  return weatherService.getWeather(
    location?.latitude ?? 39.9042,
    location?.longitude ?? 116.4074,
  );
});

final homeRoutesProvider =
    FutureProvider<List<RouteRecommendation>>((ref) async {
  final useCase = ref.watch(routeRecommendationUseCaseProvider);
  final location = ref.watch(chatNotifierProvider).currentLocation;
  return await useCase.getRecommendations(
    preferences: RoutePreferences(
      userLatitude: location?.latitude,
      userLongitude: location?.longitude,
    ),
    limit: 4,
  );
});

final recentTracksProvider = FutureProvider<List<HikingTrack>>((ref) async {
  final tracks = await ref.watch(tracksProvider.future);
  return tracks.take(2).toList();
});

/// 搜索筛选状态
final searchQueryProvider = StateProvider<String>((ref) => '');
final difficultyFilterProvider = StateProvider<Set<String>>((ref) => {});

/// 搜索后的路线列表
final filteredRoutesProvider = FutureProvider<List<RouteRecommendation>>((ref) async {
  final useCase = ref.watch(routeRecommendationUseCaseProvider);
  final location = ref.watch(chatNotifierProvider).currentLocation;
  final searchQuery = ref.watch(searchQueryProvider);
  final difficultyFilter = ref.watch(difficultyFilterProvider);

  // 搜索逻辑
  if (searchQuery.isNotEmpty) {
    final searchResults = await useCase.searchByLocation(searchQuery);
    // 应用难度筛选
    if (difficultyFilter.isEmpty) {
      return searchResults;
    }
    return searchResults.where((rec) =>
        difficultyFilter.contains(rec.route.difficultyLabel)).toList();
  }

  // 筛选逻辑
  final recommendations = await useCase.getRecommendations(
    preferences: RoutePreferences(
      userLatitude: location?.latitude,
      userLongitude: location?.longitude,
      preferredDifficulty: difficultyFilter.isNotEmpty
          ? difficultyFilter.first
          : null,
    ),
    limit: 20,
  );

  if (difficultyFilter.isEmpty) {
    return recommendations.take(4).toList();
  }
  return recommendations.where((rec) =>
      difficultyFilter.contains(rec.route.difficultyLabel)).take(4).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _WeatherHero(),
                  const SizedBox(height: AppSpacing.lg),
                  // 搜索栏
                  _SearchBar(
                    controller: _searchController,
                    onSearch: (query) {
                      ref.read(searchQueryProvider.notifier).state = query;
                    },
                    onToggleFilters: () {
                      setState(() => _showFilters = !_showFilters);
                    },
                    showFilters: _showFilters,
                  ),
                  // 筛选标签
                  if (_showFilters)
                    _FilterChips(
                      selectedDifficulties: ref.watch(difficultyFilterProvider),
                      onSelectionChanged: (difficulties) {
                        ref.read(difficultyFilterProvider.notifier).state = difficulties;
                      },
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const _QuickActionsPills(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '推荐路线',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/map'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperDark,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Text(
                            '全部',
                            style: AppTypography.label.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _FilteredRoutesList(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '最近活动',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/tracks'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperDark,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Text(
                            '全部',
                            style: AppTypography.label.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _RecentActivitiesList(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onToggleFilters;
  final bool showFilters;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onToggleFilters,
    required this.showFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: '搜索路线名称或地点...',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.inkMuted,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.inkMuted),
                      onPressed: () {
                        controller.clear();
                        onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: showFilters ? AppColors.forest : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: IconButton(
            icon: Icon(
              Icons.tune,
              color: showFilters ? Colors.white : AppColors.inkMuted,
            ),
            onPressed: onToggleFilters,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<String> selectedDifficulties;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _FilterChips({
    required this.selectedDifficulties,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final difficulties = ['新手', '中等', '困难', '专家'];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: difficulties.map((diff) {
          final isSelected = selectedDifficulties.contains(diff);
          return FilterChip(
            label: Text(diff),
            selected: isSelected,
            onSelected: (selected) {
              final newSet = Set<String>.from(selectedDifficulties);
              if (selected) {
                newSet.add(diff);
              } else {
                newSet.remove(diff);
              }
              onSelectionChanged(newSet);
            },
            selectedColor: AppColors.forest.withValues(alpha: 0.2),
            checkmarkColor: AppColors.forest,
            backgroundColor: Colors.white,
            labelStyle: AppTypography.label.copyWith(
              color: isSelected ? AppColors.forest : AppColors.inkLight,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.forest : AppColors.inkMuted.withValues(alpha: 0.3),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilteredRoutesList extends ConsumerWidget {
  const _FilteredRoutesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(filteredRoutesProvider);

    return routesAsync.when(
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return const _EmptyCard(message: '没有找到匹配的路线');
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
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _EmptyCard(message: '推荐路线加载失败'),
    );
  }
}

class _WeatherHero extends ConsumerWidget {
  const _WeatherHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(homeWeatherProvider);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF2E7D62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 16, dy: 6),
      ),
      child: weatherAsync.when(
        data: (weather) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weather.description,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C',
                      style: AppTypography.display.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        weather.hikingAdvice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    weather.iconData,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
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
                          style: AppTypography.dataSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny, size: 40, color: Colors.white70),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '天气加载失败',
                style: AppTypography.title.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsPills extends StatelessWidget {
  const _QuickActionsPills();

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('找路线', Icons.route, () => context.go('/chat')),
      ('导航', Icons.navigation, () => context.go('/map')),
      ('记录', Icons.play_circle_outline, () => context.go('/map')),
      ('识植物', Icons.photo_camera, () => context.push('/plant-identification')),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((a) {
        final (label, icon, onTap) = a;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.inkLight),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: AppColors.inkLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppColors.softShadow(blur: 12, dy: 4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large top image
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  route.imageUrl.isNotEmpty
                      ? Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          colorBlendMode: BlendMode.multiply,
                          color: Colors.black.withValues(alpha: 0.05),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.paperDark,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.paperDark,
                            child: const Icon(
                              Icons.terrain,
                              size: 48,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.paperDark,
                          child: const Icon(
                            Icons.terrain,
                            size: 48,
                            color: AppColors.inkMuted,
                          ),
                        ),
                  // Bottom gradient for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Difficulty tag on image
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        route.difficultyLabel,
                        style: AppTypography.dataSmall.copyWith(
                          color: hexToColor(route.difficultyColor),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Title on image bottom
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      route.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info row below image
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.straighten,
                    size: 16,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${route.distance} km',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${route.estimatedDuration} 分钟',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkLight,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        route.rating.toString(),
                        style: AppTypography.label.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _RecentActivitiesList extends ConsumerWidget {
  const _RecentActivitiesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(recentTracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _EmptyCard(
            message: '暂无活动记录，开始你的第一次爬山之旅吧！',
          );
        }
        return Column(
          children: tracks.map((track) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () => context.push('/track/${track.id}'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: AppColors.softShadow(blur: 12, dy: 4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.timeline,
                          color: AppColors.forest,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: AppTypography.title.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${track.distanceText} · ${track.durationText}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.chevron_right,
                          color: AppColors.inkMuted,
                          size: 24,
                        ),
                      ),
                    ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 40,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
