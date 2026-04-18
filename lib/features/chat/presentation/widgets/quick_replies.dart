import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';

class QuickReplies extends StatelessWidget {
  final Function(String)? onSelect;

  const QuickReplies({super.key, this.onSelect});

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
          return _QuickReplyChip(
            label: reply,
            onTap: onSelect != null ? () => onSelect!(reply) : null,
          );
        }).toList(),
      ),
    );
  }
}

class _QuickReplyChip extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuickReplyChip({required this.label, this.onTap});

  @override
  State<_QuickReplyChip> createState() => _QuickReplyChipState();
}

class _QuickReplyChipState extends State<_QuickReplyChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.forest.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: _isPressed
                ? AppColors.forest
                : const Color(0xFFD6D3D1),
          ),
        ),
        child: Text(
          widget.label,
          style: AppTypography.bodySmall.copyWith(
            color: _isPressed ? AppColors.forest : AppColors.inkLight,
            fontWeight: _isPressed ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
