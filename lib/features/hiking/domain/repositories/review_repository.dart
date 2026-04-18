import 'package:hiking_assistant/features/hiking/data/datasources/review_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_api_datasource.dart' as api;
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';

/// 评价仓储接口
abstract interface class ReviewRepository {
  Future<List<RouteReview>> getReviewsForRoute(String routeId);
  Future<void> addReview(String routeId, double rating, String comment, String authorName);
  Future<void> deleteReview(String reviewId);
  Future<double> getAverageRating(String routeId);
  Future<int> getReviewCount(String routeId);
}

/// 评价仓储实现 - 支持 API 和本地数据源
class ReviewRepositoryImpl implements ReviewRepository {
  final api.RouteApiDatasource _apiDatasource;
  final ReviewLocalDatasource _localDatasource;
  final bool _isAuthenticated;

  ReviewRepositoryImpl({
    required api.RouteApiDatasource apiDatasource,
    required ReviewLocalDatasource localDatasource,
    required bool isAuthenticated,
  })  : _apiDatasource = apiDatasource,
        _localDatasource = localDatasource,
        _isAuthenticated = isAuthenticated;

  @override
  Future<List<RouteReview>> getReviewsForRoute(String routeId) async {
    if (_isAuthenticated) {
      try {
        final reviews = await _apiDatasource.getReviews(routeId);
        if (reviews.isNotEmpty) return reviews;
      } catch (e) {
        // Fall back to local on API error
      }
    }
    return _localDatasource.getReviewsForRoute(routeId);
  }

  @override
  Future<void> addReview(String routeId, double rating, String comment, String authorName) async {
    if (_isAuthenticated) {
      try {
        await _apiDatasource.createReview(routeId, rating.toInt(), comment);
        return;
      } catch (e) {
        // Fall back to local on API error
      }
    }
    final review = RouteReview(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      routeId: routeId,
      rating: rating,
      comment: comment,
      authorName: authorName,
      createdAt: DateTime.now(),
    );
    await _localDatasource.addReview(review);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    // Local delete only (API delete requires ownership verification)
    await _localDatasource.deleteReview(reviewId);
  }

  @override
  Future<double> getAverageRating(String routeId) async {
    final reviews = await getReviewsForRoute(routeId);
    if (reviews.isEmpty) return 0.0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  @override
  Future<int> getReviewCount(String routeId) async {
    final reviews = await getReviewsForRoute(routeId);
    return reviews.length;
  }
}