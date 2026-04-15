import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/review_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';
import 'package:hiking_assistant/features/hiking/domain/repositories/review_repository.dart';

/// 评价本地数据源 Provider
final reviewLocalDatasourceProvider = Provider<ReviewLocalDatasource>((ref) {
  return ReviewLocalDatasource();
});

/// 评价仓储 Provider
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(reviewLocalDatasourceProvider));
});

/// 某路线的评价列表
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

/// 某路线是否已收藏
final routeFavoriteProvider =
    FutureProvider.family<bool, String>((ref, routeId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.isFavorite(routeId);
});

/// 所有收藏
final allFavoritesProvider = FutureProvider<List<RouteFavorite>>((ref) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getAllFavorites();
});

/// 评价操作 Notifier
class ReviewActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repository;
  final Ref _ref;

  ReviewActionsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// 提交评价
  Future<void> submitReview({
    required String routeId,
    required double rating,
    required String comment,
    String authorName = '游客',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final review = RouteReview(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        routeId: routeId,
        rating: rating,
        comment: comment,
        authorName: authorName,
        createdAt: DateTime.now(),
      );
      await _repository.addReview(review);
      _ref.invalidate(routeReviewsProvider(routeId));
      _ref.invalidate(routeAverageRatingProvider(routeId));
      _ref.invalidate(routeReviewCountProvider(routeId));
    });
  }

  /// 切换收藏
  Future<bool> toggleFavorite(String routeId) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final isFav = await _repository.toggleFavorite(routeId);
      _ref.invalidate(routeFavoriteProvider(routeId));
      _ref.invalidate(allFavoritesProvider);
      return isFav;
    });
    state = result;
    return result.valueOrNull ?? false;
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
