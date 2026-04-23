import 'package:hiking_assistant/features/chat/data/datasources/conversation_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/repositories/route_repository.dart';
import 'package:hiking_assistant/shared/utils/geo_utils.dart';

/// 用户偏好
class RoutePreferences {
  final String? preferredDifficulty; // 新手/简单, 中级/一般, 难/挑战
  final int? maxDuration; // 分钟
  final double? maxDistance; // km
  final List<String>? requiredTags;
  final double? userLatitude;
  final double? userLongitude;
  final UserMemoryProfile? userProfile; // 用户画像，用于个性化推荐

  const RoutePreferences({
    this.preferredDifficulty,
    this.maxDuration,
    this.maxDistance,
    this.requiredTags,
    this.userLatitude,
    this.userLongitude,
    this.userProfile,
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
          userLongitude == other.userLongitude &&
          userProfile == other.userProfile;

  @override
  int get hashCode => Object.hash(
        preferredDifficulty,
        maxDuration,
        maxDistance,
        requiredTags,
        userLatitude,
        userLongitude,
        userProfile,
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

/// 路线推荐用例 - 依赖 domain 层的 RouteRepository 接口
class RouteRecommendationUseCase {
  final RouteRepository _repository;

  RouteRecommendationUseCase(this._repository);

  /// 根据用户偏好推荐路线
  Future<List<RouteRecommendation>> getRecommendations({
    required RoutePreferences preferences,
    int limit = 5,
  }) async {
    try {
      final routes = await _repository.recommendRoutes(
        preferredDifficulty: preferences.preferredDifficulty,
        maxDuration: preferences.maxDuration,
        maxDistance: preferences.maxDistance,
        requiredTags: preferences.requiredTags,
      );
      return _buildRecommendations(routes, preferences, limit);
    } catch (e) {
      return [];
    }
  }

  /// 同步推荐路线（用于本地数据直接加载）
  List<RouteRecommendation> getRecommendationsSync({
    required RoutePreferences preferences,
    int limit = 5,
  }) {
    final routes = _repository.recommendRoutesSync(
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
    // 合并用户画像到偏好（画像作为兜底/增强）
    final effectivePrefs = _mergeWithUserProfile(preferences);

    // 如果有用户位置，按距离排序
    List<HikingRoute> sortedRoutes = routes;
    final userLatitude = effectivePrefs.userLatitude;
    final userLongitude = effectivePrefs.userLongitude;
    if (userLatitude != null && userLongitude != null) {
      sortedRoutes = _sortByDistance(
        routes,
        userLatitude,
        userLongitude,
      );
    }

    // 个性化排序：按匹配分数重新排序
    final scored = sortedRoutes.map((route) {
      final score = _calculateMatchScore(route, effectivePrefs);
      final reasons = _generateMatchReasons(route, effectivePrefs);
      return RouteRecommendation(
        route: route,
        matchScore: score,
        matchReasons: reasons,
      );
    }).toList();

    scored.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // 限制返回数量
    return scored.take(limit).toList();
  }

  /// 将用户画像合并到偏好中（画像作为兜底）
  RoutePreferences _mergeWithUserProfile(RoutePreferences prefs) {
    final profile = prefs.userProfile;
    if (profile == null) return prefs;

    // 如果用户没有明确指定难度，使用画像中的偏好
    String? difficulty = prefs.preferredDifficulty;
    if (difficulty == null || difficulty.isEmpty) {
      difficulty = profile.preferredDifficulty;
    }

    // 如果用户没有明确指定时长，使用画像中的偏好
    int? maxDuration = prefs.maxDuration;
    if (maxDuration == null && profile.preferredDuration != null) {
      maxDuration = _parseDuration(profile.preferredDuration!);
    }

    // 如果用户没有明确指定距离，使用画像中的偏好
    double? maxDistance = prefs.maxDistance;
    if (maxDistance == null && profile.preferredDistance != null) {
      maxDistance = _parseDistance(profile.preferredDistance!);
    }

    return RoutePreferences(
      preferredDifficulty: difficulty,
      maxDuration: maxDuration,
      maxDistance: maxDistance,
      requiredTags: prefs.requiredTags,
      userLatitude: prefs.userLatitude,
      userLongitude: prefs.userLongitude,
      userProfile: profile,
    );
  }

  int? _parseDuration(String duration) {
    final d = duration.toLowerCase();
    if (d.contains('短时间') || d.contains('小时')) return 60;
    if (d.contains('半天')) return 240;
    if (d.contains('全天')) return 480;
    return null;
  }

  double? _parseDistance(String distance) {
    final d = distance.toLowerCase();
    if (d.contains('短途')) return 3.0;
    if (d.contains('中程')) return 8.0;
    if (d.contains('长途')) return 15.0;
    return null;
  }

  /// 根据地点搜索路线
  Future<List<RouteRecommendation>> searchByLocation(String location) async {
    final routes = await _repository.searchRoutes(location);

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
      final dist = GeoUtils.haversineDistance(
        userLat,
        userLng,
        wp.latitude,
        wp.longitude,
      ) / 1000; // Convert to km
      if (dist < minDist) minDist = dist;
    }
    return minDist;
  }

  /// 计算匹配分数（考虑用户画像）
  double _calculateMatchScore(HikingRoute route, RoutePreferences prefs) {
    double score = 0.5; // 基础分
    final profile = prefs.userProfile;

    // 难度匹配
    final preferredDifficulty = prefs.preferredDifficulty;
    if (preferredDifficulty != null) {
      final matchDiff = _matchDifficulty(route.difficulty, preferredDifficulty);
      score += matchDiff ? 0.3 : -0.1;
    }

    // 时间匹配
    final maxDuration = prefs.maxDuration;
    if (maxDuration != null && route.estimatedDuration <= maxDuration) {
      score += 0.2;
    }

    // 距离匹配
    final maxDistance = prefs.maxDistance;
    if (maxDistance != null && route.distance <= maxDistance) {
      score += 0.1;
    }

    // 用户画像增强：喜欢的路线加分
    if (profile != null && profile.favoriteRoutes.isNotEmpty) {
      for (final favorite in profile.favoriteRoutes) {
        if (route.name.contains(favorite) || favorite.contains(route.name)) {
          score += 0.15;
          break;
        }
      }
    }

    // 用户画像增强：不喜欢的路线减分
    if (profile != null && profile.dislikedRoutes.isNotEmpty) {
      for (final disliked in profile.dislikedRoutes) {
        if (route.name.contains(disliked) || disliked.contains(route.name)) {
          score -= 0.2;
          break;
        }
      }
    }

    // 体能水平匹配
    if (profile?.fitnessLevel != null) {
      final fitness = profile!.fitnessLevel!.toLowerCase();
      final isEasyRoute = route.difficulty == 'easy';
      final isHardRoute = route.difficulty == 'hard' || route.difficulty == 'expert';

      if (fitness.contains('新手') || fitness.contains('初级')) {
        if (isEasyRoute) score += 0.1;
        if (isHardRoute) score -= 0.15;
      } else if (fitness.contains('高级') || fitness.contains('专业')) {
        if (isHardRoute) score += 0.1;
        if (isEasyRoute) score -= 0.05;
      }
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

  /// 生成推荐理由（包含个性化理由）
  List<String> _generateMatchReasons(
      HikingRoute route, RoutePreferences prefs) {
    final reasons = <String>[];
    final profile = prefs.userProfile;

    // 画像驱动的推荐理由
    if (profile != null) {
      // 喜欢的路线
      for (final favorite in profile.favoriteRoutes) {
        if (route.name.contains(favorite) || favorite.contains(route.name)) {
          reasons.add('您曾喜欢过类似路线');
          break;
        }
      }

      // 体能匹配
      final fitness = profile.fitnessLevel;
      if (fitness != null) {
        final isEasy = route.difficulty == 'easy';
        final isHard = route.difficulty == 'hard' || route.difficulty == 'expert';
        if ((fitness.contains('新手') || fitness.contains('初级')) && isEasy) {
          reasons.add('难度适合您的体能水平($fitness)');
        } else if ((fitness.contains('高级') || fitness.contains('专业')) && isHard) {
          reasons.add('难度适合您的体能水平($fitness)');
        }
      }
    }

    final preferredDifficulty = prefs.preferredDifficulty;
    if (preferredDifficulty != null) {
      final matchDiff = _matchDifficulty(route.difficulty, preferredDifficulty);
      if (matchDiff) {
        reasons.add('难度「${route.difficultyLabel}」符合要求');
      }
    }

    final maxDuration = prefs.maxDuration;
    if (maxDuration != null && route.estimatedDuration <= maxDuration) {
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