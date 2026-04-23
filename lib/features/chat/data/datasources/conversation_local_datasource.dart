import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';

/// 对话本地数据源
///
/// 使用 SharedPreferences 持久化存储：
/// - 对话历史（最近 N 条）
/// - 用户偏好摘要
/// - 常去地点
/// - 对话主题统计
class ConversationLocalDatasource {
  static const String _prefsKeyPrefix = 'chat_memory_';
  static const String _conversationHistoryKey = '${_prefsKeyPrefix}history';
  static const String _userProfileKey = '${_prefsKeyPrefix}user_profile';
  static const String _frequentLocationsKey = '${_prefsKeyPrefix}locations';
  static const String _topicStatsKey = '${_prefsKeyPrefix}topics';
  static const int _maxStoredMessages = 100;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 保存对话历史
  Future<void> saveConversationHistory(List<Message> messages) async {
    final prefs = await _preferences;
    // 只保留最近的 N 条消息
    final messagesToStore = messages.length > _maxStoredMessages
        ? messages.sublist(messages.length - _maxStoredMessages)
        : messages;

    final jsonList = messagesToStore.map((m) => _messageToJson(m)).toList();
    await prefs.setString(_conversationHistoryKey, jsonEncode(jsonList));
  }

  /// 读取对话历史
  Future<List<Message>> loadConversationHistory() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_conversationHistoryKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((j) => _messageFromJson(j as Map<String, dynamic>)).toList();
    } on Exception catch (_) {
      return [];
    }
  }

  /// 保存用户画像（偏好、习惯等）
  Future<void> saveUserProfile(UserMemoryProfile profile) async {
    final prefs = await _preferences;
    await prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  /// 读取用户画像
  Future<UserMemoryProfile?> loadUserProfile() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_userProfileKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      return UserMemoryProfile.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  /// 记录访问过的地点
  Future<void> recordLocation(String locationName, {int weight = 1}) async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_frequentLocationsKey);
    final Map<String, int> locations = {};

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          locations[key] = (value as num).toInt();
        });
      } on Exception catch (_) {}
    }

    locations[locationName] = (locations[locationName] ?? 0) + weight;

    // 只保留前 20 个最常访问的地点
    final sortedEntries = locations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLocations = Map<String, int>.fromEntries(
      sortedEntries.take(20),
    );

    await prefs.setString(_frequentLocationsKey, jsonEncode(topLocations));
  }

  /// 获取常去地点
  Future<Map<String, int>> loadFrequentLocations() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_frequentLocationsKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((key, value) =>
        MapEntry(key, (value as num).toInt()),
      );
    } on Exception catch (_) {
      return {};
    }
  }

  /// 记录对话主题统计
  Future<void> recordTopic(String topic, {int weight = 1}) async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_topicStatsKey);
    final Map<String, int> topics = {};

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          topics[key] = (value as num).toInt();
        });
      } on Exception catch (_) {}
    }

    topics[topic] = (topics[topic] ?? 0) + weight;

    // 只保留前 30 个主题
    final sortedEntries = topics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTopics = Map<String, int>.fromEntries(
      sortedEntries.take(30),
    );

    await prefs.setString(_topicStatsKey, jsonEncode(topTopics));
  }

  /// 获取热门话题
  Future<Map<String, int>> loadTopicStats() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_topicStatsKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((key, value) =>
        MapEntry(key, (value as num).toInt()),
      );
    } on Exception catch (_) {
      return {};
    }
  }

  /// 清除所有记忆
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_conversationHistoryKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_frequentLocationsKey);
    await prefs.remove(_topicStatsKey);
  }

  // 消息序列化
  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'conversationId': message.conversationId,
      'role': message.role.name,
      'content': message.content,
      'createdAt': message.createdAt.toIso8601String(),
      'messageType': message.messageType.name,
      'intent': message.intent,
    };
  }

  Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      messageType: MessageType.values.byName(json['messageType'] as String),
      intent: json['intent'] as String?,
    );
  }
}

/// 用户记忆画像
class UserMemoryProfile {
  final String? preferredDifficulty;
  final String? preferredDistance;
  final String? preferredDuration;
  final List<String> favoriteRoutes;
  final List<String> dislikedRoutes;
  final String? fitnessLevel;
  final String? commonConcerns;
  final DateTime? lastUpdated;

  const UserMemoryProfile({
    this.preferredDifficulty,
    this.preferredDistance,
    this.preferredDuration,
    this.favoriteRoutes = const [],
    this.dislikedRoutes = const [],
    this.fitnessLevel,
    this.commonConcerns,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'preferredDifficulty': preferredDifficulty,
      'preferredDistance': preferredDistance,
      'preferredDuration': preferredDuration,
      'favoriteRoutes': favoriteRoutes,
      'dislikedRoutes': dislikedRoutes,
      'fitnessLevel': fitnessLevel,
      'commonConcerns': commonConcerns,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserMemoryProfile.fromJson(Map<String, dynamic> json) {
    return UserMemoryProfile(
      preferredDifficulty: json['preferredDifficulty'] as String?,
      preferredDistance: json['preferredDistance'] as String?,
      preferredDuration: json['preferredDuration'] as String?,
      favoriteRoutes: (json['favoriteRoutes'] as List?)?.cast<String>() ?? [],
      dislikedRoutes: (json['dislikedRoutes'] as List?)?.cast<String>() ?? [],
      fitnessLevel: json['fitnessLevel'] as String?,
      commonConcerns: json['commonConcerns'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  UserMemoryProfile copyWith({
    String? preferredDifficulty,
    String? preferredDistance,
    String? preferredDuration,
    List<String>? favoriteRoutes,
    List<String>? dislikedRoutes,
    String? fitnessLevel,
    String? commonConcerns,
    DateTime? lastUpdated,
  }) {
    return UserMemoryProfile(
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      preferredDistance: preferredDistance ?? this.preferredDistance,
      preferredDuration: preferredDuration ?? this.preferredDuration,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      dislikedRoutes: dislikedRoutes ?? this.dislikedRoutes,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      commonConcerns: commonConcerns ?? this.commonConcerns,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
