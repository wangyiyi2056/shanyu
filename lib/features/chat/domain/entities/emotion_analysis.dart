/// 情绪类型
enum EmotionType {
  calm, // 平静
  happy, // 开心
  anxious, // 焦虑
  frustrated, // 沮丧/挫败
  angry, // 愤怒
  scared, // 害怕
  excited, // 兴奋
  tired, // 疲惫
  confused, // 困惑
  unknown, // 未知
}

/// 紧迫度等级
enum UrgencyLevel {
  normal, // 正常
  low, // 较低
  medium, // 中等
  high, // 高
  critical, // 紧急
}

/// 建议的回复风格
enum ResponseTone {
  normal, // 正常
  empathetic, // 共情/安慰
  urgent, // 紧急/果断
  calm, // 冷静/安抚
  encouraging, // 鼓励
  concise, // 简洁（紧急时）
}

/// 情绪与紧迫度分析结果
class EmotionAnalysisResult {
  final EmotionType emotion;
  final UrgencyLevel urgencyLevel;
  final double confidence; // 0.0 - 1.0
  final ResponseTone suggestedTone;
  final String reason;
  final String? advice; // 给系统的建议（如何回应）

  const EmotionAnalysisResult({
    required this.emotion,
    required this.urgencyLevel,
    required this.confidence,
    required this.suggestedTone,
    required this.reason,
    this.advice,
  });

  factory EmotionAnalysisResult.neutral() {
    return const EmotionAnalysisResult(
      emotion: EmotionType.unknown,
      urgencyLevel: UrgencyLevel.normal,
      confidence: 0.0,
      suggestedTone: ResponseTone.normal,
      reason: '未检测到明显情绪',
    );
  }

  /// 是否需要触发安全分析
  bool get shouldTriggerSafetyCheck =>
      urgencyLevel == UrgencyLevel.high ||
      urgencyLevel == UrgencyLevel.critical ||
      emotion == EmotionType.scared;

  /// 是否需要在上下文中提及情绪
  bool get shouldIncludeInContext =>
      emotion != EmotionType.unknown || urgencyLevel != UrgencyLevel.normal;

  String get emotionLabel => switch (emotion) {
    EmotionType.calm => '平静',
    EmotionType.happy => '开心',
    EmotionType.anxious => '焦虑',
    EmotionType.frustrated => '沮丧',
    EmotionType.angry => '愤怒',
    EmotionType.scared => '害怕',
    EmotionType.excited => '兴奋',
    EmotionType.tired => '疲惫',
    EmotionType.confused => '困惑',
    EmotionType.unknown => '未知',
  };

  String get urgencyLabel => switch (urgencyLevel) {
    UrgencyLevel.normal => '正常',
    UrgencyLevel.low => '较低',
    UrgencyLevel.medium => '中等',
    UrgencyLevel.high => '高',
    UrgencyLevel.critical => '紧急',
  };

  String get toneLabel => switch (suggestedTone) {
    ResponseTone.normal => '正常',
    ResponseTone.empathetic => '共情',
    ResponseTone.urgent => '紧急',
    ResponseTone.calm => '冷静安抚',
    ResponseTone.encouraging => '鼓励',
    ResponseTone.concise => '简洁',
  };
}
