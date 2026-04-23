import 'dart:convert';

import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/features/training/domain/entities/training_plan.dart';

/// 智能训练计划服务
///
/// 根据用户画像、体能水平和目标，生成个性化的爬山训练计划。
class TrainingPlanService {
  final ClaudeAPIService _claudeAPI;

  TrainingPlanService({required ClaudeAPIService claudeAPI})
      : _claudeAPI = claudeAPI;

  /// 生成训练计划
  ///
  /// [fitnessLevel] - 体能水平：新手/初级/中级/高级/专业
  /// [goal] - 目标：如"准备爬香山"、"提升耐力"、"挑战泰山"
  /// [weeks] - 计划周数，默认4周
  Future<TrainingPlan?> generatePlan({
    String? fitnessLevel,
    String? goal,
    int weeks = 4,
  }) async {
    final systemPrompt = '''你是一个专业的户外体能训练教练，擅长为爬山爱好者制定科学的训练计划。

## 训练计划原则
1. 循序渐进：每周强度递增不超过10%
2. 多样化：包含有氧、力量、柔韧性和模拟徒步
3. 恢复很重要：每周至少安排1-2天休息或低强度恢复
4. 个性化：根据用户当前体能水平调整强度

## 输出格式
使用以下 JSON 格式输出（不要添加其他内容）：

{
  "name": "计划名称",
  "description": "计划简介",
  "level": "beginner|intermediate|advanced",
  "schedule": [
    {
      "weekNumber": 1,
      "dayNumber": 1,
      "type": "cardio|strength|flexibility|hiking|rest",
      "title": "训练标题",
      "description": "具体训练内容和注意事项",
      "durationMinutes": 30,
      "targetElevation": 0,
      "targetDistance": 0,
      "isRestDay": false
    }
  ]
}

## 训练类型说明
- cardio: 跑步、游泳、骑行等有氧训练
- strength: 腿部力量、核心训练、深蹲、弓步等
- flexibility: 拉伸、瑜伽、泡沫轴放松
- hiking: 短途徒步、楼梯训练、负重行走
- rest: 完全休息或轻度拉伸

## 重要
- 每周安排5-6天训练，1-2天休息
- 描述要具体、可操作
- 必须包含热身和放松环节的时间''';

    final userPrompt = '''请为我制定一个$weeks周的爬山训练计划。

${fitnessLevel != null ? '当前体能水平：$fitnessLevel' : ''}
${goal != null ? '训练目标：$goal' : ''}

请输出完整的 JSON 训练计划。''';

    try {
      final response = await _claudeAPI.sendMessage(
        systemPrompt: systemPrompt,
        conversationHistory: const [],
        userMessage: userPrompt,
        maxTokens: 4000,
        enableCaching: false,
      );

      return _parseTrainingPlan(response.textContent);
    } on Exception catch (_) {
      // 如果 API 失败，返回默认计划
      return _getDefaultPlan(fitnessLevel, weeks);
    }
  }

  /// 生成今日训练建议
  Future<String> generateDailyAdvice({
    String? fitnessLevel,
    String? weatherContext,
  }) async {
    final systemPrompt = '你是一个户外训练教练，根据用户的体能水平和天气情况，给出今日训练建议。回答简洁实用，100字以内。';

    final userPrompt = '''${fitnessLevel != null ? '体能水平：$fitnessLevel' : ''}
${weatherContext != null ? '今日天气：$weatherContext' : ''}

请给出今日训练建议。''';

    try {
      final response = await _claudeAPI.sendMessage(
        systemPrompt: systemPrompt,
        conversationHistory: const [],
        userMessage: userPrompt,
        maxTokens: 512,
        enableCaching: false,
      );

      return response.textContent;
    } on Exception catch (_) {
      return '今日建议：保持适度运动，注意身体状况。如需详细训练计划，可以告诉我你的目标和体能水平。';
    }
  }

