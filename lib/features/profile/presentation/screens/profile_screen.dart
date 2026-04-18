import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/review_provider.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/achievements_provider.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/profile_provider.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: CustomScrollView(
        slivers: [
          // 护照风格头部
          SliverToBoxAdapter(
            child: _PassportHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.xl),

                // 统计数据
                Text(
                  '我的记录',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _StatsGrid(),

                const SizedBox(height: AppSpacing.xl),

                // 功能列表
                Text(
                  '功能',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _FeatureList(),

                const SizedBox(height: AppSpacing.xl),

                // 关于
                Text(
                  '关于',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _AboutSection(),

                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

void _showSimpleDialog(BuildContext context,
    {required String title, required String content}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Text(title, style: AppTypography.title),
      content: Text(content, style: AppTypography.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

class _PassportHeader extends ConsumerWidget {
  const _PassportHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF166534), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部导航
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '我的护照',
                    style: AppTypography.title.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 用户信息
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileAsync.when(
                          data: (profile) => Text(
                            profile.nickname,
                            style: AppTypography.headline.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 24,
                            width: 100,
                            child: Center(
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white70),
                              ),
                            ),
                          ),
                          error: (_, __) => Text(
                            '爬山爱好者',
                            style: AppTypography.headline.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        profileAsync.when(
                          data: (profile) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              profile.levelTitle,
                              style: AppTypography.dataSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 16,
                            width: 80,
                            child: Center(
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white70),
                              ),
                            ),
                          ),
                          error: (_, __) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              'Lv.1 初级选手',
                              style: AppTypography.dataSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InkWell(
                      onTap: () => context.push('/edit-profile'),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          '编辑',
                          style: AppTypography.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 护照编号条
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NO.',
                      style: AppTypography.dataSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '8839 2156 7742',
                      style: AppTypography.data.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
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

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        final totalDistance = tracks.fold<double>(
          0,
          (sum, t) => sum + t.totalDistance,
        );
        final totalElevation = tracks.fold<double>(
          0,
          (sum, t) => sum + t.elevationGain,
        );
        final distanceText = totalDistance >= 1000
            ? (totalDistance / 1000).toStringAsFixed(1)
            : totalDistance.toStringAsFixed(0);
        final distanceLabel = totalDistance >= 1000 ? '累计公里' : '累计米数';

        return Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.route,
                value: '${tracks.length}',
                label: '累计路线',
                color: AppColors.forest,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatItem(
                icon: Icons.terrain,
                value: distanceText,
                label: distanceLabel,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatItem(
                icon: Icons.trending_up,
                value: totalElevation.toStringAsFixed(0),
                label: '累计爬升',
                color: AppColors.lavender,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox(
        height: 100,
        child: Center(child: Text('加载失败')),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.data.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(allFavoritesProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 12),
      ),
      child: Column(
        children: [
          _FeatureItem(
            icon: Icons.history,
            title: '历史记录',
            subtitle: '查看所有爬山记录',
            color: AppColors.forest,
            onTap: () => context.push('/tracks'),
          ),
          const Divider(height: 1, indent: 68),
          achievementsAsync.when(
            data: (achievements) {
              final unlocked = achievements.where((a) => a.isUnlocked).length;
              return _FeatureItem(
                icon: Icons.emoji_events,
                title: '成就徽章',
                subtitle: '已获得 $unlocked 个徽章',
                color: AppColors.sun,
                onTap: () => context.push('/achievements'),
              );
            },
            loading: () => _FeatureItem(
              icon: Icons.emoji_events,
              title: '成就徽章',
              subtitle: '加载中...',
              color: AppColors.sun,
              onTap: null,
            ),
            error: (_, __) => _FeatureItem(
              icon: Icons.emoji_events,
              title: '成就徽章',
              subtitle: '加载失败',
              color: AppColors.sun,
              onTap: () => context.push('/achievements'),
            ),
          ),
          const Divider(height: 1, indent: 68),
          favoritesAsync.when(
            data: (favorites) => _FeatureItem(
              icon: Icons.bookmark,
              title: '收藏路线',
              subtitle: favorites.isEmpty
                  ? '暂无收藏路线'
                  : '已收藏 ${favorites.length} 条路线',
              color: AppColors.forest,
              onTap: () => context.push('/favorites'),
            ),
            loading: () => _FeatureItem(
              icon: Icons.bookmark,
              title: '收藏路线',
              subtitle: '加载中...',
              color: AppColors.forest,
              onTap: null,
            ),
            error: (_, __) => const _FeatureItem(
              icon: Icons.bookmark,
              title: '收藏路线',
              subtitle: '加载失败',
              color: AppColors.forest,
              onTap: null,
            ),
          ),
          const Divider(height: 1, indent: 68),
          _FeatureItem(
            icon: Icons.notifications_outlined,
            title: '通知设置',
            subtitle: '推送和提醒',
            color: AppColors.lavender,
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1, indent: 68),
          _FeatureItem(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            subtitle: '常见问题、联系客服',
            color: AppColors.inkMuted,
            onTap: () => context.push('/help'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    color: AppColors.inkMuted, size: 22)
              else
                const SizedBox(width: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('版本', style: AppTypography.body),
                const Spacer(),
                Text(
                  'v1.0.0',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showSimpleDialog(
                context,
                title: '用户协议',
                content: '欢迎使用爬山助手！\n\n'
                    '1. 本应用提供的路线信息仅供参考，实际出行请以现场情况为准。\n'
                    '2. 户外活动具有一定风险，请根据自身条件选择合适的路线。\n'
                    '3. 使用本应用即表示您同意我们的服务条款。',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.paperDark,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('用户协议', style: AppTypography.body),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.inkMuted, size: 22),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showSimpleDialog(
                context,
                title: '隐私政策',
                content: '我们重视您的隐私。\n\n'
                    '1. 本应用仅在本地存储您的轨迹数据、评价和收藏信息。\n'
                    '2. 位置信息仅用于路线推荐和轨迹记录功能。\n'
                    '3. 我们不会将您的个人数据上传至第三方服务器。',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.paperDark,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('隐私政策', style: AppTypography.body),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.inkMuted, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
