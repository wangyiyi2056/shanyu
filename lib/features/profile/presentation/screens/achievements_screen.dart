import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/profile/data/models/achievement_model.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/achievements_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text('成就徽章', style: AppTypography.title),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          final unlocked = achievements.where((a) => a.isUnlocked).length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.forest, AppColors.forestLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppColors.softShadow(blur: 16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            '$unlocked',
                            style: AppTypography.displaySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 48,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '已获得 / ${achievements.length} 个徽章',
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = achievements[index];
                      return _AchievementCard(achievement: a);
                    },
                    childCount: achievements.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
        error: (_, __) => Center(
          child: Text('加载失败', style: AppTypography.body),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final opacity = achievement.isUnlocked ? 1.0 : 0.4;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: achievement.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.icon,
                  size: 32,
                  color: achievement.color,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Opacity(
              opacity: opacity,
              child: Text(
                achievement.name,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: opacity,
              child: Text(
                achievement.description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!achievement.isUnlocked) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock, size: 14, color: AppColors.inkMuted),
            ],
          ],
        ),
      ),
    );
  }
}
