import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';

class QuickReplies extends StatelessWidget {
  const QuickReplies({super.key});

  static const _replies = [
    '附近有什么山可以爬？',
    '今天天气怎么样？',
    '推荐一条适合新手的路线',
    '帮我导航到香山',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.center,
        children: _replies.map((reply) {
          return _QuickReplyChip(label: reply);
        }).toList(),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;

  const _QuickReplyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.light
          ? AppColors.surfaceVariant
          : AppColors.darkSurfaceVariant,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: () {
          // 通过回调传递点击的快捷回复
          // 这个需要在父组件中处理
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ),
      ),
    );
  }
}
