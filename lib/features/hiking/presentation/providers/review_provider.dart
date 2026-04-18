import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/auth/presentation/providers/auth_provider.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/review_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_api_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';
import 'package:hiking_assistant/features/hiking/domain/repositories/review_repository.dart';

/// 评价本地数据源 Provider
final reviewLocalDatasourceProvider = Provider<ReviewLocalDatasource>((ref) {
  return ReviewLocalDatasource();
});

/// 所有收藏 Provider (from local storage)
final allFavoritesProvider = FutureProvider<List<RouteFavorite>>((ref) async {
  final localDatasource = ref.watch(reviewLocalDatasourceProvider);
  return localDatasource.getAllFavorites();
});

/// Route API datasource for reviews
final routeApiDatasourceForReviewsProvider = Provider<RouteApiDatasource>((ref) {
  return RouteApiDatasource.instance;
});

/// 评价仓储 Provider (uses API when authenticated, local otherwise)
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final authState = ref.watch(authProvider);
  final apiDatasource = ref.watch(routeApiDatasourceForReviewsProvider);
  final localDatasource = ref.watch(reviewLocalDatasourceProvider);

  return ReviewRepositoryImpl(
    apiDatasource: apiDatasource,
    localDatasource: localDatasource,
    isAuthenticated: authState is AuthAuthenticated,
  );
});

/// 某路线的评价列表 (from API when authenticated, local otherwise)
final routeReviewsProvider =
    FutureProvider.family<List<RouteReview>, String>((ref, routeId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsForRoute(routeId);
});

/// 某路线的平均评分
final routeAverageRatingProvider =
    FutureProvider.family<double, String>((ref, routeId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getAverageRating(routeId);
});

/// 某路线的评价数量
final routeReviewCountProvider =
    FutureProvider.family<int, String>((ref, routeId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewCount(routeId);
});

/// 评价操作 Notifier
class ReviewActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repository;
  final Ref _ref;

  ReviewActionsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// 提交评价 (to API when authenticated, local otherwise)
  Future<void> submitReview({
    required String routeId,
    required double rating,
    required String comment,
    String authorName = '游客',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addReview(routeId, rating, comment, authorName);
      _ref.invalidate(routeReviewsProvider(routeId));
      _ref.invalidate(routeAverageRatingProvider(routeId));
      _ref.invalidate(routeReviewCountProvider(routeId));
    });
  }

  /// 删除评价
  Future<void> deleteReview(String reviewId, String routeId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteReview(reviewId);
      _ref.invalidate(routeReviewsProvider(routeId));
      _ref.invalidate(routeAverageRatingProvider(routeId));
      _ref.invalidate(routeReviewCountProvider(routeId));
    });
  }
}

/// 评价操作 Provider
final reviewActionsProvider =
    StateNotifierProvider<ReviewActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return ReviewActionsNotifier(repository, ref);
});