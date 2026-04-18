import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:hiking_assistant/features/chat/presentation/widgets/input_bar.dart';
import 'package:hiking_assistant/features/chat/presentation/widgets/quick_replies.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _initialMessageSent = false;

  @override
  void initState() {
    super.initState();
    final initialMessage = widget.initialMessage;
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialMessageSent && mounted) {
          _initialMessageSent = true;
          ref.read(chatNotifierProvider.notifier).sendMessage(initialMessage);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
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
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('爬山助手', style: AppTypography.title),
                Text(
                  '你的户外向导',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.ink),
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).clearConversation();
            },
            tooltip: '清除对话',
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(chatState),
          ),

          // 加载指示器
          if (chatState.isLoading) _buildLoadingIndicator(),

          // 快捷回复
          if (chatState.messages.isEmpty)
            QuickReplies(
              onSelect: (text) {
                ref.read(chatNotifierProvider.notifier).sendMessage(text);
                _scrollToBottom();
              },
            ),

          // 输入框
          InputBar(
            onSend: (content) {
              ref.read(chatNotifierProvider.notifier).sendMessage(content);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(140, 80),
            painter: _MountainRangePainter(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '你好，我是爬山助手',
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '有什么我可以帮你的吗？',
            style: AppTypography.body.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final showAvatar =
            index == 0 || state.messages[index - 1].role != message.role;

        return ChatBubble(
          key: ValueKey(message.id),
          message: message,
          showAvatar: showAvatar,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.aiBubble,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.paperDark,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.inkMuted,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '思考中...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainRangePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.15, size.height * 0.55)
      ..lineTo(size.width * 0.35, size.height * 0.8)
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width * 0.85, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final detailPaint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 左峰雪线
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.22, size.height * 0.68),
      detailPaint,
    );
    // 主峰雪线
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.58, size.height * 0.5),
      detailPaint,
    );
    // 右峰雪线
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.62),
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
