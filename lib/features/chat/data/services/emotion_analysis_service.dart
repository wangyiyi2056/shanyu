import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/features/chat/domain/entities/emotion_analysis.dart';

/// 情绪与紧迫度分析服务
///
/// 结合本地关键词检测和 Claude API 深度分析，
/// 识别用户消息中的情绪状态和紧迫程度。
class EmotionAnalysisService {
  final ClaudeAPIService _claudeAPI;

  EmotionAnalysisService({required ClaudeAPIService claudeAPI})
      : _claudeAPI = claudeAPI;

  /// 分析用户消息的情绪和紧迫度
  Future<EmotionAnalysisResult> analyze(String userMessage) async {
    // 先进行本地快速检测
    final localResult = _localEmotionCheck(userMessage);
    if (localResult.confidence >= 0.8) {
      return localResult;
    }

    // 使用 Claude API 进行深度分析
    try {
      final systemPrompt = '''你是一个情绪与紧迫度分析专家。请分析用户消息中的情绪状态和紧迫程度。

## 分析维度
1. **情绪类型**: calm(平静), happy(开心), anxious(焦虑), frustrated(沮丧), angry(愤怒), scared(害怕), excited(兴奋), tired(疲惫), confused(困惑)
2. **紧迫度**: normal(正常), low(较低), medium(中等), high(高), critical(紧急)
3. **建议回复风格**: normal(正常), empathetic(共情), urgent(紧急), calm(冷静安抚), encouraging(鼓励), concise(简洁)

## 输出格式
使用以下 JSON 格式（不要添加其他内容）：

{
  "emotion": "calm|happy|anxious|frustrated|angry|scared|excited|tired|confused",
  "urgency": "normal|low|medium|high|critical",
  "confidence": 0.85,
  "tone": "normal|empathetic|urgent|calm|encouraging|concise",
  "reason": "简短说明检测原因",
  "advice": "给AI助手的回复建议"
}

## 判断标准
- critical: 用户表达生命危险、严重受伤、极度恐慌
- high: 用户明显焦虑、害怕、遇到紧急困难
- medium: 用户有些担心、困惑、轻微不适
- low: 用户略带疲惫或稍有不耐烦
- normal: 情绪平稳或积极''';

      final response = await _claudeAPI.sendMessage(
        systemPrompt: systemPrompt,
        conversationHistory: const [],
        userMessage: '请分析以下用户消息：\n\n$userMessage',
        maxTokens: 512,
        enableCaching: false,
      );

      return _parseAnalysisResponse(response.textContent);
    } on Exception catch (_) {
      return localResult.confidence > 0
          ? localResult
          : EmotionAnalysisResult.neutral();
    }
  }

