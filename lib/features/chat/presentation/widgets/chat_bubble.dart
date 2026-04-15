import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  bool get isUser => message.role == MessageRole.user;
  bool get isSystem => message.role == MessageRole.system;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI 头像
          if (!isUser) ...[
            if (showAvatar)
              _Avatar(
                icon: isSystem ? Icons.info_outline : Icons.terrain,
                gradientColors: isSystem
                    ? const [AppColors.secondary, AppColors.secondaryLight]
                    : const [AppColors.primary, AppColors.primaryLight],
              )
            else
              const SizedBox(width: 36),
            const SizedBox(width: AppSpacing.sm),
          ],

          // 气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : (isSystem
                        ? AppColors.systemBubble
                        : AppColors.aiBubble),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLg),
                  topRight: const Radius.circular(AppSpacing.radiusLg),
                  bottomLeft:
                      Radius.circular(isUser ? AppSpacing.radiusLg : 6),
                  bottomRight:
                      Radius.circular(isUser ? 6 : AppSpacing.radiusLg),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 消息内容（Markdown 渲染）
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    onTapLink: (text, href, title) =>
                        _handleLinkTap(context, href),
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.3,
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.35,
                      ),
                      h3: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      code: TextStyle(
                        backgroundColor: isUser
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.textSecondary.withValues(alpha: 0.15),
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      blockquote: TextStyle(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border(
                          left: BorderSide(
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 时间戳
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 用户头像
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            if (showAvatar)
              const _Avatar(
                icon: Icons.person,
                gradientColors: [AppColors.accentSky, Color(0xFF38BDF8)],
              )
            else
              const SizedBox(width: 36),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleLinkTap(BuildContext context, String? href) {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不支持的链接类型')),
        );
      }
      return;
    }
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Avatar extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;

  const _Avatar({
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}
