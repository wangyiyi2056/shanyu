import 'package:hiking_assistant/features/chat/domain/entities/intent.dart';

/// 本地意图识别规则
class LocalIntentRules {
  LocalIntentRules._();

  static final List<IntentRule> _rules = [
    // 紧急求助（最高优先级）
    IntentRule(
      patterns: [
        RegExp(r'救命|紧急|求助|受伤|危险|迷路|报警'),
        RegExp(r'我迷路了'),
        RegExp(r'摔倒了'),
      ],
      category: IntentCategory.emergency,
      quickResponse:
          '【安全第一】我已记录您的位置信息。如果您需要紧急救援，请立即拨打 120 或当地紧急电话。请问您现在具体在哪里？有什么可以帮您的？',
      priority: 100,
    ),

    // 天气查询
    IntentRule(
      patterns: [
        RegExp(r'天气|气温|温度|下雨|下雪|刮风'),
        RegExp(r'能不能去|适合去|要不要带伞'),
      ],
      category: IntentCategory.weatherQuery,
      priority: 50,
    ),

    // 路线搜索
    IntentRule(
      patterns: [
        RegExp(r'附近|周围|最近|旁边'),
        RegExp(r'什么山|哪座山|哪个山|哪里可以爬'),
        RegExp(r'爬山|徒步|登山|郊游'),
      ],
      category: IntentCategory.routeSearch,
      priority: 40,
    ),

    // 路线推荐
    IntentRule(
      patterns: [
        RegExp(r'推荐|建议'),
        RegExp(r'适合.*新?手|新手.*适合'),
        RegExp(r'简单.*路线|容易.*路线'),
      ],
      category: IntentCategory.routeRecommendation,
      priority: 35,
    ),

    // 开始导航/记录
    IntentRule(
      patterns: [
        RegExp(r'^导航|带我去|开始.*导航'),
        RegExp(r'^记录|开始.*轨迹|出发'),
        RegExp(r'开始爬'),
      ],
      category: IntentCategory.navigation,
      priority: 30,
    ),

    // 植物识别
    IntentRule(
      patterns: [
        RegExp(r'这是什么|识别|这是什么植物|这是什么树|这是什么花'),
      ],
      category: IntentCategory.plantIdentification,
      priority: 25,
    ),

    // 问候
    IntentRule(
      patterns: [
        RegExp(r'^你好|^您好|^嗨|^嘿|^早上好|^下午好|^晚上好'),
      ],
      category: IntentCategory.greeting,
      quickResponse:
          '你好！我是爬山助手 🌲 有什么可以帮你的吗？你可以问我：\n• 附近有什么路线\n• 查天气预报\n• 推荐适合的爬山路线\n• 开始记录轨迹',
      priority: 10,
    ),

    // 告别
    IntentRule(
      patterns: [
        RegExp(r'^再见|^拜拜|^走了|^出发了'),
      ],
      category: IntentCategory.farewell,
      quickResponse: '路上注意安全，祝你爬山愉快！⛰️ 有问题随时叫我。',
      priority: 10,
    ),

    // 帮助
    IntentRule(
      patterns: [
        RegExp(r'帮助|你能做什么|怎么用|有什么功能'),
      ],
      category: IntentCategory.help,
      quickResponse: '''我可以帮你：

🏔️ **路线推荐** - 根据你的位置和偏好推荐合适的路线
🌤️ **天气查询** - 查询目的地和途中的天气
📍 **导航指引** - 帮你导航到目的地
📊 **轨迹记录** - 记录你的爬山轨迹
🌱 **植物识别** - 拍照识别山区植物
⚠️ **安全提醒** - 及时提醒天气变化和危险路段

有什么想问的，直接说就好！''',
      priority: 5,
    ),
  ];

  static Intent? match(String input) {
    final trimmedInput = input.trim().toLowerCase();

    for (final rule in _rules) {
      for (final pattern in rule.patterns) {
        if (pattern.hasMatch(trimmedInput)) {
          return Intent(
            category: rule.category,
            confidence: 1.0,
            entities: _extractLocationEntities(input),
            parameters: const {},
            quickResponse: rule.quickResponse,
          );
        }
      }
    }

    // 如果没有匹配，也尝试提取地名
    final entities = _extractLocationEntities(input);
    if (entities.containsKey('location')) {
      // 有地名但没有匹配到意图，默认是路线搜索
      return Intent(
        category: IntentCategory.routeSearch,
        confidence: 0.5,
        entities: entities,
        parameters: const {},
      );
    }

    return null;
  }

  /// 提取地名实体
  static Map<String, dynamic> _extractLocationEntities(String input) {
    final entities = <String, dynamic>{};
    final locationPatterns = [
      // 明确的地名 + 山/公园 组合
      RegExp(r'(香山|百望山|凤凰岭|妙峰山|雾灵山|泰山|华山|黄山|峨眉山|长城)'),
      // 省市 + 山/公园
      RegExp(r'(北京|上海|成都|西安|杭州|广州|深圳)(附近|周围|周边)?.*(山|公园|景区)'),
      // 地名直接提问
      RegExp(r'(去|到|来)(香山|百望山|凤凰岭|妙峰山|雾灵山|泰山|华山|黄山|峨眉山|长城)'),
      // 地名在句子中
      RegExp(r'(香山|百望山|凤凰岭|妙峰山|雾灵山|泰山|华山|黄山|峨眉山|长城)的天气'),
      RegExp(r'(香山|百望山|凤凰岭|妙峰山|雾灵山|泰山|华山|黄山|峨眉山|长城)路线'),
      RegExp(r'(香山|百望山|凤凰岭|妙峰山|雾灵山|泰山|华山|黄山|峨眉山|长城)导航'),
    ];

    for (final pattern in locationPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        // 提取匹配的地名
        for (var i = 1; i <= match.groupCount; i++) {
          final group = match.group(i);
          if (group != null && group.isNotEmpty) {
            // 过滤掉常见的连接词
            if (!['附近', '周围', '周边'].contains(group)) {
              entities['location'] = group;
              break;
            }
          }
        }
        if (entities.containsKey('location')) break;
      }
    }

    return entities;
  }
}

class IntentRule {
  final List<RegExp> patterns;
  final IntentCategory category;
  final String? quickResponse;
  final int priority;

  IntentRule({
    required this.patterns,
    required this.category,
    this.quickResponse,
    required this.priority,
  });
}

/// 意图识别服务
class IntentService {
  IntentService();

  /// 识别意图
  Intent detectIntent(String content) {
    // 先尝试本地规则匹配
    final localIntent = LocalIntentRules.match(content);
    if (localIntent != null) {
      return localIntent;
    }

    // 返回未知意图
    return Intent(
      category: IntentCategory.unknown,
      confidence: 0.0,
      entities: const {},
      parameters: const {},
    );
  }
}
