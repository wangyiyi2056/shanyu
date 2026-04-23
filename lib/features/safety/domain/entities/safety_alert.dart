/// 安全警报等级
enum SafetyLevel {
  safe,      // 安全
  caution,   // 注意
  warning,   // 警告
  danger,    // 危险
  emergency, // 紧急
}

/// 安全警报类型
enum SafetyAlertType {
  weatherAlert,      // 天气预警
  routeDeviation,    // 路线偏离
  stationaryTooLong, // 长时间停留
  sosSignal,         // SOS 信号
  lowBattery,        // 低电量
  noSignal,          // 无信号
  healthRisk,        // 健康风险
  terrainDanger,     // 地形危险
  nightfall,         // 天黑提醒
}

/// 安全警报
class SafetyAlert {
  final String id;
  final SafetyAlertType type;
  final SafetyLevel level;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const SafetyAlert({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  SafetyAlert copyWith({
    String? id,
    SafetyAlertType? type,
    SafetyLevel? level,
    String? title,
    String? message,
    String? actionLabel,
    String? actionRoute,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return SafetyAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      level: level ?? this.level,
      title: title ?? this.title,
      message: message ?? this.message,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 是否需要立即关注
  bool get requiresImmediateAttention =>
      level == SafetyLevel.danger || level == SafetyLevel.emergency;

  /// 等级显示名称
  String get levelDisplayName {
    return switch (level) {
      SafetyLevel.safe => '安全',
      SafetyLevel.caution => '注意',
      SafetyLevel.warning => '警告',
      SafetyLevel.danger => '危险',
      SafetyLevel.emergency => '紧急',
    };
  }

  /// 类型显示名称
  String get typeDisplayName {
    return switch (type) {
      SafetyAlertType.weatherAlert => '天气预警',
      SafetyAlertType.routeDeviation => '路线偏离',
      SafetyAlertType.stationaryTooLong => '停留过久',
      SafetyAlertType.sosSignal => '求救信号',
      SafetyAlertType.lowBattery => '电量不足',
      SafetyAlertType.noSignal => '信号中断',
      SafetyAlertType.healthRisk => '健康风险',
      SafetyAlertType.terrainDanger => '地形危险',
      SafetyAlertType.nightfall => '天黑提醒',
    };
  }

  /// 等级对应颜色
  int get levelColor {
    return switch (level) {
      SafetyLevel.safe => 0xFF22C55E,
      SafetyLevel.caution => 0xFFF59E0B,
      SafetyLevel.warning => 0xFFF97316,
      SafetyLevel.danger => 0xFFEF4444,
      SafetyLevel.emergency => 0xFFDC2626,
    };
  }
}

/// 安全分析结果
class SafetyAnalysisResult {
  final SafetyLevel level;
  final String reason;
  final String advice;
  final List<SafetyAlert> suggestedAlerts;

  const SafetyAnalysisResult({
    required this.level,
    required this.reason,
    required this.advice,
    this.suggestedAlerts = const [],
  });

  factory SafetyAnalysisResult.safe() {
    return const SafetyAnalysisResult(
      level: SafetyLevel.safe,
      reason: '未检测到安全风险',
      advice: '继续保持，注意安全',
    );
  }
}
