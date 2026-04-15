import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/review_provider.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/achievements_provider.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/profile_provider.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 用户信息卡片
          const _UserInfoCard(),

          const SizedBox(height: AppSpacing.lg),

          // 统计数据
          _SectionHeader(
            title: '我的记录',
            icon: Icons.insights,
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _StatsGrid(),

          const SizedBox(height: AppSpacing.lg),

          // 功能列表
          _SectionHeader(
            title: '功能',
            icon: Icons.apps,
            iconColor: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeatureList(),

          const SizedBox(height: AppSpacing.lg),

          // 关于
          _SectionHeader(
            title: '关于',
            icon: Icons.info_outline,
            iconColor: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _AboutSection(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withValues(alpha: 0.2),
                iconColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

void _showSimpleDialog(BuildContext context,
    {required String title, required String content}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

class _UserInfoCard extends ConsumerWidget {
  const _UserInfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppColors.darkSurface,
                  AppColors.darkSurfaceVariant,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLighter,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileAsync.when(
                    data: (profile) => Text(
                      profile.nickname,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                    ),
                    loading: () => const SizedBox(
                      height: 24,
                      width: 100,
                      child: Center(
                        child: LinearProgressIndicator(minHeight: 8),
                      ),
                    ),
                    error: (_, __) => Text(
                      '爬山爱好者',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  profileAsync.when(
                    data: (profile) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        profile.levelTitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 16,
                      width: 80,
                      child: Center(
                        child: LinearProgressIndicator(minHeight: 6),
                      ),
                    ),
                    error: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Lv.1 初级选手',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/edit-profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: const Text('编辑'),
            ),
          ],
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
                gradient: const [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: Icons.terrain,
                value: distanceText,
                label: distanceLabel,
                gradient: const [AppColors.secondary, AppColors.secondaryLight],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: Icons.trending_up,
                value: totalElevation.toStringAsFixed(0),
                label: '累计爬升',
                gradient: const [AppColors.info, Color(0xFF60A5FA)],
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
  final List<Color> gradient;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLighter,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient[0].withValues(alpha: 0.15),
                  gradient[1].withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: gradient[0], size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLighter,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _FeatureItem(
            icon: Icons.history,
            iconGradient: const [AppColors.primary, AppColors.primaryLight],
            title: '历史记录',
            subtitle: '查看所有爬山记录',
            onTap: () => context.push('/tracks'),
          ),
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.textMuted,
          ),
          achievementsAsync.when(
            data: (achievements) {
              final unlocked = achievements.where((a) => a.isUnlocked).length;
              return _FeatureItem(
                icon: Icons.emoji_events,
                iconGradient: const [
                  AppColors.secondary,
                  AppColors.secondaryLight,
                ],
                title: '成就徽章',
                subtitle: '已获得 $unlocked 个徽章',
                onTap: () => context.push('/achievements'),
              );
            },
            loading: () => const _FeatureItem(
              icon: Icons.emoji_events,
              iconGradient: [
                AppColors.secondary,
                AppColors.secondaryLight,
              ],
              title: '成就徽章',
              subtitle: '加载中...',
              onTap: null,
            ),
            error: (_, __) => _FeatureItem(
              icon: Icons.emoji_events,
              iconGradient: const [
                AppColors.secondary,
                AppColors.secondaryLight,
              ],
              title: '成就徽章',
              subtitle: '加载失败',
              onTap: () => context.push('/achievements'),
            ),
          ),
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.textMuted,
          ),
          favoritesAsync.when(
            data: (favorites) => _FeatureItem(
              icon: Icons.bookmark,
              iconGradient: const [AppColors.accentRose, Color(0xFFFB923C)],
              title: '收藏路线',
              subtitle: favorites.isEmpty
                  ? '暂无收藏路线'
                  : '已收藏 ${favorites.length} 条路线',
              onTap: () => context.push('/favorites'),
            ),
            loading: () => const _FeatureItem(
              icon: Icons.bookmark,
              iconGradient: [AppColors.accentRose, Color(0xFFFB923C)],
              title: '收藏路线',
              subtitle: '加载中...',
              onTap: null,
            ),
            error: (_, __) => const _FeatureItem(
              icon: Icons.bookmark,
              iconGradient: [AppColors.accentRose, Color(0xFFFB923C)],
              title: '收藏路线',
              subtitle: '加载失败',
              onTap: null,
            ),
          ),
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.textMuted,
          ),
          _FeatureItem(
            icon: Icons.notifications_outlined,
            iconGradient: const [AppColors.accentViolet, Color(0xFFA78BFA)],
            title: '通知设置',
            subtitle: '推送和提醒',
            onTap: () => context.push('/settings'),
          ),
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.textMuted,
          ),
          _FeatureItem(
            icon: Icons.help_outline,
            iconGradient: const [AppColors.info, Color(0xFF60A5FA)],
            title: '帮助与反馈',
            subtitle: '常见问题、联系客服',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('帮助与反馈'),
                  content: const Text(
                    '如有问题或建议，请通过以下方式联系我们：\n\n'
                    '邮箱: support@hiking-assistant.app\n\n'
                    '我们会尽快回复您。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _FeatureItem({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: onTap,
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
                  gradient: LinearGradient(
                    colors: [
                      iconGradient[0].withValues(alpha: 0.15),
                      iconGradient[1].withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: iconGradient[0], size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLighter,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _AboutItem(
            icon: Icons.info_outline,
            iconColor: AppColors.textSecondary,
            title: '版本',
            trailing: Text(
              'v1.0.0',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.textMuted,
          ),
          _AboutItem(
            icon: Icons.description_outlined,
            iconColor: AppColors.textSecondary,
            title: '用户协议',
            onTap: () => _showSimpleDialog(
              context,
              title: '用户协议',
              content: '欢迎使用爬山助手！\n\n'
                  '1. 本应用提供的路线信息仅供参考，实际出行请以现场情况为准。\n'
                  '2. 户外活动具有一定风险，请根据自身条件选择合适的路线。\n'
                  '3. 使用本应用即表示您同意我们的服务条款。',
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.textMuted,
          ),
          _AboutItem(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.textSecondary,
            title: '隐私政策',
            onTap: () => _showSimpleDialog(
              context,
              title: '隐私政策',
              content: '我们重视您的隐私。\n\n'
                  '1. 本应用仅在本地存储您的轨迹数据、评价和收藏信息。\n'
                  '2. 位置信息仅用于路线推荐和轨迹记录功能。\n'
                  '3. 我们不会将您的个人数据上传至第三方服务器。',
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _AboutItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
