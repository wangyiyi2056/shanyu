import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';

class InputBar extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onVoiceInput;
  final VoidCallback? onCameraInput;

  const InputBar({
    super.key,
    required this.onSend,
    this.onVoiceInput,
    this.onCameraInput,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 功能按钮
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: InkWell(
              onTap: () => _showAttachmentMenu(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.inkMuted,
                  size: 26,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // 文本输入框
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 120,
                minHeight: 48,
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.inkMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.paperDark,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // 发送按钮
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _hasText ? AppColors.forest : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: InkWell(
                onTap: _hasText ? _handleSend : null,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: _hasText
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.forest, AppColors.forestLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        )
                      : null,
                  child: Icon(
                    Icons.send,
                    color: _hasText ? Colors.white : AppColors.inkMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AttachmentTile(
                  icon: Icons.photo_camera,
                  label: '拍照',
                  subtitle: '识别植物或风景',
                  color: AppColors.forest,
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1, indent: 68),
                _AttachmentTile(
                  icon: Icons.photo_library,
                  label: '相册',
                  subtitle: '从照片中选择',
                  color: AppColors.orange,
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1, indent: 68),
                _AttachmentTile(
                  icon: Icons.location_on,
                  label: '发送位置',
                  subtitle: '分享当前位置',
                  color: AppColors.lavender,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.body),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
