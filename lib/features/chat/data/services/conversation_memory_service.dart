import 'package:hiking_assistant/features/chat/data/datasources/conversation_local_datasource.dart';
import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/features/chat/domain/entities/intent.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';

/// 对话记忆服务
///
/// 负责：
/// 1. 持久化存储对话历史
/// 2. 生成对话摘要（使用 Claude API）
/// 3. 提取用户偏好和习惯
/// 4. 构建记忆上下文供后续对话使用
class ConversationMemoryService {
  final ConversationLocalDatasource _localDatasource;
  final ClaudeAPIService _claudeAPI;

  ConversationMemoryService({
    required ConversationLocalDatasource localDatasource,
    required ClaudeAPIService claudeAPI,
  })  : _localDatasource = localDatasource,
        _claudeAPI = claudeAPI;

  /// 保存对话消息
  Future<void> saveMessages(List<Message> messages) async {
    await _localDatasource.saveConversationHistory(messages);
  }

  /// 加载历史对话
  Future<List<Message>> loadHistory() async {
    return _localDatasource.loadConversationHistory();
  }

  /// 加载用户画像
  Future<UserMemoryProfile?> loadUserProfile() async {
    return _localDatasource.loadUserProfile();
  }

  /// 生成对话摘要并提取用户画像
  ///
  /// 在对话结束时调用，提取用户的偏好和习惯
  Future<UserMemoryProfile?> generateUserProfile(
    List<Message> messages,
  ) async {
    if (messages.length < 4) return null; // 对话太短，不生成摘要

    try {
      // 只取用户消息进行分析
      final userMessages = messages
          .where((m) => m.role == MessageRole.user)
          .map((m) => m.content)
          .join('\n');

      final systemPrompt = '你是一个对话分析专家，负责从用户的对话中提取用户的偏好、习惯和画像信息。\n\n'
          '## 提取维度\n'
          '1. **体能水平**：新手/偶尔运动/经常运动/专业\n'
          '2. **路线偏好**：喜欢的难度、距离、时长\n'
          '3. **常去地点**：经常提到的山或公园\n'
          '4. **关注点**：安全、风景、挑战、社交等\n'
          '5. **不喜欢的事物**：明确表达过不喜欢的东西\n\n'
          '## 输出格式\n'
          '使用以下 JSON 格式输出（不要添加其他内容）：\n\n'
          '{\n'
          '  "preferredDifficulty": "新手|简单|中等|困难|专家",\n'
          '  "preferredDistance": "短途|中程|长途",\n'
          '  "preferredDuration": "短时间|半天|全天",\n'
          '  "fitnessLevel": "新手|初级|中级|高级|专业",\n'
          '  "favoriteRoutes": ["路线名称1", "路线名称2"],\n'
          '  "commonConcerns": "用户最常关心的问题"\n'
          '}\n\n'
          '如果某个维度无法确定，使用 null。';

      final response = await _claudeAPI.sendMessage(
        systemPrompt: systemPrompt,
        conversationHistory: const [],
        userMessage: '请分析以下用户消息，提取用户画像：\n\n$userMessages',
        maxTokens: 1024,
        enableCaching: false,
      );

      return _parseProfileResponse(response.textContent);
    } on Exception catch (_) {
      return null;
    }
  }

