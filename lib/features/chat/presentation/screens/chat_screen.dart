import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/speech_provider.dart';
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
    final speechState = ref.watch(speechNotifierProvider);

    // 监听语音识别结果，识别完成后自动发送
    ref.listen(speechNotifierProvider, (previous, next) {
      if (previous?.isListening == true &&
          next.isListening == false &&
          next.recognizedWords.isNotEmpty) {
        // 语音识别结束且有内容，自动发送
        ref.read(chatNotifierProvider.notifier).sendMessage(next.recognizedWords);
        _scrollToBottom();
      }
    });

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
          if (speechState.isAvailable)
            IconButton(
              icon: Icon(
                speechState.isSpeaking ? Icons.volume_up : Icons.volume_off,
                color: speechState.isSpeaking
                    ? AppColors.forest
                    : AppColors.inkMuted,
              ),
              onPressed: () {
                if (speechState.isSpeaking) {
                  ref.read(speechNotifierProvider.notifier).stopSpeaking();
                }
              },
              tooltip: speechState.isSpeaking ? '停止朗读' : '语音输出',
            ),
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

          // 语音识别中指示器
          if (speechState.isListening) _buildVoiceInputIndicator(speechState),

          // 快捷回复
          if (chatState.messages.isEmpty && !speechState.isListening)
            QuickReplies(
              onSelect: (text) {
                ref.read(chatNotifierProvider.notifier).sendMessage(text);
                _scrollToBottom();
              },
            ),

          // 输入框
          if (!speechState.isListening)
            InputBar(
              onSend: (content) {
                ref.read(chatNotifierProvider.notifier).sendMessage(content);
                _scrollToBottom();
              },
              onVoiceInput: () {
                ref.read(speechNotifierProvider.notifier).toggleListening();
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

  Widget _buildVoiceInputIndicator(SpeechState speechState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: AppColors.forest,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              speechState.recognizedWords.isEmpty
                  ? '正在聆听...'
                  : speechState.recognizedWords,
              style: AppTypography.body.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () {
                ref.read(speechNotifierProvider.notifier).cancelListening();
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('取消'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkMuted,
              ),
            ),
          ],
        ),
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
