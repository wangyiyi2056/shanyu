import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/review_provider.dart';

/// 收藏路线详情列表 Provider
final favoriteRoutesProvider = FutureProvider<List<HikingRoute>>((ref) async {
  final favoritesAsync = await ref.watch(allFavoritesProvider.future);
  if (favoritesAsync.isEmpty) return [];

  final datasource = RouteLocalDatasource();
  final routes = <HikingRoute>[];
  for (final favorite in favoritesAsync) {
    final route = await datasource.getRouteById(favorite.routeId);
    if (route != null) {
      routes.add(route);
    }
  }
  return routes;
});
