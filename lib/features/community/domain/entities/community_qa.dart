/// 社区问答条目
class CommunityQa {
  final String id;
  final String question;
  final String answer;
  final String category; // e.g., '装备', '路线', '安全', '体能'
  final int helpfulCount;
  final String? source; // 来源，如 '资深驴友@张三'
  final DateTime createdAt;

  const CommunityQa({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.helpfulCount = 0,
    this.source,
    required this.createdAt,
  });
}

/// 社区问答搜索结果
class CommunityQaResult {
  final CommunityQa qa;
  final double relevanceScore;

  const CommunityQaResult({
    required this.qa,
    required this.relevanceScore,
  });
}
