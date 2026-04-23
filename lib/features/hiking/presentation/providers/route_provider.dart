import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_api_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/repositories/route_repository_impl.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';

// API datasource provider (connects to backend)
final routeApiDatasourceProvider = Provider<RouteApiDatasource>((ref) {
  return RouteApiDatasource.instance;
});

// Local datasource provider (fallback)
final routeLocalDatasourceProvider = Provider<RouteLocalDatasource>((ref) {
  return RouteLocalDatasource();
});

// Repository provider - coordinates API and local datasources
final routeRepositoryProvider = Provider<RouteRepositoryImpl>((ref) {
  final apiDatasource = ref.watch(routeApiDatasourceProvider);
  final localDatasource = ref.watch(routeLocalDatasourceProvider);
  return RouteRepositoryImpl(
    apiDatasource: apiDatasource,
    localDatasource: localDatasource,
  );
});

// UseCase provider - depends on repository
final routeRecommendationUseCaseProvider =
    Provider<RouteRecommendationUseCase>((ref) {
  final repository = ref.watch(routeRepositoryProvider);
  return RouteRecommendationUseCase(repository);
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
