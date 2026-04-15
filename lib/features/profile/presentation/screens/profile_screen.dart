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
          _SectionTitle(title: '我的记录', actionLabel: null, onAction: null),
          const SizedBox(height: AppSpacing.sm),
          const _StatsGrid(),

          const SizedBox(height: AppSpacing.lg),

          // 功能列表
          _SectionTitle(title: '功能', actionLabel: null, onAction: null),
          const SizedBox(height: AppSpacing.sm),
          _FeatureList(),

          const SizedBox(height: AppSpacing.lg),

          // 关于
          _SectionTitle(title: '关于', actionLabel: null, onAction: null),
          const SizedBox(height: AppSpacing.sm),
          const _AboutSection(),
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

void _showSimpleDialog(BuildContext context,
    {required String title, required String content}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
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

    return Container(
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  profileAsync.when(
                    data: (profile) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        profile.levelTitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Lv.1 初级选手',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

        final stats = [
          _StatData(
            icon: Icons.route,
            value: '${tracks.length}',
            label: '累计路线',
            gradient: const [AppColors.primary, AppColors.primaryLight],
          ),
          _StatData(
            icon: Icons.terrain,
            value: distanceText,
            label: distanceLabel,
            gradient: const [AppColors.accentDark, AppColors.accent],
          ),
          _StatData(
            icon: Icons.trending_up,
            value: totalElevation.toStringAsFixed(0),
            label: '累计爬升',
            gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
        ];

        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.95,
          children: stats.map((s) => _StatItem(data: s)).toList(),
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

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradient;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });
}

class _StatItem extends StatelessWidget {
  final _StatData data;

  const _StatItem({required this.data});

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
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(data.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              data.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
      child: Column(
        children: [
          _FeatureItem(
            icon: Icons.history,
            iconGradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            title: '历史记录',
            subtitle: '查看所有爬山记录',
            onTap: () => context.push('/tracks'),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          achievementsAsync.when(
            data: (achievements) {
              final unlocked = achievements.where((a) => a.isUnlocked).length;
              return _FeatureItem(
                icon: Icons.emoji_events,
                iconGradient: const [AppColors.accentDark, AppColors.accent],
                title: '成就徽章',
                subtitle: '已获得 $unlocked 个徽章',
                onTap: () => context.push('/achievements'),
              );
            },
            loading: () => const _FeatureItem(
              icon: Icons.emoji_events,
              iconGradient: [AppColors.accentDark, AppColors.accent],
              title: '成就徽章',
              subtitle: '加载中...',
              onTap: null,
            ),
            error: (_, __) => _FeatureItem(
              icon: Icons.emoji_events,
              iconGradient: const [AppColors.accentDark, AppColors.accent],
              title: '成就徽章',
              subtitle: '加载失败',
              onTap: () => context.push('/achievements'),
            ),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          favoritesAsync.when(
            data: (favorites) => _FeatureItem(
              icon: Icons.bookmark,
              iconGradient: const [AppColors.primary, AppColors.primaryLight],
              title: '收藏路线',
              subtitle:
                  favorites.isEmpty ? '暂无收藏路线' : '已收藏 ${favorites.length} 条路线',
              onTap: () => context.push('/favorites'),
            ),
            loading: () => const _FeatureItem(
              icon: Icons.bookmark,
              iconGradient: [AppColors.primary, AppColors.primaryLight],
              title: '收藏路线',
              subtitle: '加载中...',
              onTap: null,
            ),
            error: (_, __) => const _FeatureItem(
              icon: Icons.bookmark,
              iconGradient: [AppColors.primary, AppColors.primaryLight],
              title: '收藏路线',
              subtitle: '加载失败',
              onTap: null,
            ),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          _FeatureItem(
            icon: Icons.notifications_outlined,
            iconGradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            title: '通知设置',
            subtitle: '推送和提醒',
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16),
          _FeatureItem(
            icon: Icons.help_outline,
            iconGradient: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: iconGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textHint)
          : null,
      onTap: onTap,
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

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
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: Text('版本'),
            trailing: Text(
              'v1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: AppColors.textSecondary),
            title: const Text('用户协议'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () => _showSimpleDialog(
              context,
              title: '用户协议',
              content: '欢迎使用爬山助手！\n\n'
                  '1. 本应用提供的路线信息仅供参考，实际出行请以现场情况为准。\n'
                  '2. 户外活动具有一定风险，请根据自身条件选择合适的路线。\n'
                  '3. 使用本应用即表示您同意我们的服务条款。',
            ),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
            title: const Text('隐私政策'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textHint),
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
