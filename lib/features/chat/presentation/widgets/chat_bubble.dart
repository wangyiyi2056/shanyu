import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/speech_provider.dart';

class ChatBubble extends ConsumerWidget {
  final Message message;
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  bool get isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.forest, AppColors.forestLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
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
                maxWidth: MediaQuery.of(context).size.width * 0.78,
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
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
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
                      p: AppTypography.body.copyWith(
                        height: 1.55,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      h1: AppTypography.headline.copyWith(
                        fontSize: 20,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      h2: AppTypography.title.copyWith(
                        fontSize: 18,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      h3: AppTypography.title.copyWith(
                        fontSize: 16,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      strong: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      em: AppTypography.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      code: TextStyle(
                        backgroundColor: isUser
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFE7E5E4),
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFF292524),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      listBullet: AppTypography.body.copyWith(
                        color: isUser ? Colors.white : AppColors.ink,
                      ),
                      blockquote: AppTypography.body.copyWith(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.inkLight,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.paperDark,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border(
                          left: BorderSide(
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.4)
                                : AppColors.forest,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Cards
                  if (message.actionCards.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildActionCards(context, message.actionCards),
                  ],

                  // 时间戳 + 朗读按钮
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.inkMuted,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: AppSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            final text = message.content
                                .replaceAll(RegExp(r'[*#_\[\]\(\)]'), ' ')
                                .trim();
                            ref.read(speechNotifierProvider.notifier).speak(text);
                          },
                          child: Icon(
                            Icons.volume_up,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 用户头像
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            if (showAvatar)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.ink,
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

  Widget _buildActionCards(BuildContext context, List<ActionCard> cards) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: cards.map((card) {
        return GestureDetector(
          onTap: () => _handleActionCardTap(context, card),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.forest, AppColors.forestLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.touch_app,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  card.label,
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleActionCardTap(BuildContext context, ActionCard card) {
    switch (card.type) {
      case ActionCardType.button:
        if (card.action.startsWith('/')) {
          context.push(card.action);
        } else {
          // 处理其他 action 类型
        }
      case ActionCardType.link:
        _handleLinkTap(context, card.action);
      case ActionCardType.input:
      // 输入类型暂不处理
    }
  }
}
