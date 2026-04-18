import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/profile/data/datasources/settings_local_datasource.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/settings_provider.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeProvider);
    final notificationsAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text('设置', style: AppTypography.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 外观设置
          Text(
            '外观',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 12),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.brightness_medium,
                  iconColor: AppColors.sun,
                  title: '主题模式',
                  subtitle: themeAsync.when(
                    data: (mode) => switch (mode) {
                      ThemeMode.light => '浅色',
                      ThemeMode.dark => '深色',
                      ThemeMode.system => '跟随系统',
                    },
                    loading: () => '加载中...',
                    error: (_, __) => '加载失败',
                  ),
                  onTap: () => _showThemeModeDialog(
                    context,
                    ref,
                    themeAsync.valueOrNull ?? ThemeMode.system,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 通知设置
          Text(
            '通知',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.lavender,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '接收通知',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '活动和推荐提醒',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  value: notificationsAsync.valueOrNull ?? true,
                  onChanged: notificationsAsync.isLoading
                      ? null
                      : (value) async {
                          await ref
                              .read(settingsActionsProvider.notifier)
                              .setNotificationsEnabled(value);
                          ref.invalidate(notificationsEnabledProvider);
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 数据管理
          Text(
            '数据管理',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 12),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.delete_outline,
                  iconColor: AppColors.error,
                  title: '清除所有轨迹数据',
                  subtitle: '删除本地保存的所有轨迹记录',
                  onTap: () => _showClearTracksDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 账户
          Text(
            '账户',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 12),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.logout,
                  iconColor: AppColors.error,
                  title: '退出登录',
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 关于
          Text(
            '关于',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 12),
            ),
            child: Column(
              children: [
                const _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.ink,
                  title: '版本',
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ),
                const Divider(height: 1, indent: 68),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.ink,
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
                const Divider(height: 1, indent: 68),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.ink,
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
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(
      BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('选择主题', style: AppTypography.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeModeOption(
              title: '跟随系统',
              selected: currentMode == ThemeMode.system,
              onTap: () => _applyThemeMode(context, ref, ThemeMode.system),
            ),
            _ThemeModeOption(
              title: '浅色模式',
              selected: currentMode == ThemeMode.light,
              onTap: () => _applyThemeMode(context, ref, ThemeMode.light),
            ),
            _ThemeModeOption(
              title: '深色模式',
              selected: currentMode == ThemeMode.dark,
              onTap: () => _applyThemeMode(context, ref, ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyThemeMode(
      BuildContext context, WidgetRef ref, ThemeMode mode) async {
    Navigator.of(context).pop();
    final appMode = switch (mode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    };
    await ref.read(settingsActionsProvider.notifier).setThemeMode(appMode);
    ref.invalidate(themeModeProvider);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('退出登录', style: AppTypography.title),
        content: Text('确定要退出登录吗？', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showClearTracksDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('清除轨迹数据', style: AppTypography.title),
        content: Text(
          '确定要删除所有轨迹记录吗？此操作不可恢复。',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(trackRepositoryProvider).clearAllTracks();
              ref.invalidate(tracksProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有轨迹数据已清除')),
                );
              }
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
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
}

class _ThemeModeOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? AppColors.forest : AppColors.inkMuted,
      ),
      title: Text(title, style: AppTypography.body),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? const Icon(
                          Icons.chevron_right,
                          color: AppColors.inkMuted,
                          size: 22,
                        )
                      : const SizedBox(width: 22)),
            ],
          ),
        ),
      ),
    );
  }
}
