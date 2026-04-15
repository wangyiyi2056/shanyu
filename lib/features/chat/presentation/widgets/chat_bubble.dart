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
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.terrain,
                  size: 18,
                  color: Colors.white,
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: AppSpacing.sm),
          ],

          // 气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubble : AppColors.aiBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLg),
                  topRight: const Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(isUser ? AppSpacing.radiusLg : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : AppSpacing.radiusLg),
                ),
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
                        height: 1.5,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      h3: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.textPrimary,
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
                            : Colors.grey.withValues(alpha: 0.2),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
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
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textHint,
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
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
              )
            else
              const SizedBox(width: 32),
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
