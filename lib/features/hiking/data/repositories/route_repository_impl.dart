import 'package:hiking_assistant/features/hiking/data/datasources/route_api_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/repositories/route_repository.dart';

/// Route repository implementation that coordinates API and local datasources
class RouteRepositoryImpl implements RouteRepository {
  final RouteApiDatasource _apiDatasource;
  final RouteLocalDatasource _localDatasource;

  const RouteRepositoryImpl({
    required RouteApiDatasource apiDatasource,
    required RouteLocalDatasource localDatasource,
  })  : _apiDatasource = apiDatasource,
        _localDatasource = localDatasource;

  @override
  Future<List<HikingRoute>> getAllRoutes() async {
    try {
      final routes = await _apiDatasource.getAllRoutes();
      if (routes.isNotEmpty) return routes;
    } catch (_) {
      // Fall through to local
    }
    return _localDatasource.getAllRoutes();
  }

  @override
  Future<HikingRoute?> getRouteById(String id) async {
    try {
      final route = await _apiDatasource.getRouteById(id);
      if (route != null) return route;
    } catch (_) {
      // Fall through to local
    }
    return _localDatasource.getRouteById(id);
  }

  @override
  Future<List<HikingRoute>> searchRoutes(String query) async {
    try {
      final routes = await _apiDatasource.searchRoutes(query);
      if (routes.isNotEmpty) return routes;
    } catch (_) {
      // Fall through to local
    }
    return _localDatasource.searchRoutes(query);
  }

  @override
  Future<List<HikingRoute>> getRoutesByDifficulty(String difficulty) async {
    try {
      final routes = await _apiDatasource.getRoutesByDifficulty(difficulty);
      if (routes.isNotEmpty) return routes;
    } catch (_) {
      // Fall through to local
    }
    return _localDatasource.getRoutesByDifficulty(difficulty);
  }

  @override
  Future<List<HikingRoute>> recommendRoutes({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  }) async {
    try {
      final routes = await _apiDatasource.recommendRoutes(
        preferredDifficulty: preferredDifficulty,
        maxDuration: maxDuration,
        maxDistance: maxDistance,
        requiredTags: requiredTags,
      );
      if (routes.isNotEmpty) return routes;
    } catch (_) {
      // Fall through to local
    }
    return _localDatasource.recommendRoutes(
      preferredDifficulty: preferredDifficulty,
      maxDuration: maxDuration,
      maxDistance: maxDistance,
      requiredTags: requiredTags,
    );
  }

  @override
  List<HikingRoute> recommendRoutesSync({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  }) {
    return _localDatasource.recommendRoutesSync(
      preferredDifficulty: preferredDifficulty,
      maxDuration: maxDuration,
      maxDistance: maxDistance,
      requiredTags: requiredTags,
    );
  }
}