import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';
import 'package:hiking_assistant/features/chat/domain/entities/conversation.dart';
import 'package:hiking_assistant/features/chat/domain/entities/intent.dart';
import 'package:hiking_assistant/features/chat/domain/services/intent_service.dart';
import 'package:hiking_assistant/features/chat/domain/tools/chat_tool.dart';
import 'package:hiking_assistant/features/chat/domain/tools/tool_registry.dart';
import 'package:hiking_assistant/features/chat/domain/tools/weather_tool.dart';
import 'package:hiking_assistant/features/chat/domain/tools/route_search_tool.dart';
import 'package:hiking_assistant/features/chat/domain/tools/location_tool.dart';
import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/features/chat/data/services/emotion_analysis_service.dart';
import 'package:hiking_assistant/features/chat/data/datasources/conversation_local_datasource.dart';
import 'package:hiking_assistant/features/chat/data/services/conversation_memory_service.dart';
import 'package:hiking_assistant/features/chat/domain/entities/emotion_analysis.dart';
import 'package:hiking_assistant/features/safety/data/services/safety_analysis_service.dart';
import 'package:hiking_assistant/features/safety/domain/entities/safety_alert.dart';
import 'package:hiking_assistant/features/safety/presentation/providers/safety_monitor_provider.dart';
import 'package:hiking_assistant/shared/services/location_service.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/route_provider.dart';
import 'package:hiking_assistant/features/weather/data/services/weather_api_service.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';
import 'package:hiking_assistant/features/community/data/services/community_qa_service.dart';
import 'package:hiking_assistant/features/community/domain/entities/community_qa.dart';
import 'package:hiking_assistant/features/training/data/services/training_plan_service.dart';
import 'package:hiking_assistant/features/training/domain/entities/training_plan.dart';

// 意图服务 Provider
final intentServiceProvider = Provider<IntentService>((ref) {
  return IntentService();
});

// Claude API 服务 Provider
final claudeAPIServiceProvider = Provider<ClaudeAPIService>((ref) {
  return ClaudeAPIService.instance;
});

// 位置服务 Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

// 天气服务 Provider
final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService.instance;
});

// 情绪分析服务 Provider
final emotionAnalysisServiceProvider = Provider<EmotionAnalysisService>((ref) {
  return EmotionAnalysisService(claudeAPI: ref.watch(claudeAPIServiceProvider));
});

// 社区问答服务 Provider
final communityQaServiceProvider = Provider<CommunityQaService>((ref) {
  return CommunityQaService(claudeAPI: ref.watch(claudeAPIServiceProvider));
});

// 训练计划服务 Provider
final trainingPlanServiceProvider = Provider<TrainingPlanService>((ref) {
  return TrainingPlanService(claudeAPI: ref.watch(claudeAPIServiceProvider));
});

// 对话本地数据源 Provider
final conversationLocalDatasourceProvider =
    Provider<ConversationLocalDatasource>((ref) {
  return ConversationLocalDatasource();
});

// 对话记忆服务 Provider
final conversationMemoryServiceProvider =
    Provider<ConversationMemoryService>((ref) {
  return ConversationMemoryService(
    localDatasource: ref.watch(conversationLocalDatasourceProvider),
    claudeAPI: ref.watch(claudeAPIServiceProvider),
  );
});

// 系统提示词
const String _systemPrompt = '''你是一个专业、友好的爬山助手 AI，名为"山语"。

## 你的核心能力
1. 路线推荐：根据用户的位置、体能、天气推荐合适的爬山路线
2. 天气查询：提供实时天气和预报
3. 轨迹记录：记录爬山轨迹
4. 安全提醒：及时提醒危险

## 对话风格
- 使用友好的口语化表达
- 适当使用 emoji 增加亲和力
- 对于爬山相关术语，提供简单解释
- 鼓励用户，但不夸大事实
- 安全问题必须严肃对待

## 安全优先原则
当用户表达受伤、迷路等，直接响应：
【安全确认】+【当前位置】+【建议行动】

## 回复格式
- 使用 Markdown 格式
- 路线信息使用结构化格式
- 关键信息加粗或使用列表

## 限制
1. 不知道的信息要如实说明，不要编造
2. 不确定的安全信息要建议用户咨询专业人士
3. 尊重用户的隐私''';

