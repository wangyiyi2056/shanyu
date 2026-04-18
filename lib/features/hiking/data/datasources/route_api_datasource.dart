import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';
import 'package:hiking_assistant/shared/services/api_client.dart';

/// Remote route data source (connects to backend)
class RouteApiDatasource {
  RouteApiDatasource._();

  static RouteApiDatasource get instance => RouteApiDatasource._();

  final ApiClient _client = ApiClient.instance;

  /// Get all routes with optional filters
  Future<List<HikingRoute>> getAllRoutes({
    String? query,
    String? difficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      if (query != null) 'query': query,
      if (difficulty != null) 'difficulty': difficulty,
      if (maxDuration != null) 'max_duration': maxDuration.toString(),
      if (maxDistance != null) 'max_distance': maxDistance.toString(),
      if (tags != null) 'tags': tags.join(','),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final response = await _client.get('/routes', query: queryParams);

    if (response.isSuccess && response.listData != null) {
      return response.listData!
          .cast<Map<String, dynamic>>()
          .map(_parseRoute)
          .toList();
    }

    // Fallback to empty list on error
    return [];
  }

  /// Get route by ID
  Future<HikingRoute?> getRouteById(String id) async {
    final response = await _client.get('/routes/$id');

    if (response.isSuccess && response.data != null) {
      return _parseRoute(response.data!);
    }
    return null;
  }

  /// Search routes by query
  Future<List<HikingRoute>> searchRoutes(String query) async {
    return getAllRoutes(query: query);
  }

  /// Get routes by difficulty
  Future<List<HikingRoute>> getRoutesByDifficulty(String difficulty) async {
    return getAllRoutes(difficulty: difficulty);
  }

  /// Recommend routes based on preferences
  Future<List<HikingRoute>> recommendRoutes({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  }) async {
    return getAllRoutes(
      difficulty: preferredDifficulty,
      maxDuration: maxDuration,
      maxDistance: maxDistance,
      tags: requiredTags,
    );
  }

  /// Create a new route (requires auth)
  Future<HikingRoute?> createRoute(HikingRoute route) async {
    final response = await _client.post(
      '/routes',
      body: _routeToJson(route),
    );

    if (response.isSuccess && response.data != null) {
      return _parseRoute(response.data!);
    }
    return null;
  }

  /// Get reviews for a route
  Future<List<RouteReview>> getReviews(String routeId) async {
    final response = await _client.get('/routes/$routeId/reviews');

    if (response.isSuccess && response.listData != null) {
      return response.listData!
          .cast<Map<String, dynamic>>()
          .map(_parseReview)
          .toList();
    }
    return [];
  }

  /// Create a review (requires auth)
  Future<RouteReview?> createReview(
    String routeId,
    int rating,
    String? content,
  ) async {
    final response = await _client.post(
      '/routes/$routeId/reviews',
      body: {'rating': rating, 'content': content},
    );

    if (response.isSuccess && response.data != null) {
      return _parseReview(response.data!);
    }
    return null;
  }

  HikingRoute _parseRoute(Map<String, dynamic> data) {
    return HikingRoute(
      id: data['id'] as String,
      name: data['name'] as String,
      location: data['location'] as String,
      description: data['description'] as String? ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      elevationGain: (data['elevation_gain'] as num?)?.toDouble() ?? 0.0,
      maxElevation: (data['max_elevation'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: data['estimated_duration'] as int? ?? 0,
      difficulty: data['difficulty'] as String? ?? 'moderate',
      surfaceType: data['surface_type'] as String? ?? 'mixed',
      tags: (data['tags'] as List?)?.cast<String>().toList() ?? [],
      waypoints: (data['waypoints'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((w) => Waypoint(
                id: w['id'] as String,
                name: w['name'] as String,
                type: w['type'] as String,
                latitude: (w['latitude'] as num).toDouble(),
                longitude: (w['longitude'] as num).toDouble(),
                elevation: (w['elevation'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList() ?? [],
      warnings: (data['warnings'] as List?)?.cast<String>().toList() ?? [],
      bestSeasons: (data['best_seasons'] as List?)?.cast<String>().toList() ?? [],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      imageUrl: data['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> _routeToJson(HikingRoute route) {
    return {
      'name': route.name,
      'location': route.location,
      'description': route.description,
      'distance': route.distance,
      'elevation_gain': route.elevationGain,
      'max_elevation': route.maxElevation,
      'estimated_duration': route.estimatedDuration,
      'difficulty': route.difficulty,
      'surface_type': route.surfaceType,
      'tags': route.tags,
      'waypoints': route.waypoints
          .map((w) => {
                'id': w.id,
                'name': w.name,
                'type': w.type,
                'latitude': w.latitude,
                'longitude': w.longitude,
                'elevation': w.elevation,
              })
          .toList(),
      'warnings': route.warnings,
      'best_seasons': route.bestSeasons,
      'image_url': route.imageUrl,
    };
  }

  RouteReview _parseReview(Map<String, dynamic> data) {
    return RouteReview(
      id: data['id'] as String,
      routeId: data['route_id'] as String,
      rating: (data['rating'] as num).toDouble(),
      comment: data['content'] as String? ?? '',
      authorName: '用户', // API doesn't return user name
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}