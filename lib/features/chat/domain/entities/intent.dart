/// 意图类别
enum IntentCategory {
  routeSearch,
  routeDetail,
  routeRecommendation,
  routeComparison,
  navigation,
  tracking,
  weatherQuery,
  weatherAlert,
  fitnessQuery,
  restAdvice,
  emergency,
  safetyCheck,
  greeting,
  farewell,
  feedback,
  settings,
  help,
  plantIdentification,
  trainingPlan,
  unknown,
}

/// 意图
class Intent {
  final IntentCategory category;
  final double confidence;
  final Map<String, dynamic> entities;
  final Map<String, dynamic> parameters;
  final String? quickResponse;
  final ToolCallInfo? toolCall;

  const Intent({
    required this.category,
    required this.confidence,
    this.entities = const {},
    this.parameters = const {},
    this.quickResponse,
    this.toolCall,
  });

  /// 是否是快速响应（本地可处理）
  bool get isQuickResponse =>
      quickResponse != null || isGreeting || isFarewell || isHelp;

  bool get isGreeting => category == IntentCategory.greeting;
  bool get isFarewell => category == IntentCategory.farewell;
  bool get isHelp => category == IntentCategory.help;
  bool get isEmergency => category == IntentCategory.emergency;
  bool get requiresToolCall => toolCall != null;

  String get displayName {
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
}

/// 工具调用信息
class ToolCallInfo {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCallInfo({
    required this.id,
    required this.name,
    required this.arguments,
  });
}