  TrainingPlan? _parseTrainingPlan(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(response);
      if (jsonMatch == null) return null;

      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final scheduleData = data['schedule'] as List?;
      if (scheduleData == null) return null;

      final schedule = scheduleData.map((dayJson) {
        final d = dayJson as Map<String, dynamic>;
        return TrainingDay(
          weekNumber: (d['weekNumber'] as num?)?.toInt() ?? 1,
          dayNumber: (d['dayNumber'] as num?)?.toInt() ?? 1,
          type: _parseTrainingType(d['type'] as String?),
          title: d['title'] as String? ?? '训练',
          description: d['description'] as String? ?? '',
          durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 30,
          targetElevation: (d['targetElevation'] as num?)?.toInt(),
          targetDistance: (d['targetDistance'] as num?)?.toDouble(),
          isRestDay: d['isRestDay'] as bool? ?? false,
        );
      }).toList();

      return TrainingPlan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        name: data['name'] as String? ?? '训练计划',
        description: data['description'] as String? ?? '',
        level: _parseTrainingLevel(data['level'] as String?),
        durationWeeks: (data['durationWeeks'] as num?)?.toInt() ?? 4,
        schedule: schedule,
        goalRoute: data['goalRoute'] as String?,
        createdAt: DateTime.now(),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  TrainingType _parseTrainingType(String? value) {
    return switch (value) {
      'cardio' => TrainingType.cardio,
      'strength' => TrainingType.strength,
      'flexibility' => TrainingType.flexibility,
      'hiking' => TrainingType.hiking,
      'rest' => TrainingType.rest,
      _ => TrainingType.cardio,
    };
  }

  TrainingLevel _parseTrainingLevel(String? value) {
    return switch (value) {
      'beginner' => TrainingLevel.beginner,
      'intermediate' => TrainingLevel.intermediate,
      'advanced' => TrainingLevel.advanced,
      _ => TrainingLevel.beginner,
    };
  }

  /// 默认训练计划（API 失败时使用）
  TrainingPlan _getDefaultPlan(String? fitnessLevel, int weeks) {
    final level = _fitnessToLevel(fitnessLevel);
    final schedule = <TrainingDay>[];

    for (int w = 1; w <= weeks; w++) {
      for (int d = 1; d <= 7; d++) {
        if (d == 7) {
          schedule.add(TrainingDay(
            weekNumber: w,
            dayNumber: d,
            type: TrainingType.rest,
            title: '休息日',
            description: '充分休息，进行轻度拉伸或泡沫轴放松。保证充足睡眠。',
            durationMinutes: 15,
            isRestDay: true,
          ));
        } else if (d == 1 || d == 4) {
          schedule.add(TrainingDay(
            weekNumber: w,
            dayNumber: d,
            type: TrainingType.cardio,
            title: '有氧耐力训练',
            description: '快走或慢跑${level == TrainingLevel.beginner ? 20 + w * 2 : 30 + w * 3}分钟，保持能正常说话的速度。',
            durationMinutes: level == TrainingLevel.beginner ? 20 + w * 2 : 30 + w * 3,
          ));
        } else if (d == 2 || d == 5) {
          schedule.add(TrainingDay(
            weekNumber: w,
            dayNumber: d,
            type: TrainingType.strength,
            title: '力量训练',
            description: '深蹲3组x12次、弓步蹲3组x10次、平板支撑3组x30秒、小腿提踵3组x15次。组间休息60秒。',
            durationMinutes: 35,
          ));
        } else if (d == 3) {
          schedule.add(TrainingDay(
            weekNumber: w,
            dayNumber: d,
            type: TrainingType.hiking,
            title: '徒步模拟',
            description: '爬楼梯或爬坡训练${15 + w * 2}分钟，如条件允许可负重2-3kg。',
            durationMinutes: 30 + w * 2,
            targetElevation: 50 * w,
          ));
        } else if (d == 6) {
          schedule.add(TrainingDay(
            weekNumber: w,
            dayNumber: d,
            type: TrainingType.flexibility,
            title: '柔韧性训练',
            description: '全身拉伸20分钟，重点放松腿部肌肉。可进行简单瑜伽动作。',
            durationMinutes: 20,
          ));
        }
      }
    }

    return TrainingPlan(
      id: 'default_plan_${DateTime.now().millisecondsSinceEpoch}',
      name: '${level == TrainingLevel.beginner ? '新手' : '进阶'}爬山训练计划',
      description: '为期$weeks周的基础训练计划，包含有氧、力量、柔韧性和徒步模拟。',
      level: level,
      durationWeeks: weeks,
      schedule: schedule,
      createdAt: DateTime.now(),
    );
  }

  TrainingLevel _fitnessToLevel(String? fitness) {
    final f = fitness?.toLowerCase() ?? '';
    if (f.contains('新手') || f.contains('初级')) return TrainingLevel.beginner;
    if (f.contains('中级') || f.contains('经常')) return TrainingLevel.intermediate;
    if (f.contains('高级') || f.contains('专业')) return TrainingLevel.advanced;
    return TrainingLevel.beginner;
  }
}
