import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

/// Route repository interface for domain layer
abstract interface class RouteRepository {
  /// Get all hiking routes
  Future<List<HikingRoute>> getAllRoutes();

  /// Get a specific route by ID
  Future<HikingRoute?> getRouteById(String id);

  /// Search routes by location name or keywords
  Future<List<HikingRoute>> searchRoutes(String query);

  /// Get routes filtered by difficulty level
  Future<List<HikingRoute>> getRoutesByDifficulty(String difficulty);

  /// Get route recommendations based on preferences
  Future<List<HikingRoute>> recommendRoutes({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  });

  /// Get route recommendations synchronously (for local data)
  List<HikingRoute> recommendRoutesSync({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  });
}