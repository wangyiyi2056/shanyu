import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 本地 OpenAI 兼容 API 服务
class ClaudeAPIService {
  ClaudeAPIService._();

  static ClaudeAPIService get instance => ClaudeAPIService._();

  // 本地 API 配置
  static const String _apiUrl = 'http://127.0.0.1:8000/v1/chat/completions';
  static const String _apiKey = '123456';
  static const String _model = 'gemma-4-e4b-it-8bit';

  /// 发送消息
  Future<ClaudeResponse> sendMessage({
    required String systemPrompt,
    required List<ClaudeMessage> conversationHistory,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    try {
      // 构建 OpenAI 格式的消息
      final messages = <Map<String, String>>[];

      // 添加系统提示
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

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

      debugPrint('[LocalAPI] Sending request to $_apiUrl');
      debugPrint('[LocalAPI] Model: $_model');
      debugPrint('[LocalAPI] Messages: ${messages.length}');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('请求超时，请检查本地模型服务是否运行');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[LocalAPI] Response: ${data.toString().substring(0, 200)}...');
        return _parseOpenAIResponse(data);
      } else {
        debugPrint('[LocalAPI] Error: ${response.statusCode} - ${response.body}');
        return _getDemoResponse(userMessage);
      }
    } catch (e) {
      debugPrint('[LocalAPI] Exception: $e');
      return _getDemoResponse(userMessage);
    }
  }

  /// 解析 OpenAI 格式响应
  ClaudeResponse _parseOpenAIResponse(Map<String, dynamic> data) {
    try {
      // OpenAI 格式的响应
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final firstChoice = choices[0];
        final message = firstChoice['message'] as Map<String, dynamic>?;
        if (message != null) {
          final content = message['content'] as String? ?? '';
          return ClaudeResponse(
            content: [ClaudeContent(type: 'text', text: content)],
            model: data['model'] ?? _model,
          );
        }
      }

      // 如果解析失败，返回默认响应
      return _getDemoResponse('请稍后');
    } catch (e) {
      debugPrint('[LocalAPI] Parse error: $e');
      return _getDemoResponse('请稍后');
    }
  }

  /// 演示模式响应
  ClaudeResponse _getDemoResponse(String userMessage) {
    final content = _generateDemoResponse(userMessage);
    return ClaudeResponse(
      content: [ClaudeContent(type: 'text', text: content)],
      model: _model,
    );
  }

  String _generateDemoResponse(String userMessage) {
    final lowerInput = userMessage.toLowerCase();

    if (lowerInput.contains('天气')) {
      return '''📍 **香山公园** 天气预报

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

    if (lowerInput.contains('路线') || lowerInput.contains('爬山') || lowerInput.contains('山')) {
      return '''根据你的位置，我为你找到以下附近路线：

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
      return '''根据你的情况（初次爬山），我推荐：

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
      return '''🧭 开始导航到 **香山公园**

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

    return '''好的，我明白了！

作为你的爬山助手，我可以帮你：
• 查路线、查天气
• 做行程规划
• 记录轨迹
• 提供安全提醒

还有什么需要帮忙的吗？''';
  }
}

/// Claude 消息
class ClaudeMessage {
  final String role;
  final String content;

  ClaudeMessage({required this.role, required this.content});
}

/// Claude 响应
class ClaudeResponse {
  final List<ClaudeContent> content;
  final String model;
  final String? id;

  ClaudeResponse({
    required this.content,
    required this.model,
    this.id,
  });

  String get textContent => content.isNotEmpty ? content.first.text : '';
}

class ClaudeContent {
  final String type;
  final String text;

  ClaudeContent({required this.type, required this.text});
}
