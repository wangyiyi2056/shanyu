import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hiking_assistant/core/constants/app_constants.dart';
import 'package:hiking_assistant/features/chat/domain/tools/chat_tool.dart';

/// Anthropic Claude API 服务
///
/// 使用官方 Anthropic Claude API 格式：
/// - Endpoint: /v1/messages
/// - Headers: x-api-key, anthropic-version
/// - 支持 Prompt Caching 降低成本
/// - 支持 Extended Thinking (adaptive)
class ClaudeAPIService {
  ClaudeAPIService._();

  static ClaudeAPIService get instance => ClaudeAPIService._();

  // Anthropic API 配置
  static const String _apiUrl = AppConstants.claudeApiUrl;
  static const String _apiKey = AppConstants.claudeApiKey;
  static const String _model = AppConstants.claudeModel;
  static const String _apiVersion = '2023-06-01';

  /// 发送消息 (Anthropic Claude API 格式)
  ///
  /// 支持 Prompt Caching:
  /// - 系统提示和工具定义缓存（5分钟或1小时 TTL）
  /// - 验证缓存命中率: cache_read_input_tokens
  Future<ClaudeResponse> sendMessage({
    required String systemPrompt,
    required List<ClaudeMessage> conversationHistory,
    required String userMessage,
    int maxTokens = 16000,
    bool enableCaching = true,
    bool enableThinking = false,
    List<ChatTool>? tools,
  }) async {
    try {
      // 构建 Anthropic 格式的消息数组
      // Anthropic 格式: messages 只包含 user 和 assistant，不含 system
      final messages = <Map<String, dynamic>>[];

      // 添加历史消息
      for (final msg in conversationHistory) {
        messages.add({
          'role': msg.role,
          'content': msg.content,
        });
      }

      // 添加当前用户消息
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // 构建请求体
      final requestBody = <String, dynamic>{
        'model': _model,
        'max_tokens': maxTokens,
        'messages': messages,
      };

      // 添加系统提示（Anthropic 格式）
      // 支持 Prompt Caching: 在系统提示块添加 cache_control
      if (systemPrompt.isNotEmpty) {
        if (enableCaching && systemPrompt.length > 1000) {
          // 使用缓存控制 - 大型系统提示
          requestBody['system'] = [
            {
              'type': 'text',
              'text': systemPrompt,
              'cache_control': {'type': 'ephemeral'},
            },
          ];
        } else {
          requestBody['system'] = systemPrompt;
        }
      }

      // 添加 Extended Thinking (adaptive mode for Opus 4.6+)
      if (enableThinking) {
        requestBody['thinking'] = {'type': 'adaptive'};
        requestBody['output_config'] = {'effort': 'high'};
      }

      // 添加工具定义 (Anthropic tools format)
      if (tools != null && tools.isNotEmpty) {
        requestBody['tools'] = tools.map((t) => t.toAnthropicSchema()).toList();
        // 对工具定义启用缓存
        if (enableCaching) {
          for (final tool in requestBody['tools']) {
            tool['cache_control'] = {'type': 'ephemeral'};
          }
        }
      }

      // 发送请求
      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw ClaudeAPIException(
            code: 'timeout',
            message: '请求超时，请检查网络连接',
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseAnthropicResponse(data);
      } else if (response.statusCode == 401) {
        throw ClaudeAPIException(
          code: 'authentication_error',
          message: 'API Key 无效或未配置',
        );
      } else if (response.statusCode == 429) {
        throw ClaudeAPIException(
          code: 'rate_limit_error',
          message: '请求频率超限，请稍后重试',
        );
      } else if (response.statusCode >= 500) {
        throw ClaudeAPIException(
          code: 'api_error',
          message: '服务器错误，请稍后重试',
        );
      } else {
        // 解析错误信息
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorData['error'] as Map<String, dynamic>?;
          throw ClaudeAPIException(
            code: 'invalid_request_error',
            message: error?['message'] ?? '请求错误: ${response.statusCode}',
          );
        } on Exception catch (_) {
          throw ClaudeAPIException(
            code: 'unknown_error',
            message: '未知错误: ${response.statusCode}',
          );
        }
      }
    } on ClaudeAPIException catch (e) {
      // 返回演示响应作为 fallback
      return _getDemoResponse(userMessage, errorMessage: e.message);
    } on Exception catch (_) {
      return _getDemoResponse(userMessage);
    }
  }

  /// 解析 Anthropic Claude API 响应
  ClaudeResponse _parseAnthropicResponse(Map<String, dynamic> data) {
    final contentBlocks = data['content'] as List?;
    final usage = data['usage'] as Map<String, dynamic>?;

    final content = <ClaudeContentBlock>[];

    if (contentBlocks != null) {
      for (final block in contentBlocks) {
        final blockType = block['type'] as String?;
        if (blockType == 'text') {
          content.add(ClaudeContentBlock(
            type: 'text',
            text: block['text'] as String? ?? '',
          ));
        } else if (blockType == 'thinking') {
          content.add(ClaudeContentBlock(
            type: 'thinking',
            text: block['thinking'] as String? ?? '',
          ));
        } else if (blockType == 'tool_use') {
          content.add(ClaudeContentBlock(
            type: 'tool_use',
            text: block['name'] as String? ?? '',
            toolName: block['name'] as String?,
            toolInput: block['input'] as Map<String, dynamic>?,
            toolUseId: block['id'] as String?,
          ));
        }
      }
    }

    return ClaudeResponse(
      content: content,
      model: data['model'] ?? _model,
      id: data['id'] as String?,
      usage: usage != null
          ? ClaudeUsage(
              inputTokens: usage['input_tokens'] as int? ?? 0,
              outputTokens: usage['output_tokens'] as int? ?? 0,
              cacheCreationInputTokens:
                  usage['cache_creation_input_tokens'] as int? ?? 0,
              cacheReadInputTokens:
                  usage['cache_read_input_tokens'] as int? ?? 0,
            )
          : null,
      stopReason: data['stop_reason'] as String?,
    );
  }

  /// 演示模式响应（API 不可用时使用）
  ClaudeResponse _getDemoResponse(
    String userMessage, {
    String? errorMessage,
  }) {
    final content = _generateDemoResponse(userMessage, errorMessage: errorMessage);
    return ClaudeResponse(
      content: [ClaudeContentBlock(type: 'text', text: content)],
      model: _model,
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      stopReason: 'end_turn',
    );
  }

  /// 生成演示响应内容
  String _generateDemoResponse(String userMessage, {String? errorMessage}) {
    final lowerInput = userMessage.toLowerCase();
    final prefix = errorMessage != null ? '⚠️ $errorMessage\n\n' : '';

    if (lowerInput.contains('天气')) {
      return '''$prefix📍 **香山公园** 天气预报

🌤️ 今日: 多云转晴
   气温: 15°C - 23°C
   风力: 东南风 2-3级
   空气质量: 优

⏰ 建议出行时间:
   上午 9:00 - 11:00
   下午 14:00 - 16:00

⚠️ 温馨提示:
   • 今天天气适宜爬山
   • 建议携带外套
   • 注意防晒

需要我帮你规划具体行程吗？''';
    }

    if (lowerInput.contains('路线') ||
        lowerInput.contains('爬山') ||
        lowerInput.contains('山')) {
      return '''$prefix根据你的位置，我为你找到以下附近路线：

🏔️ **香山公园** (北京)
   距离: 2.3km | 难度: ⭐⭐ 简单
   预计时间: 1.5小时
   特色: 红叶节(11月)、有缆车

🏔️ **百望山** (北京)
   距离: 3.5km | 难度: ⭐⭐⭐ 中等
   预计时间: 2.5小时
   特色: 人少景美、全览北京

🏔️ **凤凰岭** (北京)
   距离: 5.2km | 难度: ⭐⭐⭐⭐ 较难
   预计时间: 4小时
   特色: 自然风光、挑战性强

你想了解哪个路线的详细信息？''';
    }

    if (lowerInput.contains('推荐') || lowerInput.contains('新手')) {
      return '''$prefix根据你的情况（初次爬山），我推荐：

🥇 **香山亲子路线**
   • 难度: ⭐⭐ 简单
   • 距离: 2.3km
   • 时间: 1.5小时
   • 特色: 有缆车回程、适合新手

👍 推荐理由:
   1. 路线成熟，标识清晰
   2. 有多处休息点
   3. 景色优美，红叶季更佳
   4. 交通便利（地铁直达）

需要我帮你导航过去吗？''';
    }

    if (lowerInput.contains('导航') || lowerInput.contains('去')) {
      return '''$prefix🧭 开始导航到 **香山公园**

📍 起点: 你的当前位置
📍 终点: 香山公园东门

🚗 驾车路线:
   距离: 12km | 预计: 25分钟

🚌 公交路线:
   乘坐 360路/318路 到香山站
   预计: 45分钟

🚶 步行导航已开启
   请沿着这条路直行...

需要我开始记录轨迹吗？''';
    }

    return '''$prefix好的，我明白了！

作为你的爬山助手，我可以帮你：
• 查路线、查天气
• 做行程规划
• 记录轨迹
• 提供安全提醒

还有什么需要帮忙的吗？''';
  }

  /// 计算缓存节省成本
  ///
  /// 返回估算的节省百分比
  double calculateCacheSavings(ClaudeUsage? usage) {
    if (usage == null) return 0;

    final totalInput = usage.inputTokens +
        usage.cacheCreationInputTokens +
        usage.cacheReadInputTokens;

    if (totalInput == 0) return 0;

    // 缓存读取成本约 0.1x，写入成本约 1.25x (5分钟 TTL)
    final savedTokens = usage.cacheReadInputTokens;
    return (savedTokens / totalInput) * 100;
  }
}

