import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';
import 'package:hiking_assistant/features/chat/domain/entities/conversation.dart';
import 'package:hiking_assistant/features/chat/domain/entities/intent.dart';
import 'package:hiking_assistant/features/chat/domain/services/intent_service.dart';
import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/shared/services/location_service.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/weather/data/services/weather_api_service.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

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

  ChatState({
    required this.conversationId,
    required this.messages,
    required this.context,
    this.isLoading = false,
    this.pendingToolCall,
    this.currentLocation,
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
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      isLoading: isLoading ?? this.isLoading,
      pendingToolCall: pendingToolCall ?? this.pendingToolCall,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

// 简单的 UUID 生成器
String _generateUuid() {
  return DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (DateTime.now().microsecond % 9000)).toString();
}

// ChatNotifier
class ChatNotifier extends StateNotifier<ChatState> {
  final IntentService _intentService;
  final ClaudeAPIService _claudeAPI;
  final LocationService _locationService;
  final RouteRecommendationUseCase _routeRecommendationUseCase;
  final WeatherApiService _weatherApiService;

  // 对话历史（用于 Claude API）
  List<ClaudeMessage> _conversationHistory = [];

  ChatNotifier({
    required IntentService intentService,
    required ClaudeAPIService claudeAPI,
    required LocationService locationService,
    required RouteRecommendationUseCase routeRecommendationUseCase,
    required WeatherApiService weatherApiService,
  })  : _intentService = intentService,
        _claudeAPI = claudeAPI,
        _locationService = locationService,
        _routeRecommendationUseCase = routeRecommendationUseCase,
        _weatherApiService = weatherApiService,
        super(ChatState.initial()) {
    // 初始化获取位置
    _initLocation();
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

    // 4. 如果是快速响应（本地可处理），直接返回
    if (intent.isQuickResponse && intent.quickResponse != null) {
      final assistantMessage = Message(
        id: _generateUuid(),
        conversationId: state.conversationId,
        role: MessageRole.assistant,
        content: intent.quickResponse!,
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

    // 5. 处理位置信息
    LocationResult? location = state.currentLocation;
    String? requestedLocation;

    // 如果用户指定了地名，进行地理编码
    if (intent.entities.containsKey('location')) {
      requestedLocation = intent.entities['location'] as String;
      location = await _locationService.searchLocation(requestedLocation);
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

    // 8. 构建上下文
    final contextPrompt = _buildContextPrompt(
      location,
      requestedLocation,
      routeRecommendations,
      weatherData,
    );

    // 9. 调用 Claude API
    await _callClaudeAPI(content, contextPrompt, requestedLocation);
  }

  /// 判断内容是否与路线相关
  bool _isRouteRelatedContent(String content) {
    final routeKeywords = [
      '爬', '登山', '徒步', '路线', '香山', '百望山', '凤凰岭',
      '妙峰山', '雾灵山', '长城', '白虎涧', '难度', '时间',
      '距离', '新手', '推荐', '路线',
    ];
    final lowerContent = content.toLowerCase();
    return routeKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  /// 获取路线推荐
  Future<List<RouteRecommendation>> _getRouteRecommendations(
    String content,
    LocationResult? location,
    Intent intent,
  ) async {
    try {
      // 解析用户偏好
      final preferences = _parseRoutePreferences(content, location, intent);
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
    if (lowerContent.contains('新手') || lowerContent.contains('简单') || lowerContent.contains('容易')) {
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
    WeatherData? weatherData,
  ) {
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

    // 添加天气信息
    if (weatherData != null) {
      buffer.writeln('## 当前天气信息');
      buffer.writeln('${weatherData.iconEmoji} ${weatherData.description}');
      buffer.writeln('- 当前温度: ${weatherData.temperature.toStringAsFixed(0)}°C');
      final maxTemp = weatherData.maxTemp;
      final minTemp = weatherData.minTemp;
      if (maxTemp != null && minTemp != null) {
        buffer.writeln('- 最高/最低: ${maxTemp.toStringAsFixed(0)}°C / ${minTemp.toStringAsFixed(0)}°C');
      }
      buffer.writeln('- 风速: ${weatherData.windSpeed.toStringAsFixed(0)} km/h');
      buffer.writeln('- 爬山建议: ${weatherData.hikingAdvice}');
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

  /// 调用 Claude API
  Future<void> _callClaudeAPI(
    String userContent,
    String contextPrompt,
    String? requestedLocation,
  ) async {
    try {
      // 添加用户消息到历史
      _conversationHistory = [
        ..._conversationHistory,
        ClaudeMessage(role: 'user', content: userContent),
      ];

      // 构建带有上下文的系统消息
      final fullSystemPrompt = contextPrompt.isNotEmpty
          ? '$_systemPrompt\n\n$contextPrompt'
          : _systemPrompt;

      // 调用 Claude API
      final response = await _claudeAPI.sendMessage(
        systemPrompt: fullSystemPrompt,
        conversationHistory: _conversationHistory,
        userMessage: userContent,
      );

      // 添加助手消息到历史
      _conversationHistory = [
        ..._conversationHistory,
        ClaudeMessage(role: 'assistant', content: response.textContent),
      ];

      // 创建助手消息
      final assistantMessage = Message(
        id: _generateUuid(),
        conversationId: state.conversationId,
        role: MessageRole.assistant,
        content: response.textContent,
        messageType: MessageType.text,
        createdAt: DateTime.now(),
      );

      // 更新状态
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );

      // 限制历史长度
      if (_conversationHistory.length > 20) {
        _conversationHistory = _conversationHistory.sublist(
          _conversationHistory.length - 20,
        );
      }
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
  );
});

// 导入路线推荐 Provider
final routeRecommendationUseCaseProvider = Provider<RouteRecommendationUseCase>((ref) {
  final datasource = RouteLocalDatasource();
  return RouteRecommendationUseCase(datasource);
});