  /// 本地快速情绪检测
  EmotionAnalysisResult _localEmotionCheck(String message) {
    final lowerMessage = message.toLowerCase();

    // 紧急/害怕检测 (critical)
    final criticalPatterns = [
      ('救命', EmotionType.scared),
      ('快死了', EmotionType.scared),
      ('要死了', EmotionType.scared),
      ('极度恐慌', EmotionType.scared),
      ('崩溃了', EmotionType.anxious),
    ];
    for (final (keyword, emotion) in criticalPatterns) {
      if (lowerMessage.contains(keyword)) {
        return EmotionAnalysisResult(
          emotion: emotion,
          urgencyLevel: UrgencyLevel.critical,
          confidence: 0.95,
          suggestedTone: ResponseTone.urgent,
          reason: '检测到紧急情绪表达: $keyword',
          advice: '立即确认用户安全状况，提供紧急帮助指引',
        );
      }
    }

    // 高紧迫度检测 (high)
    final highPatterns = [
      ('好害怕', EmotionType.scared),
      ('怎么办', EmotionType.anxious),
      ('急死了', EmotionType.anxious),
      ('迷路了', EmotionType.scared),
      ('受伤', EmotionType.anxious),
      ('疼', EmotionType.anxious),
      ('不敢走了', EmotionType.scared),
      (' stranded', EmotionType.scared),
    ];
    for (final (keyword, emotion) in highPatterns) {
      if (lowerMessage.contains(keyword)) {
        return EmotionAnalysisResult(
          emotion: emotion,
          urgencyLevel: UrgencyLevel.high,
          confidence: 0.85,
          suggestedTone: ResponseTone.calm,
          reason: '检测到高紧迫度情绪: $keyword',
          advice: '保持冷静安抚的语气，优先处理用户的安全和情绪',
        );
      }
    }

    // 焦虑/沮丧检测 (medium)
    final mediumPatterns = [
      ('担心', EmotionType.anxious),
      ('紧张', EmotionType.anxious),
      ('焦虑', EmotionType.anxious),
      ('好累', EmotionType.tired),
      ('爬不动', EmotionType.tired),
      ('走不动了', EmotionType.tired),
      ('太难了', EmotionType.frustrated),
      ('后悔', EmotionType.frustrated),
      ('不应该', EmotionType.frustrated),
      ('迷路', EmotionType.confused),
      ('找不到', EmotionType.confused),
    ];
    for (final (keyword, emotion) in mediumPatterns) {
      if (lowerMessage.contains(keyword)) {
        return EmotionAnalysisResult(
          emotion: emotion,
          urgencyLevel: UrgencyLevel.medium,
          confidence: 0.7,
          suggestedTone: emotion == EmotionType.tired
              ? ResponseTone.encouraging
              : ResponseTone.empathetic,
          reason: '检测到中等情绪信号: $keyword',
          advice: '表达理解和共情，提供具体可行的建议',
        );
      }
    }

    // 低紧迫度检测 (low)
    final lowPatterns = [
      ('有点累', EmotionType.tired),
      ('腿酸', EmotionType.tired),
      ('出汗', EmotionType.tired),
      ('口渴', EmotionType.tired),
      ('有点远', EmotionType.anxious),
      ('还有多久', EmotionType.anxious),
    ];
    for (final (keyword, emotion) in lowPatterns) {
      if (lowerMessage.contains(keyword)) {
        return EmotionAnalysisResult(
          emotion: emotion,
          urgencyLevel: UrgencyLevel.low,
          confidence: 0.6,
          suggestedTone: ResponseTone.encouraging,
          reason: '检测到轻微疲劳或担忧: $keyword',
          advice: '给予温和的鼓励和实用建议',
        );
      }
    }

    // 积极情绪检测
    final positivePatterns = [
      ('开心', EmotionType.happy),
      ('太美了', EmotionType.excited),
      ('很棒', EmotionType.happy),
      ('喜欢', EmotionType.happy),
      ('兴奋', EmotionType.excited),
      ('爽', EmotionType.excited),
      ('厉害', EmotionType.excited),
    ];
    for (final (keyword, emotion) in positivePatterns) {
      if (lowerMessage.contains(keyword)) {
        return EmotionAnalysisResult(
          emotion: emotion,
          urgencyLevel: UrgencyLevel.normal,
          confidence: 0.65,
          suggestedTone: ResponseTone.encouraging,
          reason: '检测到积极情绪: $keyword',
          advice: '保持积极互动，分享用户的喜悦',
        );
      }
    }

    return EmotionAnalysisResult.neutral();
  }

  EmotionAnalysisResult _parseAnalysisResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(response);
      if (jsonMatch == null) return EmotionAnalysisResult.neutral();

      final jsonStr = jsonMatch.group(0)!;
      final emotion = _extractJsonValue(jsonStr, 'emotion');
      final urgency = _extractJsonValue(jsonStr, 'urgency');
      final tone = _extractJsonValue(jsonStr, 'tone');
      final reason = _extractJsonValue(jsonStr, 'reason');
      final advice = _extractJsonValue(jsonStr, 'advice');
      final confidenceStr = _extractJsonValue(jsonStr, 'confidence');
      final confidence = double.tryParse(confidenceStr ?? '0.5') ?? 0.5;

      return EmotionAnalysisResult(
        emotion: _parseEmotion(emotion),
        urgencyLevel: _parseUrgency(urgency),
        confidence: confidence.clamp(0.0, 1.0),
        suggestedTone: _parseTone(tone),
        reason: reason ?? 'AI分析结果',
        advice: advice,
      );
    } on Exception catch (_) {
      return EmotionAnalysisResult.neutral();
    }
  }

  String? _extractJsonValue(String json, String key) {
    final pattern = RegExp(r'"$key"\s*:\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    if (match != null) return match.group(1);

    // Try number format
    final numPattern = RegExp(r'"$key"\s*:\s*([0-9.]+)');
    final numMatch = numPattern.firstMatch(json);
    return numMatch?.group(1);
  }

  EmotionType _parseEmotion(String? value) {
    return switch (value) {
      'calm' => EmotionType.calm,
      'happy' => EmotionType.happy,
      'anxious' => EmotionType.anxious,
      'frustrated' => EmotionType.frustrated,
      'angry' => EmotionType.angry,
      'scared' => EmotionType.scared,
      'excited' => EmotionType.excited,
      'tired' => EmotionType.tired,
      'confused' => EmotionType.confused,
      _ => EmotionType.unknown,
    };
  }

  UrgencyLevel _parseUrgency(String? value) {
    return switch (value) {
      'critical' => UrgencyLevel.critical,
      'high' => UrgencyLevel.high,
      'medium' => UrgencyLevel.medium,
      'low' => UrgencyLevel.low,
      _ => UrgencyLevel.normal,
    };
  }

  ResponseTone _parseTone(String? value) {
    return switch (value) {
      'empathetic' => ResponseTone.empathetic,
      'urgent' => ResponseTone.urgent,
      'calm' => ResponseTone.calm,
      'encouraging' => ResponseTone.encouraging,
      'concise' => ResponseTone.concise,
      _ => ResponseTone.normal,
    };
  }
}
