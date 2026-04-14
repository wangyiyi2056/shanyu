/// 对话状态
enum DialogueState {
  active,
  awaitingToolResult,
  confirming,
  concluded,
}

/// 对话上下文
class ConversationContext {
  final String conversationId;
  final String userId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final DialogueState state;
  final Map<String, dynamic> globalContext;
  final RouteContext? activeRouteContext;
  final LocationContext? locationContext;
  final UserPreferences? userPreferences;
  final List<DialogueSummary> dialogueHistory;
  final List<String> pendingToolCallIds;

  const ConversationContext({
    required this.conversationId,
    required this.userId,
    required this.createdAt,
    this.lastMessageAt,
    this.state = DialogueState.active,
    this.globalContext = const {},
    this.activeRouteContext,
    this.locationContext,
    this.userPreferences,
    this.dialogueHistory = const [],
    this.pendingToolCallIds = const [],
  });

  factory ConversationContext.initial(String userId, String conversationId) {
    return ConversationContext(
      conversationId: conversationId,
      userId: userId,
      createdAt: DateTime.now(),
      globalContext: {
        'language': 'zh',
        'userLevel': 'casual',
      },
    );
  }

  ConversationContext copyWith({
    String? conversationId,
    String? userId,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    DialogueState? state,
    Map<String, dynamic>? globalContext,
    RouteContext? activeRouteContext,
    LocationContext? locationContext,
    UserPreferences? userPreferences,
    List<DialogueSummary>? dialogueHistory,
    List<String>? pendingToolCallIds,
  }) {
    return ConversationContext(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      state: state ?? this.state,
      globalContext: globalContext ?? this.globalContext,
      activeRouteContext: activeRouteContext ?? this.activeRouteContext,
      locationContext: locationContext ?? this.locationContext,
      userPreferences: userPreferences ?? this.userPreferences,
      dialogueHistory: dialogueHistory ?? this.dialogueHistory,
      pendingToolCallIds: pendingToolCallIds ?? this.pendingToolCallIds,
    );
  }
}

/// 路线上下文
class RouteContext {
  final String routeId;
  final String? routeName;
  final double? distance;
  final double? elevationGain;
  final String? difficulty;
  final LocationData? userLocation;
  final List<String> visitedWaypoints;

  const RouteContext({
    required this.routeId,
    this.routeName,
    this.distance,
    this.elevationGain,
    this.difficulty,
    this.userLocation,
    this.visitedWaypoints = const [],
  });
}

/// 位置上下文
class LocationContext {
  final LocationData? currentLocation;
  final String? currentArea;
  final String? nearestTrailhead;
  final bool isOnTrail;

  const LocationContext({
    this.currentLocation,
    this.currentArea,
    this.nearestTrailhead,
    this.isOnTrail = false,
  });
}

/// 位置数据
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final DateTime? timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.timestamp,
  });
}

/// 用户偏好
class UserPreferences {
  final String language;
  final String distanceUnit;
  final String difficultyPreference;
  final bool notificationsEnabled;

  const UserPreferences({
    this.language = 'zh',
    this.distanceUnit = 'km',
    this.difficultyPreference = 'casual',
    this.notificationsEnabled = true,
  });
}

/// 对话摘要
class DialogueSummary {
  final DateTime timestamp;
  final String intent;
  final String briefSummary;

  const DialogueSummary({
    required this.timestamp,
    required this.intent,
    required this.briefSummary,
  });
}
