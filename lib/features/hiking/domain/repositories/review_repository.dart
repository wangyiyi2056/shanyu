import 'package:hiking_assistant/features/hiking/data/datasources/review_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';

/// 评价仓储接口
abstract interface class ReviewRepository {
  Future<List<RouteReview>> getReviewsForRoute(String routeId);
  Future<List<RouteReview>> getAllReviews();
  Future<RouteReview> addReview(RouteReview review);
  Future<void> deleteReview(String reviewId);
  Future<double> getAverageRating(String routeId);
  Future<int> getReviewCount(String routeId);
  Future<bool> isFavorite(String routeId);
  Future<void> addFavorite(String routeId);
  Future<void> removeFavorite(String routeId);
  Future<bool> toggleFavorite(String routeId);
  Future<List<RouteFavorite>> getAllFavorites();
}

/// 评价仓储实现
class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewLocalDatasource _datasource;

  ReviewRepositoryImpl(this._datasource);

  @override
  Future<List<RouteReview>> getReviewsForRoute(String routeId) =>
      _datasource.getReviewsForRoute(routeId);

  @override
  Future<List<RouteReview>> getAllReviews() => _datasource.getAllReviews();

  @override
  Future<RouteReview> addReview(RouteReview review) =>
      _datasource.addReview(review);

  @override
  Future<void> deleteReview(String reviewId) =>
      _datasource.deleteReview(reviewId);

  @override
  Future<double> getAverageRating(String routeId) =>
      _datasource.getAverageRating(routeId);

  @override
  Future<int> getReviewCount(String routeId) =>
      _datasource.getReviewCount(routeId);

  @override
  Future<bool> isFavorite(String routeId) => _datasource.isFavorite(routeId);

  @override
  Future<void> addFavorite(String routeId) => _datasource.addFavorite(routeId);

  @override
  Future<void> removeFavorite(String routeId) =>
      _datasource.removeFavorite(routeId);

  @override
  Future<bool> toggleFavorite(String routeId) =>
      _datasource.toggleFavorite(routeId);

  @override
  Future<List<RouteFavorite>> getAllFavorites() =>
      _datasource.getAllFavorites();
}