// 对话状态
class ChatState {
  final String conversationId;
  final List<Message> messages;
  final ConversationContext context;
  final bool isLoading;
  final ToolCallInfo? pendingToolCall;
  final LocationResult? currentLocation;
  final EmotionAnalysisResult? lastEmotion;

  ChatState({
    required this.conversationId,
    required this.messages,
    required this.context,
    this.isLoading = false,
    this.pendingToolCall,
    this.currentLocation,
    this.lastEmotion,
  });

  factory ChatState.initial() {
    final uuid = _generateUuid();
    return ChatState(
      conversationId: uuid,
      messages: const [],
      context: ConversationContext.initial('anonymous', uuid),
    );
  }

  ChatState copyWith({
    String? conversationId,
    List<Message>? messages,
    ConversationContext? context,
    bool? isLoading,
    ToolCallInfo? pendingToolCall,
    LocationResult? currentLocation,
    EmotionAnalysisResult? lastEmotion,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      isLoading: isLoading ?? this.isLoading,
      pendingToolCall: pendingToolCall ?? this.pendingToolCall,
      currentLocation: currentLocation ?? this.currentLocation,
      lastEmotion: lastEmotion ?? this.lastEmotion,
    );
  }
}

// 简单的 UUID 生成器
String _generateUuid() {
  final now = DateTime.now();
  return '${now.millisecondsSinceEpoch}${1000 + (now.microsecond % 9000)}';
}

// ChatNotifier
class ChatNotifier extends StateNotifier<ChatState> {
  final IntentService _intentService;
  final ClaudeAPIService _claudeAPI;
  final LocationService _locationService;
  final RouteRecommendationUseCase _routeRecommendationUseCase;
  final WeatherApiService _weatherApiService;
  final SafetyAnalysisService _safetyService;
  final ConversationMemoryService _memoryService;
  final EmotionAnalysisService _emotionService;
  final CommunityQaService _communityQaService;
  final TrainingPlanService _trainingPlanService;
  final void Function(SafetyAlert)? _onSafetyAlert;
  final ToolRegistry _toolRegistry;

  // 对话历史（用于 Claude API）
  List<ClaudeMessage> _conversationHistory = [];
  String _memoryContext = '';

  ChatNotifier({
    required IntentService intentService,
    required ClaudeAPIService claudeAPI,
    required LocationService locationService,
    required RouteRecommendationUseCase routeRecommendationUseCase,
    required WeatherApiService weatherApiService,
    required SafetyAnalysisService safetyService,
    required ConversationMemoryService memoryService,
    required EmotionAnalysisService emotionService,
    required CommunityQaService communityQaService,
    required TrainingPlanService trainingPlanService,
    void Function(SafetyAlert)? onSafetyAlert,
  })  : _intentService = intentService,
        _claudeAPI = claudeAPI,
        _locationService = locationService,
        _routeRecommendationUseCase = routeRecommendationUseCase,
        _weatherApiService = weatherApiService,
        _safetyService = safetyService,
        _memoryService = memoryService,
        _emotionService = emotionService,
        _communityQaService = communityQaService,
        _trainingPlanService = trainingPlanService,
        _onSafetyAlert = onSafetyAlert,
        _toolRegistry = ToolRegistry([
          WeatherTool(weatherApiService),
          RouteSearchTool(routeRecommendationUseCase),
          LocationTool(locationService),
        ]),
        super(ChatState.initial()) {
    // 初始化获取位置和加载记忆
    _initLocation();
    _loadMemory();
  }

  /// 加载历史记忆
  Future<void> _loadMemory() async {
    try {
      _memoryContext = await _memoryService.buildMemoryContext();
    } on Exception catch (_) {
      // 记忆加载失败不影响主流程
    }
  }