/// Claude 消息（Anthropic 格式）
class ClaudeMessage {
  final String role; // 'user' 或 'assistant'
  final String content;

  const ClaudeMessage({required this.role, required this.content});
}

/// Claude 响应（Anthropic 格式）
class ClaudeResponse {
  final List<ClaudeContentBlock> content;
  final String model;
  final String? id;
  final ClaudeUsage? usage;
  final String? stopReason;

  ClaudeResponse({
    required this.content,
    required this.model,
    this.id,
    this.usage,
    this.stopReason,
  });

  /// 获取文本内容
  String get textContent {
    final textBlock = content.where((b) => b.type == 'text').firstOrNull;
    return textBlock?.text ?? '';
  }

  /// 获取思考内容
  String get thinkingContent {
    final thinkingBlock = content.where((b) => b.type == 'thinking').firstOrNull;
    return thinkingBlock?.text ?? '';
  }

  /// 获取工具调用块
  List<ClaudeContentBlock> get toolUseBlocks {
    return content.where((b) => b.type == 'tool_use').toList();
  }

  /// 是否包含工具调用
  bool get hasToolUse => toolUseBlocks.isNotEmpty;

  /// 是否为缓存命中
  bool get isCacheHit => (usage?.cacheReadInputTokens ?? 0) > 0;
}

/// Claude 内容块（Anthropic 格式）
class ClaudeContentBlock {
  final String type; // 'text', 'thinking', 'tool_use'
  final String text;
  final String? toolName;
  final Map<String, dynamic>? toolInput;
  final String? toolUseId;

  const ClaudeContentBlock({
    required this.type,
    required this.text,
    this.toolName,
    this.toolInput,
    this.toolUseId,
  });

  bool get isToolUse => type == 'tool_use';
}

/// Claude 使用统计（Anthropic 格式）
class ClaudeUsage {
  final int inputTokens;
  final int outputTokens;
  final int cacheCreationInputTokens;
  final int cacheReadInputTokens;

  const ClaudeUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheCreationInputTokens = 0,
    this.cacheReadInputTokens = 0,
  });

  /// 总输入 tokens（包含缓存）
  int get totalInputTokens =>
      inputTokens + cacheCreationInputTokens + cacheReadInputTokens;
}

/// Claude API 异常
class ClaudeAPIException implements Exception {
  final String code;
  final String message;

  const ClaudeAPIException({required this.code, required this.message});

  @override
  String toString() => 'ClaudeAPIException($code): $message';
}