  /// 构建记忆上下文
  ///
  /// 在每次对话开始时调用，提供给 AI 作为上下文
  Future<String> buildMemoryContext() async {
    final profile = await _localDatasource.loadUserProfile();
    final locations = await _localDatasource.loadFrequentLocations();
    final topics = await _localDatasource.loadTopicStats();

    if (profile == null && locations.isEmpty && topics.isEmpty) {
      return ''; // 没有记忆
    }

    final buffer = StringBuffer();
    buffer.writeln('## 用户记忆（基于历史对话）');
    buffer.writeln();

    if (profile != null) {
      if (profile.fitnessLevel != null) {
        buffer.writeln('- **体能水平**: ${profile.fitnessLevel}');
      }
      if (profile.preferredDifficulty != null) {
        buffer.writeln('- **偏好难度**: ${profile.preferredDifficulty}');
      }
      if (profile.preferredDistance != null) {
        buffer.writeln('- **偏好距离**: ${profile.preferredDistance}');
      }
      if (profile.preferredDuration != null) {
        buffer.writeln('- **偏好时长**: ${profile.preferredDuration}');
      }
      if (profile.favoriteRoutes.isNotEmpty) {
        buffer.writeln(
          '- **喜欢的路线**: ${profile.favoriteRoutes.take(5).join(', ')}',
        );
      }
      if (profile.commonConcerns != null) {
        buffer.writeln('- **常见关注点**: ${profile.commonConcerns}');
      }
      buffer.writeln();
    }

    if (locations.isNotEmpty) {
      final topLocations = locations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buffer.writeln(
        '- **常去地点**: ${topLocations.take(5).map((e) => e.key).join(', ')}',
      );
      buffer.writeln();
    }

    if (topics.isNotEmpty) {
      final topTopics = topics.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buffer.writeln(
        '- **常问话题**: ${topTopics.take(5).map((e) => e.key).join(', ')}',
      );
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 从消息中提取地点并记录
  Future<void> extractAndRecordLocations(List<Message> messages) async {
    final locationPatterns = [
      RegExp(r'(香山|百望山|凤凰岭|妙峰山|雾灵山|泰山|华山|黄山|峨眉山|长城|白虎涧)'),
      RegExp(r'(北京|上海|成都|西安|杭州|广州|深圳)'),
    ];

    for (final message in messages) {
      if (message.role != MessageRole.user) continue;
      for (final pattern in locationPatterns) {
        final matches = pattern.allMatches(message.content);
        for (final match in matches) {
          final location = match.group(0);
          if (location != null && location.isNotEmpty) {
            await _localDatasource.recordLocation(location);
          }
        }
      }
    }
  }

  /// 从消息中提取话题并记录
  Future<void> extractAndRecordTopics(
    List<Message> messages,
    IntentCategory intent,
  ) async {
    final topic = _getIntentDisplayName(intent);
    if (topic.isNotEmpty && topic != '未知') {
      await _localDatasource.recordTopic(topic);
    }
  }

  String _getIntentDisplayName(IntentCategory category) {
    return switch (category) {
      IntentCategory.routeSearch => '路线搜索',
      IntentCategory.routeDetail => '路线详情',
      IntentCategory.routeRecommendation => '路线推荐',
      IntentCategory.routeComparison => '路线对比',
      IntentCategory.navigation => '导航',
      IntentCategory.tracking => '轨迹记录',
      IntentCategory.weatherQuery => '天气查询',
      IntentCategory.weatherAlert => '天气预警',
      IntentCategory.fitnessQuery => '体能估算',
      IntentCategory.restAdvice => '休息建议',
      IntentCategory.emergency => '紧急求助',
      IntentCategory.safetyCheck => '安全确认',
      IntentCategory.greeting => '问候',
      IntentCategory.farewell => '告别',
      IntentCategory.feedback => '反馈',
      IntentCategory.settings => '设置',
      IntentCategory.help => '帮助',
      IntentCategory.plantIdentification => '植物识别',
      IntentCategory.trainingPlan => '训练计划',
      IntentCategory.unknown => '未知',
    };
  }

  /// 更新用户画像
  Future<void> updateUserProfile(UserMemoryProfile profile) async {
    await _localDatasource.saveUserProfile(profile);
  }

  /// 清除所有记忆
  Future<void> clearAll() async {
    await _localDatasource.clearAll();
  }

  UserMemoryProfile? _parseProfileResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(response);
      if (jsonMatch == null) return null;

      final jsonStr = jsonMatch.group(0)!;
      final difficulty = _extractJsonValue(jsonStr, 'preferredDifficulty');
      final distance = _extractJsonValue(jsonStr, 'preferredDistance');
      final duration = _extractJsonValue(jsonStr, 'preferredDuration');
      final fitness = _extractJsonValue(jsonStr, 'fitnessLevel');
      final concerns = _extractJsonValue(jsonStr, 'commonConcerns');
      final favoritesJson = _extractJsonList(jsonStr, 'favoriteRoutes');

      return UserMemoryProfile(
        preferredDifficulty: difficulty,
        preferredDistance: distance,
        preferredDuration: duration,
        fitnessLevel: fitness,
        commonConcerns: concerns,
        favoriteRoutes: favoritesJson,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  String? _extractJsonValue(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  List<String> _extractJsonList(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*\\[(.*?)\\]');
    final match = pattern.firstMatch(json);
    if (match == null) return [];

    final listStr = match.group(1)!;
    return listStr
        .split(',')
        .map((s) => s.trim())
        .map((s) {
          if (s.startsWith('"') || s.startsWith("'")) {
            s = s.substring(1);
          }
          if (s.endsWith('"') || s.endsWith("'")) {
            s = s.substring(0, s.length - 1);
          }
          return s;
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
