import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/auth/presentation/providers/auth_provider.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/review_local_datasource.dart';
import 'package:hiking_assistant/features/profile/data/datasources/profile_api_datasource.dart';

/// Route local datasource for getting route details
final routeLocalDatasourceProvider = Provider<RouteLocalDatasource>((ref) {
  return RouteLocalDatasource();
});

/// Review local datasource for favorites (unauthenticated users)
final reviewLocalDatasourceForFavoritesProvider =
    Provider<ReviewLocalDatasource>((ref) {
  return ReviewLocalDatasource();
});

/// Profile API datasource provider
final profileApiDatasourceProvider = Provider<ProfileApiDatasource>((ref) {
  return ProfileApiDatasource.instance;
});

/// Favorite route IDs from backend (when authenticated) or local storage
final favoriteIdsProvider = FutureProvider<List<String>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    // Fall back to local storage when not authenticated
    final localDatasource = ref.watch(reviewLocalDatasourceForFavoritesProvider);
    final favorites = await localDatasource.getAllFavorites();
    return favorites.map((f) => f.routeId).toList();
  }

  try {
    final api = ref.watch(profileApiDatasourceProvider);
    return await api.getFavorites();
  } catch (e) {
    // Fall back to local on API error
    final localDatasource = ref.watch(reviewLocalDatasourceForFavoritesProvider);
    final favorites = await localDatasource.getAllFavorites();
    return favorites.map((f) => f.routeId).toList();
  }
});

/// 收藏路线详情列表 Provider
final favoriteRoutesProvider = FutureProvider<List<HikingRoute>>((ref) async {
  final favoriteIds = await ref.watch(favoriteIdsProvider.future);
  if (favoriteIds.isEmpty) return [];

  final datasource = ref.watch(routeLocalDatasourceProvider);
  final routes = <HikingRoute>[];
  for (final routeId in favoriteIds) {
    final route = await datasource.getRouteById(routeId);
    if (route != null) {
      routes.add(route);
    }
  }
  return routes;
});

/// Toggle favorite - uses API when authenticated, local when not
final toggleFavoriteProvider =
    FutureProvider.family<bool, String>((ref, routeId) async {
  final authState = ref.watch(authProvider);

  if (authState is AuthAuthenticated) {
    // Use backend API
    final api = ref.watch(profileApiDatasourceProvider);
    final currentFavorites = await ref.read(favoriteIdsProvider.future);
    final isFavorite = currentFavorites.contains(routeId);

    if (isFavorite) {
      final success = await api.removeFavorite(routeId);
      if (success) {
        ref.invalidate(favoriteIdsProvider);
        ref.invalidate(favoriteRoutesProvider);
      }
      return !isFavorite;
    } else {
      final success = await api.addFavorite(routeId);
      if (success) {
        ref.invalidate(favoriteIdsProvider);
        ref.invalidate(favoriteRoutesProvider);
      }
      return !isFavorite;
    }
  } else {
    // Use local storage via ReviewLocalDatasource
    final localDatasource = ref.read(reviewLocalDatasourceForFavoritesProvider);
    final result = await localDatasource.toggleFavorite(routeId);
    ref.invalidate(favoriteIdsProvider);
    ref.invalidate(favoriteRoutesProvider);
    return result;
  }
});