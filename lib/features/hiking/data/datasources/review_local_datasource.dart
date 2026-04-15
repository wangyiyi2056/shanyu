import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';

/// 本地评价数据源（使用 SharedPreferences）
class ReviewLocalDatasource {
  static const String _reviewsKey = 'hiking_reviews';
  static const String _favoritesKey = 'hiking_favorites';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// 获取某路线的所有评价
  Future<List<RouteReview>> getReviewsForRoute(String routeId) async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_reviewsKey);
    if (jsonString == null) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list
        .map((e) => RouteReview.fromJson(e as Map<String, dynamic>))
        .where((r) => r.routeId == routeId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取所有评价
  Future<List<RouteReview>> getAllReviews() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_reviewsKey);
    if (jsonString == null) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list
        .map((e) => RouteReview.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 添加评价
  Future<RouteReview> addReview(RouteReview review) async {
    final prefs = await _prefs;
    final reviews = await getAllReviews();
    reviews.add(review);
    await prefs.setString(_reviewsKey, jsonEncode(reviews.map((r) => r.toJson()).toList()));
    return review;
  }

  /// 删除评价
  Future<void> deleteReview(String reviewId) async {
    final prefs = await _prefs;
    final reviews = await getAllReviews();
    reviews.removeWhere((r) => r.id == reviewId);
    await prefs.setString(_reviewsKey, jsonEncode(reviews.map((r) => r.toJson()).toList()));
  }

  /// 获取某路线的平均评分
  Future<double> getAverageRating(String routeId) async {
    final reviews = await getReviewsForRoute(routeId);
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<double>(0.0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  /// 获取某路线的评价数量
  Future<int> getReviewCount(String routeId) async {
    final reviews = await getReviewsForRoute(routeId);
    return reviews.length;
  }

  /// 获取所有收藏
  Future<List<RouteFavorite>> getAllFavorites() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_favoritesKey);
    if (jsonString == null) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list
        .map((e) => RouteFavorite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 是否已收藏
  Future<bool> isFavorite(String routeId) async {
    final favorites = await getAllFavorites();
    return favorites.any((f) => f.routeId == routeId);
  }

  /// 添加收藏
  Future<void> addFavorite(String routeId) async {
    final prefs = await _prefs;
    final favorites = await getAllFavorites();
    if (favorites.any((f) => f.routeId == routeId)) return;

    favorites.add(RouteFavorite(
      routeId: routeId,
      createdAt: DateTime.now(),
    ));
    await prefs.setString(_favoritesKey, jsonEncode(favorites.map((f) => f.toJson()).toList()));
  }

  /// 取消收藏
  Future<void> removeFavorite(String routeId) async {
    final prefs = await _prefs;
    final favorites = await getAllFavorites();
    favorites.removeWhere((f) => f.routeId == routeId);
    await prefs.setString(_favoritesKey, jsonEncode(favorites.map((f) => f.toJson()).toList()));
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(String routeId) async {
    final isFav = await isFavorite(routeId);
    if (isFav) {
      await removeFavorite(routeId);
      return false;
    } else {
      await addFavorite(routeId);
      return true;
    }
  }
}
