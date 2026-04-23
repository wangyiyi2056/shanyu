import 'package:hiking_assistant/features/chat/data/services/claude_api_service.dart';
import 'package:hiking_assistant/features/community/domain/entities/community_qa.dart';

/// 社区问答服务
///
/// 维护一个本地社区知识库，结合 Claude API 为用户问题提供社区化的智能回答。
class CommunityQaService {
  final ClaudeAPIService _claudeAPI;

  CommunityQaService({required ClaudeAPIService claudeAPI})
      : _claudeAPI = claudeAPI;

  // 本地社区知识库（可后续替换为后端 API）
  final List<CommunityQa> _knowledgeBase = [
    CommunityQa(
      id: 'qa_001',
      question: '新手第一次爬山需要准备什么装备？',
      answer:
          '新手建议准备：1) 防滑登山鞋（最重要）；2) 双肩背包（20-30L）；3) 速干衣裤；4) 登山杖；5) 足够的水（每人至少1.5L）；6) 简易急救包；7) 高热量零食。不需要一开始就购买昂贵装备，基础款即可。',
      category: '装备',
      helpfulCount: 156,
      source: '资深领队@山野行者',
      createdAt: DateTime(2024, 3, 15),
    ),
    CommunityQa(
      id: 'qa_002',
      question: '香山哪个季节最美？',
      answer:
          '香山最美的季节是秋季（10月下旬-11月中旬），红叶节期间满山红叶非常壮观。但这也是人最多的时段，建议工作日前往或选择清晨。春季（4月）桃花盛开也很美，且人少。',
      category: '路线',
      helpfulCount: 203,
      source: '北京土著@胡同里长大',
      createdAt: DateTime(2024, 5, 20),
    ),
    CommunityQa(
      id: 'qa_003',
      question: '爬山时膝盖疼怎么办？',
      answer:
          '膝盖疼的处理方法：1) 立即停下来休息，不要强撑；2) 使用登山杖分担膝盖压力（调节到合适高度）；3) 检查鞋子是否合适，鞋底磨损严重会加剧膝盖负担；4) 下山路尽量走Z字形，减少直线下冲；5) 平时加强股四头肌锻炼。如果持续疼痛，建议就医检查。',
      category: '安全',
      helpfulCount: 89,
      source: '运动康复师@骨科老李',
      createdAt: DateTime(2024, 6, 10),
    ),
    CommunityQa(
      id: 'qa_004',
      question: '一个人爬山安全吗？',
      answer:
          '一个人爬山有一定风险，不建议新手独自出行。如果一定要 solo：1) 选择成熟、人多的路线；2) 提前告知家人朋友你的计划和预计返回时间；3) 携带充电宝，保持手机有电；4) 下载离线地图；5) 带够水和食物；6) 关注天气，遇恶劣天气立即下撤。',
      category: '安全',
      helpfulCount: 178,
      source: '救援队志愿者@蓝天救援',
      createdAt: DateTime(2024, 2, 28),
    ),
    CommunityQa(
      id: 'qa_005',
      question: '爬山的节奏应该怎么控制？',
      answer:
          '正确的爬山节奏：1) 起步慢热，前15分钟不要快，让身体逐步适应；2) 保持能正常说话的速度（"说话测试"）；3) 心跳控制在最大心率的60-70%（估算公式：220-年龄）；4) 每爬升100-150米休息2-3分钟；5) 下山比上山更伤膝盖，一定要慢，重心放低。',
      category: '体能',
      helpfulCount: 134,
      source: '户外教练@山野训练营',
      createdAt: DateTime(2024, 4, 5),
    ),
    CommunityQa(
      id: 'qa_006',
      question: '遇到雷雨天气在山上怎么办？',
      answer:
          '山上遇雷雨紧急处理：1) 立即停止攀爬，远离山顶、山脊、孤树、水边；2) 寻找低洼处蹲下，双脚并拢（减少跨步电压）；3) 远离金属物品（登山杖、背包金属架）；4) 不要在洞穴入口停留（闪电可能跳过山体进入）；5) 等雷雨过去30分钟后再继续。预防为主，出发前务必看天气预报。',
      category: '安全',
      helpfulCount: 245,
      source: '气象工作者@云卷云舒',
      createdAt: DateTime(2024, 7, 12),
    ),
    CommunityQa(
      id: 'qa_007',
      question: '爬山带多少水合适？',
      answer:
          '一般建议每人每小时携带300-500ml水。夏季或高强度路线需要更多（500-800ml/小时）。不要等口渴了再喝，建议每15-20分钟小口补充。可以带电解质饮料补充盐分。留有20%余量以防万一。',
      category: '装备',
      helpfulCount: 112,
      source: ' hydration geek@水壶专家',
      createdAt: DateTime(2024, 5, 8),
    ),
    CommunityQa(
      id: 'qa_008',
      question: '北京周边适合新手的山有哪些？',
      answer:
          '北京新手友好山峰推荐：1) 香山 - 路线成熟，有缆车，交通方便；2) 百望山 - 难度低，视野好，约1.5小时；3) 凤凰岭北线 -  slightly challenging but well marked；4) 妙峰山 - 有古道，文化底蕴；5) 坡峰岭 - 人少景美，秋季红叶。建议从香山或百望山开始。',
      category: '路线',
      helpfulCount: 320,
      source: '北京登山协会@京郊通',
      createdAt: DateTime(2024, 1, 20),
    ),
    CommunityQa(
      id: 'qa_009',
      question: '登山杖怎么选？',
      answer:
          '登山杖选购建议：1) 新手选外锁款，调节方便且可靠；2) 材质：铝合金结实便宜，碳纤维轻便贵但易断；3) 长度调节：站立时肘部90度弯曲，杖尖触地；4) 手柄：软木吸汗但贵，EVA泡沫舒适，橡胶耐用；5) 建议买一对，平衡发力。预算200-500元可以买到不错的入门款。',
      category: '装备',
      helpfulCount: 167,
      source: '装备测评@户外实验室',
      createdAt: DateTime(2024, 8, 3),
    ),
    CommunityQa(
      id: 'qa_010',
      question: '爬山前需要做哪些热身？',
      answer:
          '爬山前热身（10-15分钟）：1) 关节活动：脚踝绕环、膝关节屈伸、髋关节绕环；2) 动态拉伸：高抬腿、后踢腿、开合跳各30秒；3) 核心激活：原地踏步配合摆臂；4) 小腿拉伸：弓步压腿。热身强度以微微出汗为宜，不要静态拉伸（研究发现静态拉伸反而降低爆发力）。',
      category: '体能',
      helpfulCount: 98,
      source: '运动医学博士@跑山博士',
      createdAt: DateTime(2024, 9, 15),
    ),
  ];

