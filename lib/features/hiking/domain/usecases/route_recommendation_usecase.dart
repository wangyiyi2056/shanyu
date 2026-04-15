import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

/// 用户偏好
class RoutePreferences {
  final String? preferredDifficulty; // 新手/简单, 中级/一般, 难/挑战
  final int? maxDuration; // 分钟
  final double? maxDistance; // km
  final List<String>? requiredTags;
  final double? userLatitude;
  final double? userLongitude;

  const RoutePreferences({
    this.preferredDifficulty,
    this.maxDuration,
    this.maxDistance,
    this.requiredTags,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePreferences &&
          runtimeType == other.runtimeType &&
          preferredDifficulty == other.preferredDifficulty &&
          maxDuration == other.maxDuration &&
          maxDistance == other.maxDistance &&
          _listEquals(requiredTags, other.requiredTags) &&
          userLatitude == other.userLatitude &&
          userLongitude == other.userLongitude;

  @override
  int get hashCode => Object.hash(
        preferredDifficulty,
        maxDuration,
        maxDistance,
        requiredTags,
        userLatitude,
        userLongitude,
      );

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 路线推荐结果
class RouteRecommendation {
  final HikingRoute route;
  final double matchScore;
  final List<String> matchReasons;

  const RouteRecommendation({
    required this.route,
    required this.matchScore,
    required this.matchReasons,
  });
}

/// 路线推荐用例
class RouteRecommendationUseCase {
  final RouteLocalDatasource _datasource;

  RouteRecommendationUseCase(this._datasource);

  /// 根据用户偏好推荐路线
  Future<List<RouteRecommendation>> getRecommendations({
    required RoutePreferences preferences,
    int limit = 5,
  }) async {
    final routes = await _datasource.recommendRoutes(
      preferredDifficulty: preferences.preferredDifficulty,
      maxDuration: preferences.maxDuration,
      maxDistance: preferences.maxDistance,
      requiredTags: preferences.requiredTags,
    );
    return _buildRecommendations(routes, preferences, limit);
  }

  /// 同步推荐路线（用于本地数据直接加载）
  List<RouteRecommendation> getRecommendationsSync({
    required RoutePreferences preferences,
    int limit = 5,
  }) {
    final routes = _datasource.recommendRoutesSync(
      preferredDifficulty: preferences.preferredDifficulty,
      maxDuration: preferences.maxDuration,
      maxDistance: preferences.maxDistance,
      requiredTags: preferences.requiredTags,
    );
    return _buildRecommendations(routes, preferences, limit);
  }

  List<RouteRecommendation> _buildRecommendations(
    List<HikingRoute> routes,
    RoutePreferences preferences,
    int limit,
  ) {
    // 如果有用户位置，按距离排序
    List<HikingRoute> sortedRoutes = routes;
    if (preferences.userLatitude != null && preferences.userLongitude != null) {
      sortedRoutes = _sortByDistance(
        routes,
        preferences.userLatitude!,
        preferences.userLongitude!,
      );
    }

    // 限制返回数量
    sortedRoutes = sortedRoutes.take(limit).toList();

    // 生成推荐理由
    return sortedRoutes.map((route) {
      return RouteRecommendation(
        route: route,
        matchScore: _calculateMatchScore(route, preferences),
        matchReasons: _generateMatchReasons(route, preferences),
      );
    }).toList();
  }

  /// 根据地点搜索路线
  Future<List<RouteRecommendation>> searchByLocation(String location) async {
    final routes = await _datasource.searchRoutes(location);

    return routes.map((route) {
      return RouteRecommendation(
        route: route,
        matchScore: 1.0,
        matchReasons: ['名称或位置匹配: $location'],
      );
    }).toList();
  }

  /// 按距离排序
  List<HikingRoute> _sortByDistance(
    List<HikingRoute> routes,
    double userLat,
    double userLng,
  ) {
    final sorted = routes.toList();
    sorted.sort((a, b) {
      final distA = _calculateMinDistance(a.waypoints, userLat, userLng);
      final distB = _calculateMinDistance(b.waypoints, userLat, userLng);
      return distA.compareTo(distB);
    });
    return sorted;
  }

  /// 计算到路线的最小距离
  double _calculateMinDistance(
    List<Waypoint> waypoints,
    double userLat,
    double userLng,
  ) {
    if (waypoints.isEmpty) return double.infinity;

    double minDist = double.infinity;
    for (final wp in waypoints) {
      final dist = _haversineDistance(
        userLat,
        userLng,
        wp.latitude,
        wp.longitude,
      );
      if (dist < minDist) minDist = dist;
    }
    return minDist;
  }

  /// 计算两点间的球面距离（km）
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // 地球半径
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(lat1)) *
            _cos(_toRad(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) => _sinApprox(x);
  double _cos(double x) => _cosApprox(x);
  double _sqrt(double x) => _sqrtApprox(x);
  double _atan2(double y, double x) => _atan2Approx(y, x);

  // 近似计算
  double _sinApprox(double x) {
    x = x % (2 * 3.141592653589793);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  double _cosApprox(double x) {
    x = x % (2 * 3.141592653589793);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  double _sqrtApprox(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2Approx(double y, double x) {
    if (x > 0) return _atanApprox(y / x);
    if (x < 0 && y >= 0) return _atanApprox(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atanApprox(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atanApprox(double x) {
    if (x.abs() > 1) {
      return (3.141592653589793 / 2) - _atanApprox(1 / x);
    }
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }

  /// 计算匹配分数
  double _calculateMatchScore(HikingRoute route, RoutePreferences prefs) {
    double score = 0.5; // 基础分

    // 难度匹配
    if (prefs.preferredDifficulty != null) {
      final matchDiff =
          _matchDifficulty(route.difficulty, prefs.preferredDifficulty!);
      score += matchDiff ? 0.3 : -0.1;
    }

    // 时间匹配
    if (prefs.maxDuration != null &&
        route.estimatedDuration <= prefs.maxDuration!) {
      score += 0.2;
    }

    // 距离匹配
    if (prefs.maxDistance != null && route.distance <= prefs.maxDistance!) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  bool _matchDifficulty(String routeDiff, String preferred) {
    final p = preferred.toLowerCase();
    if (p.contains('新手') || p.contains('简单')) {
      return routeDiff == 'easy';
    }
    if (p.contains('中级') || p.contains('一般')) {
      return routeDiff == 'moderate';
    }
    if (p.contains('难') || p.contains('挑战')) {
      return routeDiff == 'hard' || routeDiff == 'expert';
    }
    return true;
  }

  /// 生成推荐理由
  List<String> _generateMatchReasons(
      HikingRoute route, RoutePreferences prefs) {
    final reasons = <String>[];

    if (prefs.preferredDifficulty != null) {
      final matchDiff =
          _matchDifficulty(route.difficulty, prefs.preferredDifficulty!);
      if (matchDiff) {
        reasons.add('难度「${route.difficultyLabel}」符合要求');
      }
    }

    if (prefs.maxDuration != null &&
        route.estimatedDuration <= prefs.maxDuration!) {
      reasons.add('预计时长${route.estimatedDuration}分钟，在您的时间范围内');
    }

    if (route.rating >= 4.5) {
      reasons.add('评分较高(${route.rating})');
    }

    if (route.warnings.isEmpty) {
      reasons.add('无特殊风险提示');
    } else {
      reasons.add('注意: ${route.warnings.join(", ")}');
    }

    return reasons;
  }
}
