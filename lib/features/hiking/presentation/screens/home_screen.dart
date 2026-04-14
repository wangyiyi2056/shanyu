import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';

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
                onPressed: () {},
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 天气卡片
                _WeatherCard(),

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
                Text(
                  '最近活动',
                  style: Theme.of(context).textTheme.titleMedium,
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

class _WeatherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
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
                    '北京 · 多云',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '18°C - 25°C',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '适宜爬山',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.air, size: 20, color: AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(
                  '2级',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
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
          onTap: () => context.go('/chat'),
        ),
        _QuickActionItem(
          icon: Icons.photo_camera,
          label: '识植物',
          color: AppColors.success,
          onTap: () => context.go('/chat'),
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

class _RecommendedRoutesList extends StatelessWidget {
  const _RecommendedRoutesList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RouteCard(
          name: '香山公园',
          difficulty: '简单',
          distance: '2.3km',
          duration: '1.5小时',
          rating: 4.5,
        ),
        SizedBox(height: AppSpacing.sm),
        _RouteCard(
          name: '百望山',
          difficulty: '中等',
          distance: '3.5km',
          duration: '2.5小时',
          rating: 4.3,
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String name;
  final String difficulty;
  final String distance;
  final String duration;
  final double rating;

  const _RouteCard({
    required this.name,
    required this.difficulty,
    required this.distance,
    required this.duration,
    required this.rating,
  });

  Color get _difficultyColor {
    return switch (difficulty) {
      '简单' => AppColors.difficultyEasy,
      '中等' => AppColors.difficultyModerate,
      '较难' => AppColors.difficultyHard,
      _ => AppColors.difficultyExpert,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/chat'),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 封面图
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.terrain,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                            difficulty,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: _difficultyColor,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$distance · $duration',
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

class _RecentActivitiesList extends StatelessWidget {
  const _RecentActivitiesList();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.history,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无活动记录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '开始你的第一次爬山之旅吧！',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
