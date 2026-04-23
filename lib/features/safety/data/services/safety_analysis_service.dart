import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/features/safety/domain/entities/safety_alert.dart';

/// 安全分析服务
///
/// 使用 Claude API 分析用户消息中的安全风险等级，
/// 并结合天气、位置等上下文信息生成安全建议。
class SafetyAnalysisService {
  final ClaudeAPIService _claudeAPI;

  SafetyAnalysisService({required ClaudeAPIService claudeAPI})
      : _claudeAPI = claudeAPI;

  /// 分析用户消息的安全风险
  ///
  /// 返回安全分析结果，包含风险等级和建议
  Future<SafetyAnalysisResult> analyzeMessageSafety(
    String userMessage, {
    String? weatherContext,
    String? locationContext,
    bool isTracking = false,
  }) async {
    // 先进行快速的本地关键词检测（用于紧急情况的即时响应）
    final localCheck = _localSafetyCheck(userMessage);
    if (localCheck.level == SafetyLevel.emergency) {
      return localCheck;
    }

    // 对于非紧急消息，使用 Claude API 进行深度分析
    try {
      final systemPrompt = '''你是一个户外安全分析专家，专注于爬山和徒步活动的安全风险评估。

## 分析维度
1. **身体状况**：用户是否提到疲劳、受伤、头晕、呼吸困难等症状
2. **环境风险**：天气恶劣、天黑、迷路、地形危险等
3. **装备问题**：缺水、缺食物、装备损坏、电量不足等
4. **心理状态**：恐慌、焦虑、过度自信等
5. **行为风险**：单独行动、冒险行为、违反安全规则等

## 输出格式
必须使用以下 JSON 格式回复（不要添加其他内容）：

```json
{
  "level": "safe|caution|warning|danger|emergency",
  "reason": "风险评估原因，简短说明",
  "advice": "给用户的具体建议",
  "alertType": "weatherAlert|routeDeviation|stationaryTooLong|sosSignal|lowBattery|noSignal|healthRisk|terrainDanger|nightfall|null"
}
```

## 等级定义
- safe: 一切正常，无需担心
- caution: 需要注意，但风险可控
- warning: 存在明显风险，建议立即采取预防措施
- danger: 危险情况，必须立即处理
- emergency: 紧急情况，需要救援

## 重要原则
1. 安全第一，宁可过度警告也不要遗漏风险
2. 如果用户提到受伤、迷路、极端天气等，必须标记为 danger 或 emergency
3. 提供具体、可操作的建议，不要泛泛而谈''';

      final contextInfo = _buildContextInfo(
        weatherContext: weatherContext,
        locationContext: locationContext,
        isTracking: isTracking,
      );

      final response = await _claudeAPI.sendMessage(
        systemPrompt: systemPrompt,
        conversationHistory: const [],
        userMessage: '请分析以下用户消息的安全风险：\n\n$userMessage\n\n$contextInfo',
        maxTokens: 1024,
        enableCaching: false,
      );

      return _parseAnalysisResponse(response.textContent);
    } on Exception catch (_) {
      // API 失败时回退到本地检测
      return localCheck;
    }
  }

