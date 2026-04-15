import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';

// Datasource provider
final routeLocalDatasourceProvider = Provider<RouteLocalDatasource>((ref) {
  return RouteLocalDatasource();
});

// UseCase provider
final routeRecommendationUseCaseProvider =
    Provider<RouteRecommendationUseCase>((ref) {
  return RouteRecommendationUseCase(ref.watch(routeLocalDatasourceProvider));
});

// 推荐路线列表
final recommendedRoutesProvider =
    FutureProvider.family<List<RouteRecommendation>, RoutePreferences>(
  (ref, preferences) async {
    final useCase = ref.watch(routeRecommendationUseCaseProvider);
    return useCase.getRecommendations(preferences: preferences);
  },
);

// 根据地点搜索路线
final searchRoutesProvider =
    FutureProvider.family<List<RouteRecommendation>, String>(
  (ref, location) async {
    final useCase = ref.watch(routeRecommendationUseCaseProvider);
    return useCase.searchByLocation(location);
  },
);
