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
          Text(
            '我的记录',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _StatsGrid(),

          const SizedBox(height: AppSpacing.lg),

          // 功能列表
          Text(
            '功能',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeatureList(),

          const SizedBox(height: AppSpacing.lg),

          // 关于
          Text(
            '关于',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _AboutSection(),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person,
                size: 40,
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
                      style: Theme.of(context).textTheme.titleLarge,
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  profileAsync.when(
                    data: (profile) => Text(
                      profile.levelTitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    loading: () => const SizedBox(
                      height: 16,
                      width: 80,
                      child: Center(
                        child: LinearProgressIndicator(minHeight: 6),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Lv.1 初级选手',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/edit-profile'),
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

        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.2,
          children: [
            _StatItem(
              icon: Icons.route,
              value: '${tracks.length}',
              label: '累计路线',
              color: AppColors.primary,
            ),
            _StatItem(
              icon: Icons.terrain,
              value: distanceText,
              label: distanceLabel,
              color: AppColors.secondary,
            ),
            _StatItem(
              icon: Icons.trending_up,
              value: totalElevation.toStringAsFixed(0),
              label: '累计爬升',
              color: AppColors.info,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
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

    return Card(
      child: Column(
        children: [
          _FeatureItem(
            icon: Icons.history,
            title: '历史记录',
            subtitle: '查看所有爬山记录',
            onTap: () => context.push('/tracks'),
          ),
          const Divider(height: 1),
          achievementsAsync.when(
            data: (achievements) {
              final unlocked = achievements.where((a) => a.isUnlocked).length;
              return _FeatureItem(
                icon: Icons.emoji_events,
                title: '成就徽章',
                subtitle: '已获得 $unlocked 个徽章',
                onTap: () => context.push('/achievements'),
              );
            },
            loading: () => const _FeatureItem(
              icon: Icons.emoji_events,
              title: '成就徽章',
              subtitle: '加载中...',
              onTap: null,
            ),
            error: (_, __) => _FeatureItem(
              icon: Icons.emoji_events,
              title: '成就徽章',
              subtitle: '加载失败',
              onTap: () => context.push('/achievements'),
            ),
          ),
          const Divider(height: 1),
          favoritesAsync.when(
            data: (favorites) => _FeatureItem(
              icon: Icons.bookmark,
              title: '收藏路线',
              subtitle:
                  favorites.isEmpty ? '暂无收藏路线' : '已收藏 ${favorites.length} 条路线',
              onTap: () => context.push('/favorites'),
            ),
            loading: () => const _FeatureItem(
              icon: Icons.bookmark,
              title: '收藏路线',
              subtitle: '加载中...',
              onTap: null,
            ),
            error: (_, __) => const _FeatureItem(
              icon: Icons.bookmark,
              title: '收藏路线',
              subtitle: '加载失败',
              onTap: null,
            ),
          ),
          const Divider(height: 1),
          _FeatureItem(
            icon: Icons.notifications_outlined,
            title: '通知设置',
            subtitle: '推送和提醒',
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1),
          _FeatureItem(
            icon: Icons.help_outline,
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
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
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
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            trailing: Text(
              'v1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
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
