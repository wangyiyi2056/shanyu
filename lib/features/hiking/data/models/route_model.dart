/// 爬山路线数据模型
class HikingRoute {
  final String id;
  final String name;
  final String location;
  final String description;
  final double distance; // km
  final double elevationGain; // m
  final double maxElevation; // m
  final int estimatedDuration; // 分钟
  final String difficulty; // easy, moderate, hard, expert
  final String surfaceType; // paved, dirt, mixed, rocky
  final List<String> tags;
  final List<Waypoint> waypoints;
  final List<String> warnings;
  final List<String> bestSeasons;
  final double rating;
  final int reviewCount;
  final String imageUrl;

  const HikingRoute({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.distance,
    required this.elevationGain,
    required this.maxElevation,
    required this.estimatedDuration,
    required this.difficulty,
    required this.surfaceType,
    this.tags = const [],
    this.waypoints = const [],
    this.warnings = const [],
    this.bestSeasons = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl = '',
  });

  /// 难度等级（1-5）
  int get difficultyLevel {
    return switch (difficulty) {
      'easy' => 1,
      'moderate' => 2,
      'hard' => 3,
      'expert' => 4,
      _ => 2,
    };
  }

  /// 体能消耗（1-5）
  int get exertionLevel {
    if (distance < 3 && elevationGain < 300) return 1;
    if (distance < 5 && elevationGain < 500) return 2;
    if (distance < 8 && elevationGain < 800) return 3;
    if (distance < 12 && elevationGain < 1200) return 4;
    return 5;
  }

  /// 获取难度描述
  String get difficultyLabel {
    return switch (difficulty) {
      'easy' => '简单',
      'moderate' => '中等',
      'hard' => '较难',
      'expert' => '专家',
      _ => '中等',
    };
  }

  /// 获取难度颜色
  String get difficultyColor {
    return switch (difficulty) {
      'easy' => '#4CAF50',
      'moderate' => '#FFC107',
      'hard' => '#FF9800',
      'expert' => '#F44336',
      _ => '#FFC107',
    };
  }
}

/// 路线上的关键点
class Waypoint {
  final String id;
  final String name;
  final String type; // start, viewpoint, rest_area, danger, landmark, end
  final double latitude;
  final double longitude;
  final double elevation;
  final String? description;

  const Waypoint({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    this.description,
  });
}