  /// 本地快速安全检测（无需 API）
  SafetyAnalysisResult _localSafetyCheck(String message) {
    final lowerMessage = message.toLowerCase();

    // 紧急关键词
    final emergencyKeywords = [
      '救命', '求救', 'sos', '快死了', '不行了', '失去意识',
      '严重受伤', '骨折', '大出血', '心脏病', '昏迷',
    ];
    for (final keyword in emergencyKeywords) {
      if (lowerMessage.contains(keyword)) {
        return SafetyAnalysisResult(
          level: SafetyLevel.emergency,
          reason: '检测到紧急求救信号：$keyword',
          advice: '【紧急】请立即拨打 120 或当地救援电话。如果可能，发送您的位置给紧急联系人。保持冷静，等待救援。',
          suggestedAlerts: [
            SafetyAlert(
              id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
              type: SafetyAlertType.sosSignal,
              level: SafetyLevel.emergency,
              title: '紧急求救',
              message: '检测到紧急求救信号，请立即采取行动',
              actionLabel: '查看紧急指南',
              actionRoute: '/help',
              createdAt: DateTime.now(),
            ),
          ],
        );
      }
    }

    // 危险关键词
    final dangerKeywords = [
      '迷路', '找不到路', '被困', '摔伤', '扭到', '流血',
      '暴雨', '雷电', '大雾', '冰雹', '山体滑坡', '泥石流',
      '没水', '没食物', '手机没电', '没信号',
    ];
    for (final keyword in dangerKeywords) {
      if (lowerMessage.contains(keyword)) {
        return SafetyAnalysisResult(
          level: SafetyLevel.danger,
          reason: '检测到安全风险：$keyword',
          advice: '【注意】您当前可能面临安全风险。建议：1) 评估当前状况 2) 联系同伴或救援人员 3) 寻找安全地点等待',
          suggestedAlerts: [
            SafetyAlert(
              id: 'danger_${DateTime.now().millisecondsSinceEpoch}',
              type: SafetyAlertType.healthRisk,
              level: SafetyLevel.danger,
              title: '安全风险 detected',
              message: '检测到可能的安全风险：$keyword',
              createdAt: DateTime.now(),
            ),
          ],
        );
      }
    }

    // 警告关键词
    final warningKeywords = [
      '累了', '疲劳', '腿软', '头晕', '恶心', '喘不过气',
      '天黑', '降温', '刮风', '下雨', '路滑', '陡峭',
      '一个人', '独自', '没经验',
    ];
    for (final keyword in warningKeywords) {
      if (lowerMessage.contains(keyword)) {
        return SafetyAnalysisResult(
          level: SafetyLevel.warning,
          reason: '检测到潜在风险：$keyword',
          advice: '请注意身体状况和环境变化。建议适时休息，评估是否继续行程。',
        );
      }
    }

    // 注意关键词
    final cautionKeywords = [
      '有点累', '出汗', '口渴', '微热', '稍远',
    ];
    for (final keyword in cautionKeywords) {
      if (lowerMessage.contains(keyword)) {
        return SafetyAnalysisResult(
          level: SafetyLevel.caution,
          reason: '检测到轻微疲劳或不适',
          advice: '建议适当休息，补充水分和能量。',
        );
      }
    }

    return SafetyAnalysisResult.safe();
  }

  String _buildContextInfo({
    String? weatherContext,
    String? locationContext,
    bool isTracking = false,
  }) {
    final buffer = StringBuffer();
    if (weatherContext != null && weatherContext.isNotEmpty) {
      buffer.writeln('当前天气：$weatherContext');
    }
    if (locationContext != null && locationContext.isNotEmpty) {
      buffer.writeln('当前位置：$locationContext');
    }
    if (isTracking) {
      buffer.writeln('用户正在记录轨迹（正在爬山中）');
    }
    return buffer.toString();
  }