  Future<void> _initLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      state = state.copyWith(currentLocation: location);
    }
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 1. 创建用户消息
    final userMessage = Message(
      id: _generateUuid(),
      conversationId: state.conversationId,
      role: MessageRole.user,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    // 2. 更新状态（添加用户消息）
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // 3. 意图识别
    final intent = _intentService.detectIntent(content);

    // 3.5 情绪与紧迫度分析
    final emotionResult = await _emotionService.analyze(content);
    if (mounted) {
      state = state.copyWith(lastEmotion: emotionResult);
    }

    // 4. 如果是快速响应（本地可处理），直接返回
    final quickResponse = intent.quickResponse;
    if (intent.isQuickResponse && quickResponse != null) {
      final assistantMessage = Message(
        id: _generateUuid(),
        conversationId: state.conversationId,
        role: MessageRole.assistant,
        content: quickResponse,
        messageType: MessageType.text,
        intent: intent.category.name,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
      return;
    }

    // 4.5 植物识别意图 - 返回操作卡片引导用户进入识别页面
    if (intent.category == IntentCategory.plantIdentification) {
      final assistantMessage = Message(
        id: _generateUuid(),
        conversationId: state.conversationId,
        role: MessageRole.assistant,
        content: '我可以帮您识别山区的植物！🌿\n\n拍照后我会分析植物特征，并提供：\n• 植物名称和科属\n• 毒性等级评估\n• 可食用性判断\n• 户外安全建议',
        messageType: MessageType.actionCard,
        intent: intent.category.name,
        createdAt: DateTime.now(),
        actionCards: const [
          ActionCard(
            id: 'open_plant_camera',
            label: '打开植物识别',
            action: '/plant-identification',
            type: ActionCardType.button,
          ),
        ],
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
      return;
    }

    // 5. 训练计划生成（如果涉及训练/体能准备）
    if (intent.category == IntentCategory.trainingPlan ||
        _isTrainingRelatedContent(content)) {
      final plan = await _generateTrainingPlan(content);
      if (plan != null) {
        final planMessage = Message(
          id: _generateUuid(),
          conversationId: state.conversationId,
          role: MessageRole.assistant,
          content: _formatTrainingPlan(plan),
          messageType: MessageType.text,
          intent: intent.category.name,
          createdAt: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, planMessage],
          isLoading: false,
        );
        return;
      }
    }

    // 6. 处理位置信息
    LocationResult? location = state.currentLocation;
    String? requestedLocation;

    // 如果用户指定了地名，进行地理编码
    if (intent.entities.containsKey('location')) {
      final locationEntity = intent.entities['location'];
      if (locationEntity is String) {
        requestedLocation = locationEntity;
        location = await _locationService.searchLocation(requestedLocation);
      }
    }

    // 6. 获取路线推荐（如果涉及路线查询）
    List<RouteRecommendation>? routeRecommendations;
    if (intent.category == IntentCategory.routeRecommendation ||
        intent.category == IntentCategory.routeSearch ||
        _isRouteRelatedContent(content)) {
      routeRecommendations = await _getRouteRecommendations(
        content,
        location,
        intent,
      );
    }

    // 7. 获取天气信息（如果涉及天气查询或路线推荐）
    WeatherData? weatherData;
    if (intent.category == IntentCategory.weatherQuery ||
        intent.category == IntentCategory.weatherAlert ||
        routeRecommendations != null) {
      try {
        weatherData = await _weatherApiService.getWeather(
          location?.latitude ?? 39.9042,
          location?.longitude ?? 116.4074,
        );
      } on Exception catch (_) {
        weatherData = null;
      }
    }

    // 8. 搜索社区问答（帮助类、通用类问题）
    String? communityContext;
    if (intent.category == IntentCategory.help ||
        intent.category == IntentCategory.unknown ||
        _isCommunityRelatedContent(content)) {
      final qaResults = _communityQaService.search(content, limit: 2);
      if (qaResults.isNotEmpty) {
        communityContext = _buildCommunityContext(qaResults);
      }
    }

    // 9. 构建上下文（包含情绪信息和社区问答）
    final contextPrompt = _buildContextPrompt(
      location,
      requestedLocation,
      routeRecommendations,
      weatherData,
      emotion: emotionResult,
      communityContext: communityContext,
    );

    // 10. 并行执行：调用 Claude API + 安全分析 + 情绪紧急时加强安全分析
    final weatherDesc = weatherData?.description ?? '';
    final locationDesc = location?.address ?? '';

    await Future.wait([
      _callClaudeAPI(content, contextPrompt, requestedLocation, emotion: emotionResult),
      _analyzeSafety(content, weatherDesc, locationDesc, emotion: emotionResult),
    ]);
  }

  /// 安全分析
  Future<void> _analyzeSafety(
    String content,
    String weatherDesc,
    String locationDesc, {
    EmotionAnalysisResult? emotion,
  }) async {
    try {
      final result = await _safetyService.analyzeMessageSafety(
        content,
        weatherContext: weatherDesc.isNotEmpty ? weatherDesc : null,
        locationContext: locationDesc.isNotEmpty ? locationDesc : null,
      );

      // 如果有警报，通知外部并添加到对话
      if (result.suggestedAlerts.isNotEmpty) {
        for (final alert in result.suggestedAlerts) {
          _onSafetyAlert?.call(alert);
        }

        // 对于 warning 及以上等级，在对话中添加安全提醒
        if (result.level.index >= SafetyLevel.warning.index) {
          final safetyMessage = Message(
            id: _generateUuid(),
            conversationId: state.conversationId,
            role: MessageRole.assistant,
            content: '''⚠️ **安全提醒**

${result.reason}

**建议：**
${result.advice}

如有紧急情况，请立即拨打 120 或当地救援电话。''',
            messageType: MessageType.text,
            intent: 'safetyAlert',
            createdAt: DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, safetyMessage],
          );
        }
      }
    } on Exception catch (_) {
      // 安全分析失败不影响主流程
    }
  }

  /// 判断内容是否与训练计划相关
  bool _isTrainingRelatedContent(String content) {
    final keywords = [
      '训练计划',
      '锻炼计划',
      '体能训练',
      '爬山训练',
      '准备爬山',
      '怎么准备',
      '如何训练',
      '提升体能',
      '增强体力',
      '备战',
      '训练几周',
      '训练周期',
    ];
    final lowerContent = content.toLowerCase();
    return keywords.any((keyword) => lowerContent.contains(keyword));
  }

  /// 生成训练计划
  Future<TrainingPlan?> _generateTrainingPlan(String content) async {
    try {
      // 解析周数
      var weeks = 4;
      final weekMatch = RegExp(r'(\d+)\s*周').firstMatch(content);
      if (weekMatch != null) {
        weeks = int.parse(weekMatch.group(1)!);
        if (weeks < 1) weeks = 1;
        if (weeks > 12) weeks = 12;
      }

      // 解析体能水平
      String? fitnessLevel;
      final lowerContent = content.toLowerCase();
      if (lowerContent.contains('新手') ||
          lowerContent.contains('初级') ||
          lowerContent.contains('刚开始')) {
        fitnessLevel = '新手';
      } else if (lowerContent.contains('中级') ||
          lowerContent.contains('经常') ||
          lowerContent.contains('有一定基础')) {
        fitnessLevel = '中级';
      } else if (lowerContent.contains('高级') ||
          lowerContent.contains('专业') ||
          lowerContent.contains('经验丰富')) {
        fitnessLevel = '高级';
      }

      // 解析目标
      String? goal;
      if (lowerContent.contains('香山')) {
        goal = '准备爬香山';
      } else if (lowerContent.contains('泰山')) {
        goal = '挑战泰山';
      } else if (lowerContent.contains('华山')) {
        goal = '挑战华山';
      } else if (lowerContent.contains('黄山')) {
        goal = '挑战黄山';
      } else if (lowerContent.contains(' endurance') ||
          lowerContent.contains('耐力')) {
        goal = '提升耐力';
      } else if (lowerContent.contains('力量')) {
        goal = '增强力量';
      }

      // 尝试从用户画像获取体能水平
      if (fitnessLevel == null) {
        final profile = await _memoryService.loadUserProfile();
        if (profile != null && profile.fitnessLevel != null) {
          fitnessLevel = profile.fitnessLevel;
        }
      }

      return await _trainingPlanService.generatePlan(
        fitnessLevel: fitnessLevel,
        goal: goal,
        weeks: weeks,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 格式化训练计划为文本
  String _formatTrainingPlan(TrainingPlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('## 🏋️ ${plan.name}');
    buffer.writeln();
    buffer.writeln('**等级**: ${plan.levelLabel}  |  **周期**: ${plan.durationWeeks}周');
    if (plan.goalRoute != null) {
      buffer.writeln('**目标**: ${plan.goalRoute}');
    }
    buffer.writeln();
    buffer.writeln(plan.description);
    buffer.writeln();

    // 显示本周和下周概要
    final currentWeek = 1;
    for (int w = currentWeek; w <= plan.durationWeeks && w <= currentWeek + 1; w++) {
      final weekDays = plan.getWeekSchedule(w);
      if (weekDays.isEmpty) continue;

      buffer.writeln('### 第 $w 周');
      for (final day in weekDays) {
        final icon = switch (day.type) {
          TrainingType.cardio => '🏃',
          TrainingType.strength => '💪',
          TrainingType.flexibility => '🧘',
          TrainingType.hiking => '🥾',
          TrainingType.rest => '☕',
        };
        buffer.writeln(
            '$icon **${day.title}** (${day.durationMinutes}分钟)${day.isRestDay ? ' - 休息日' : ''}');
        if (!day.isRestDay) {
          buffer.writeln('   ${day.description}');
        }
      }
      buffer.writeln();
    }

    if (plan.durationWeeks > 2) {
      buffer.writeln('... 还有 ${plan.durationWeeks - 2} 周内容，可在训练页面查看完整计划');
    }

    buffer.writeln();
    buffer.writeln('💡 每天训练前记得热身，训练后做拉伸放松。坚持就是胜利！');

    return buffer.toString();
  }

  /// 判断内容是否与社区问答相关
  bool _isCommunityRelatedContent(String content) {
    final keywords = [
      '装备', '鞋子', '背包', '衣服', '杖',
      '安全', '危险', '受伤', '急救', '雷雨', '迷路',
      '体能', '训练', '热身', '拉伸', '膝盖', '腿',
      '水', '食物', '零食', '补给',
      '新手', '第一次', '准备', '建议',
      '季节', '时间', '多久', '多长',
    ];
    final lowerContent = content.toLowerCase();
    return keywords.any((keyword) => lowerContent.contains(keyword));
  }

  String _buildCommunityContext(List<CommunityQaResult> results) {
    final buffer = StringBuffer();
    for (int i = 0; i < results.length; i++) {
      final qa = results[i].qa;
      buffer.writeln('${i + 1}. ${qa.question}');
      buffer.writeln('   回答: ${qa.answer.substring(0, qa.answer.length > 100 ? 100 : qa.answer.length)}...');
      if (qa.source != null) {
        buffer.writeln('   来源: ${qa.source} (${qa.helpfulCount}人觉得有用)');
      }
    }
    return buffer.toString();
  }

  /// 判断内容是否与路线相关
  bool _isRouteRelatedContent(String content) {
    final routeKeywords = [
      '爬',
      '登山',
      '徒步',
      '路线',
      '香山',
      '百望山',
      '凤凰岭',
      '妙峰山',
      '雾灵山',
      '长城',
      '白虎涧',
      '难度',
      '时间',
      '距离',
      '新手',
      '推荐',
      '路线',
    ];
    final lowerContent = content.toLowerCase();
    return routeKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  /// 获取路线推荐（含个性化画像）
  Future<List<RouteRecommendation>> _getRouteRecommendations(
    String content,
    LocationResult? location,
    Intent intent,
  ) async {
    try {
      // 解析用户显式偏好
      var preferences = _parseRoutePreferences(content, location, intent);

      // 加载用户画像并合并到偏好
      final profile = await _memoryService.loadUserProfile();
      if (profile != null) {
        preferences = RoutePreferences(
          preferredDifficulty: preferences.preferredDifficulty,
          maxDuration: preferences.maxDuration,
          maxDistance: preferences.maxDistance,
          requiredTags: preferences.requiredTags,
          userLatitude: preferences.userLatitude,
          userLongitude: preferences.userLongitude,
          userProfile: profile,
        );
      }

      return await _routeRecommendationUseCase.getRecommendations(
        preferences: preferences,
        limit: 3,
      );
    } on Exception catch (_) {
      return [];
    }
  }

  /// 解析路线偏好
  RoutePreferences _parseRoutePreferences(
    String content,
    LocationResult? location,
    Intent intent,
  ) {
    final lowerContent = content.toLowerCase();

    // 解析难度偏好
    String? preferredDifficulty;
    if (lowerContent.contains('新手') ||
        lowerContent.contains('简单') ||
        lowerContent.contains('容易')) {
      preferredDifficulty = '新手/简单';
    } else if (lowerContent.contains('中级') || lowerContent.contains('一般')) {
      preferredDifficulty = '中级/一般';
    } else if (lowerContent.contains('难') || lowerContent.contains('挑战')) {
      preferredDifficulty = '难/挑战';
    }

    // 解析时间偏好（小时转分钟）
    int? maxDuration;
    final hourMatch = RegExp(r'(\d+)\s*小时').firstMatch(content);
    if (hourMatch != null) {
      maxDuration = int.parse(hourMatch.group(1)!) * 60;
    }
    final minuteMatch = RegExp(r'(\d+)\s*分钟').firstMatch(content);
    if (minuteMatch != null) {
      maxDuration = int.parse(minuteMatch.group(1)!);
    }

    // 解析距离偏好
    double? maxDistance;
    final distanceMatch = RegExp(r'(\d+(?:\.\d+)?)\s*公里').firstMatch(content);
    if (distanceMatch != null) {
      maxDistance = double.parse(distanceMatch.group(1)!);
    }

    return RoutePreferences(
      preferredDifficulty: preferredDifficulty,
      maxDuration: maxDuration,
      maxDistance: maxDistance,
      userLatitude: location?.latitude,
      userLongitude: location?.longitude,
    );
  }

  /// 构建上下文提示
  String _buildContextPrompt(
    LocationResult? location,
    String? requestedLocation,
    List<RouteRecommendation>? routeRecommendations,
    WeatherData? weatherData, {
    EmotionAnalysisResult? emotion,
    String? communityContext,
  }) {
    final buffer = StringBuffer();

    if (location != null) {
      buffer.writeln('## 用户位置信息');
      if (requestedLocation != null) {
        buffer.writeln('用户查询位置: $requestedLocation');
        buffer.writeln('查询位置坐标: ${location.latitude}, ${location.longitude}');
      } else {
        buffer.writeln('当前位置: ${location.address}');
        buffer.writeln('坐标: ${location.latitude}, ${location.longitude}');
      }
      buffer.writeln();
    }

    // 添加情绪与紧迫度信息
    if (emotion != null && emotion.shouldIncludeInContext) {
      buffer.writeln('## 用户当前状态');
      buffer.writeln('- 情绪: ${emotion.emotionLabel}');
      buffer.writeln('- 紧迫度: ${emotion.urgencyLabel}');
      buffer.writeln('- 建议回复风格: ${emotion.toneLabel}');
      buffer.writeln();
    }

    // 添加天气信息
    if (weatherData != null) {
      buffer.writeln('## 当前天气信息');
      buffer.writeln('天气: ${weatherData.description}');
      buffer.writeln('- 当前温度: ${weatherData.temperature.toStringAsFixed(0)}°C');
      final maxTemp = weatherData.maxTemp;
      final minTemp = weatherData.minTemp;
      if (maxTemp != null && minTemp != null) {
        buffer.writeln(
            '- 最高/最低: ${maxTemp.toStringAsFixed(0)}°C / ${minTemp.toStringAsFixed(0)}°C');
      }
      buffer.writeln('- 风速: ${weatherData.windSpeed.toStringAsFixed(0)} km/h');
      buffer.writeln('- 爬山建议: ${weatherData.hikingAdvice}');
      buffer.writeln();
    }

    // 添加社区问答知识
    if (communityContext != null && communityContext.isNotEmpty) {
      buffer.writeln('## 社区知识参考');
      buffer.writeln(communityContext);
      buffer.writeln();
    }

    // 添加路线推荐
    if (routeRecommendations != null && routeRecommendations.isNotEmpty) {
      buffer.writeln('## 推荐路线（基于用户偏好）');
      for (int i = 0; i < routeRecommendations.length; i++) {
        final rec = routeRecommendations[i];
        final route = rec.route;
        buffer.writeln();
        buffer.writeln('### ${i + 1}. ${route.name}');
        buffer.writeln('- **位置**: ${route.location}');
        buffer.writeln('- **难度**: ${route.difficultyLabel}');
        buffer.writeln('- **距离**: ${route.distance} km');
        buffer.writeln('- **预计时长**: ${route.estimatedDuration} 分钟');
        buffer.writeln('- **爬升**: ${route.elevationGain} m');
        buffer.writeln('- **评分**: ${route.rating} (${route.reviewCount}条评价)');
        if (route.warnings.isNotEmpty) {
          buffer.writeln('- **注意**: ${route.warnings.join(", ")}');
        }
        buffer.writeln('- **推荐理由**: ${rec.matchReasons.join("; ")}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 调用 Claude API（支持工具调用循环）
  Future<void> _callClaudeAPI(
    String userContent,
    String contextPrompt,
    String? requestedLocation, {
    EmotionAnalysisResult? emotion,
  }) async {
    try {
      // 添加用户消息到历史
      _conversationHistory = [
        ..._conversationHistory,
        ClaudeMessage(role: 'user', content: userContent),
      ];

      // 构建带有上下文的系统消息（包含记忆上下文）
      var fullSystemPrompt = _systemPrompt;
      if (_memoryContext.isNotEmpty) {
        fullSystemPrompt = '$fullSystemPrompt\n\n$_memoryContext';
      }
      if (contextPrompt.isNotEmpty) {
        fullSystemPrompt = '$fullSystemPrompt\n\n$contextPrompt';
      }

      // 根据情绪状态调整系统提示的回复风格
      if (emotion != null && emotion.shouldIncludeInContext) {
        final toneGuidance = _buildToneGuidance(emotion);
        fullSystemPrompt = '$fullSystemPrompt\n\n## 当前回复风格要求\n$toneGuidance';
      }

      // 工具调用循环（最多 3 轮，防止无限循环）
      var turnCount = 0;
      const maxToolTurns = 3;
      String finalText = '';

      while (turnCount < maxToolTurns) {
        turnCount++;

        // 调用 Claude API（传入工具定义）
        final response = await _claudeAPI.sendMessage(
          systemPrompt: fullSystemPrompt,
          conversationHistory: _conversationHistory,
          userMessage: userContent,
          tools: _toolRegistry.allTools,
        );

        // 检查是否有工具调用
        if (!response.hasToolUse) {
          // 没有工具调用，直接返回文本结果
          finalText = response.textContent;

          // 添加助手消息到历史
          _conversationHistory = [
            ..._conversationHistory,
            ClaudeMessage(role: 'assistant', content: finalText),
          ];
          break;
        }

        // 处理工具调用
        final toolBlocks = response.toolUseBlocks;
        String assistantTurnContent = '';
        final toolResults = <Map<String, dynamic>>[];

        for (final block in toolBlocks) {
          if (block.toolName == null || block.toolUseId == null) continue;

          // 执行工具
          final request = ToolCallRequest(
            id: block.toolUseId!,
            name: block.toolName!,
            arguments: block.toolInput ?? {},
          );
          final result = await _toolRegistry.execute(request);

          // 构建助手消息内容（包含 tool_use）
          assistantTurnContent +=
              '[tool_use: ${block.toolName}] ${block.text}\n';

          // 构建工具结果
          toolResults.add({
            'type': 'tool_result',
            'tool_use_id': block.toolUseId,
            'content': result.result,
          });
        }

        // 添加助手消息（包含 tool_use）到历史
        _conversationHistory = [
          ..._conversationHistory,
          ClaudeMessage(role: 'assistant', content: assistantTurnContent),
        ];

        // 添加工具结果到历史（作为 user 消息，Anthropic 格式要求）
        if (toolResults.isNotEmpty) {
          _conversationHistory = [
            ..._conversationHistory,
            ClaudeMessage(
              role: 'user',
              content: jsonEncode(toolResults),
            ),
          ];
        }
      }

      // 创建助手消息
      final assistantMessage = Message(
        id: _generateUuid(),
        conversationId: state.conversationId,
        role: MessageRole.assistant,
        content: finalText.isNotEmpty
            ? finalText
            : '已为您查询相关信息，请查看结果。',
        messageType: MessageType.text,
        createdAt: DateTime.now(),
      );

      // 更新状态
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );

      // 限制历史长度
      if (_conversationHistory.length > 24) {
        _conversationHistory = _conversationHistory.sublist(
          _conversationHistory.length - 24,
        );
      }

      // 持久化对话历史
      unawaited(_persistConversation());
    } on Exception catch (_) {
      // 错误处理
      final errorMessage = Message(
        id: _generateUuid(),
        conversationId: state.conversationId,
        role: MessageRole.assistant,
        content: '抱歉，服务暂时不可用，请稍后再试。',
        messageType: MessageType.text,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  /// 根据情绪构建回复风格指引
  String _buildToneGuidance(EmotionAnalysisResult emotion) {
    return switch (emotion.suggestedTone) {
      ResponseTone.empathetic =>
        '用户当前情绪为「${emotion.emotionLabel}」，请表达理解和共情，先安抚情绪再提供建议。避免说教，多用"我理解"、"没关系"等表达。',
      ResponseTone.urgent =>
        '情况紧急，请直接给出最关键的行动建议，先保证用户安全。语气果断但冷静，避免冗长解释。',
      ResponseTone.calm =>
        '用户可能感到焦虑或害怕，请用冷静、安抚的语气回复。强调"问题不大"、"可以处理"，提供清晰步骤。',
      ResponseTone.encouraging =>
        '用户可能感到疲惫或挫败，请给予积极鼓励。肯定用户的努力，提供 achievable 的小目标建议。',
      ResponseTone.concise =>
        '请尽量简洁回复，直接给出核心信息。',
      ResponseTone.normal =>
        '保持友好、专业的正常对话风格。',
    };
  }

  /// 持久化对话数据
  Future<void> _persistConversation() async {
    try {
      final messages = state.messages;
      if (messages.isEmpty) return;

      // 保存消息历史
      await _memoryService.saveMessages(messages);

      // 提取地点和话题（异步，不阻塞）
      unawaited(_memoryService.extractAndRecordLocations(messages));
      final lastIntent = messages.lastWhere(
        (m) => m.intent != null,
        orElse: () => messages.last,
      );
      if (lastIntent.intent != null) {
        final intent = IntentCategory.values.cast<IntentCategory?>().firstWhere(
          (c) => c?.name == lastIntent.intent,
          orElse: () => null,
        );
        if (intent != null) {
          unawaited(_memoryService.extractAndRecordTopics(messages, intent));
        }
      }

      // 每 10 条消息生成一次用户画像
      if (messages.length >= 10 && messages.length % 10 == 0) {
        unawaited(_updateUserProfile());
      }
    } on Exception catch (_) {
      // 持久化失败不影响主流程
    }
  }

  /// 更新用户画像
  Future<void> _updateUserProfile() async {
    try {
      final profile = await _memoryService.generateUserProfile(state.messages);
      if (profile != null) {
        await _memoryService.updateUserProfile(profile);
        // 更新记忆上下文
        _memoryContext = await _memoryService.buildMemoryContext();
      }
    } on Exception catch (_) {
      // 画像生成失败不影响主流程
    }
  }

  /// 清除对话
  void clearConversation() {
    _conversationHistory = [];
    state = ChatState.initial();
    // 重新获取位置
    _initLocation();
  }

  /// 刷新位置
  Future<void> refreshLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      state = state.copyWith(currentLocation: location);
    }
  }
}

// Provider
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    intentService: ref.watch(intentServiceProvider),
    claudeAPI: ref.watch(claudeAPIServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    routeRecommendationUseCase: ref.watch(routeRecommendationUseCaseProvider),
    weatherApiService: ref.watch(weatherApiServiceProvider),
    safetyService: ref.watch(safetyAnalysisServiceProvider),
    memoryService: ref.watch(conversationMemoryServiceProvider),
    emotionService: ref.watch(emotionAnalysisServiceProvider),
    communityQaService: ref.watch(communityQaServiceProvider),
    trainingPlanService: ref.watch(trainingPlanServiceProvider),
    onSafetyAlert: (alert) {
      ref.read(safetyMonitorProvider.notifier).addAlert(alert);
    },
  );
});