  /// 搜索社区问答
  List<CommunityQaResult> search(String query, {int limit = 3}) {
    final lowerQuery = query.toLowerCase();
    final results = <CommunityQaResult>[];

    for (final qa in _knowledgeBase) {
      double score = 0;

      // 问题匹配
      if (qa.question.toLowerCase().contains(lowerQuery)) {
        score += 0.5;
      }

      // 答案匹配
      if (qa.answer.toLowerCase().contains(lowerQuery)) {
        score += 0.3;
      }

      // 分类匹配
      if (lowerQuery.contains(qa.category)) {
        score += 0.2;
      }

      // 关键词匹配
      final keywords = _extractKeywords(lowerQuery);
      for (final kw in keywords) {
        if (qa.question.toLowerCase().contains(kw)) score += 0.1;
        if (qa.answer.toLowerCase().contains(kw)) score += 0.05;
      }

      // 热门度加权
      if (qa.helpfulCount > 100) {
        score += 0.05;
      }

      if (score > 0) {
        results.add(CommunityQaResult(qa: qa, relevanceScore: score));
      }
    }

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(limit).toList();
  }

  /// 使用 Claude API 综合社区知识回答问题
  Future<String?> synthesizeAnswer(
    String userQuestion,
    List<CommunityQaResult> communityResults,
  ) async {
    if (communityResults.isEmpty) return null;

    final buffer = StringBuffer();
    buffer.writeln('用户问题：$userQuestion\n');
    buffer.writeln('以下是社区中的相关问答：\n');

    for (int i = 0; i < communityResults.length; i++) {
      final result = communityResults[i];
      final qa = result.qa;
      buffer.writeln('--- 参考 ${i + 1} ---');
      buffer.writeln('问题：${qa.question}');
      buffer.writeln('回答：${qa.answer}');
      buffer.writeln('分类：${qa.category}');
      if (qa.source != null) {
        buffer.writeln('来源：${qa.source}');
      }
      buffer.writeln('有用数：${qa.helpfulCount}');
      buffer.writeln();
    }

    final systemPrompt = '''你是一个专业的户外爬山社区助手。请基于以下社区问答资料，为用户的问题提供一个综合、准确的回答。

## 回答要求
1. 综合多个社区回答的精华，给出最实用的建议
2. 保持友好、口语化的社区风格
3. 如果社区资料有冲突，选择更权威或更新的说法
4. 在回答末尾标注参考了社区中哪些内容（简要提及）
5. 如果社区资料不足以回答，明确说明"社区资料中未找到相关信息"

## 格式
- 使用 Markdown 格式
- 关键信息加粗或使用列表
- 适当分段，保持可读性''';

    try {
      final response = await _claudeAPI.sendMessage(
        systemPrompt: systemPrompt,
        conversationHistory: const [],
        userMessage: buffer.toString(),
        maxTokens: 2048,
        enableCaching: false,
      );

      return response.textContent;
    } on Exception catch (_) {
      return null;
    }
  }

  List<String> _extractKeywords(String text) {
    // 简单提取2字及以上的词作为关键词
    final words = <String>[];
    final segments = text.split(RegExp(r'[\s,，.。？?！!；;]+'));
    for (final seg in segments) {
      if (seg.length >= 2) {
        words.add(seg);
      }
    }
    return words;
  }
}