  SafetyAnalysisResult _parseAnalysisResponse(String response) {
    try {
      // 尝试从响应中提取 JSON
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(response);
      if (jsonMatch == null) {
        return SafetyAnalysisResult.safe();
      }

      final jsonStr = jsonMatch.group(0)!;
      // 简单的手动解析（避免依赖 json 库）
      final level = _extractJsonValue(jsonStr, 'level');
      final reason = _extractJsonValue(jsonStr, 'reason');
      final advice = _extractJsonValue(jsonStr, 'advice');
      final alertType = _extractJsonValue(jsonStr, 'alertType');

      final safetyLevel = _parseSafetyLevel(level);

      // 如果分析结果是安全的，不生成警报
      if (safetyLevel == SafetyLevel.safe) {
        return SafetyAnalysisResult(
          level: safetyLevel,
          reason: reason ?? '未检测到安全风险',
          advice: advice ?? '继续保持，注意安全',
        );
      }

      // 生成安全警报
      final alert = SafetyAlert(
        id: 'ai_safety_${DateTime.now().millisecondsSinceEpoch}',
        type: _parseAlertType(alertType),
        level: safetyLevel,
        title: '安全提醒',
        message: reason ?? '检测到潜在安全风险',
        createdAt: DateTime.now(),
      );

      return SafetyAnalysisResult(
        level: safetyLevel,
        reason: reason ?? '',
        advice: advice ?? '',
        suggestedAlerts: [alert],
      );
    } on Exception catch (_) {
      return SafetyAnalysisResult.safe();
    }
  }

  String? _extractJsonValue(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  SafetyLevel _parseSafetyLevel(String? level) {
    return switch (level) {
      'emergency' => SafetyLevel.emergency,
      'danger' => SafetyLevel.danger,
      'warning' => SafetyLevel.warning,
      'caution' => SafetyLevel.caution,
      _ => SafetyLevel.safe,
    };
  }

  SafetyAlertType _parseAlertType(String? type) {
    return switch (type) {
      'weatherAlert' => SafetyAlertType.weatherAlert,
      'routeDeviation' => SafetyAlertType.routeDeviation,
      'stationaryTooLong' => SafetyAlertType.stationaryTooLong,
      'sosSignal' => SafetyAlertType.sosSignal,
      'lowBattery' => SafetyAlertType.lowBattery,
      'noSignal' => SafetyAlertType.noSignal,
      'healthRisk' => SafetyAlertType.healthRisk,
      'terrainDanger' => SafetyAlertType.terrainDanger,
      'nightfall' => SafetyAlertType.nightfall,
      _ => SafetyAlertType.healthRisk,
    };
  }

  /// 根据天气数据生成天气预警
  SafetyAlert? generateWeatherAlert(String weatherDescription,
      double temperature, double windSpeed,) {
    // 极端天气检测
    if (weatherDescription.contains('暴雨') ||
        weatherDescription.contains('雷电') ||
        weatherDescription.contains('冰雹')) {
      return SafetyAlert(
        id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
        type: SafetyAlertType.weatherAlert,
        level: SafetyLevel.danger,
        title: '极端天气预警',
        message: '当前天气状况恶劣（$weatherDescription），建议立即寻找安全地点躲避，暂停爬山活动。',
        actionLabel: '查看天气详情',
        actionRoute: '/weather-detail',
        createdAt: DateTime.now(),
      );
    }

    if (windSpeed > 50) {
      return SafetyAlert(
        id: 'weather_wind_${DateTime.now().millisecondsSinceEpoch}',
        type: SafetyAlertType.weatherAlert,
        level: SafetyLevel.warning,
        title: '大风预警',
        message: '当前风速 ${windSpeed.toStringAsFixed(0)} km/h，山区大风可能导致危险，请注意安全。',
        createdAt: DateTime.now(),
      );
    }

    if (temperature < 0) {
      return SafetyAlert(
        id: 'weather_temp_${DateTime.now().millisecondsSinceEpoch}',
        type: SafetyAlertType.weatherAlert,
        level: SafetyLevel.caution,
        title: '低温提醒',
        message: '当前温度 ${temperature.toStringAsFixed(0)}°C，注意防寒保暖，防止失温。',
        createdAt: DateTime.now(),
      );
    }

    if (temperature > 35) {
      return SafetyAlert(
        id: 'weather_heat_${DateTime.now().millisecondsSinceEpoch}',
        type: SafetyAlertType.weatherAlert,
        level: SafetyLevel.caution,
        title: '高温提醒',
        message: '当前温度 ${temperature.toStringAsFixed(0)}°C，注意防暑降温，及时补充水分。',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }
}
