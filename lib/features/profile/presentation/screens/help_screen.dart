import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text('帮助与反馈', style: AppTypography.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 联系卡片
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.forest, AppColors.forestLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '遇到问题？',
                    style: AppTypography.title.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '我们随时为您提供帮助',
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'support@hiking-assistant.app',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 常见问题
          Text(
            '常见问题',
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
                _FaqTile(
                  question: '如何开始记录轨迹？',
                  answer:
                      '进入地图页面，点击右下角的红色录制按钮即可开始记录您的爬山轨迹。',
                ),
                const Divider(height: 1, indent: 68),
                _FaqTile(
                  question: '数据会同步到云端吗？',
                  answer:
                      '目前所有轨迹数据、收藏和评价都仅在本地存储，不会上传到任何服务器。',
                ),
                const Divider(height: 1, indent: 68),
                _FaqTile(
                  question: '如何收藏喜欢的路线？',
                  answer:
                      '在路线详情页点击右上角的心形图标即可收藏，收藏的路线可以在个人页的"收藏路线"中查看。',
                ),
                const Divider(height: 1, indent: 68),
                _FaqTile(
                  question: '地图加载慢怎么办？',
                  answer:
                      '请检查网络连接，或尝试放大地图区域以减少瓦片加载数量。',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 反馈入口
          Text(
            '提交反馈',
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
                _FeedbackTile(
                  icon: Icons.bug_report_outlined,
                  color: AppColors.error,
                  title: '功能异常',
                  subtitle: '遇到 Bug 请告诉我们',
                  onTap: () => _showFeedbackSent(context, '功能异常'),
                ),
                const Divider(height: 1, indent: 68),
                _FeedbackTile(
                  icon: Icons.lightbulb_outline,
                  color: AppColors.sun,
                  title: '产品建议',
                  subtitle: '期待听到您的想法',
                  onTap: () => _showFeedbackSent(context, '产品建议'),
                ),
                const Divider(height: 1, indent: 68),
                _FeedbackTile(
                  icon: Icons.rate_review_outlined,
                  color: AppColors.lavender,
                  title: '评价应用',
                  subtitle: '前往应用商店评分',
                  onTap: () => _showFeedbackSent(context, '评价应用'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSent(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('感谢反馈：$type'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.forest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(Icons.help_outline,
              color: AppColors.forest, size: 20),
        ),
        title: Text(
          question,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              68,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              answer,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeedbackTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 20),
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
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inkMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
