import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/review_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';

void main() {
  late ReviewLocalDatasource datasource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    datasource = ReviewLocalDatasource();
  });

  group('ReviewLocalDatasource', () {
    test('returns empty list when no reviews exist', () async {
      final reviews = await datasource.getReviewsForRoute('route-1');
      expect(reviews, isEmpty);
    });

    test('adds and retrieves a review', () async {
      final review = RouteReview(
        id: 'review-1',
        routeId: 'route-1',
        rating: 4.5,
        comment: '风景不错',
        authorName: '张三',
        createdAt: DateTime(2024, 1, 1),
      );

      await datasource.addReview(review);
      final reviews = await datasource.getReviewsForRoute('route-1');

      expect(reviews.length, 1);
      expect(reviews.first.id, 'review-1');
      expect(reviews.first.rating, 4.5);
      expect(reviews.first.comment, '风景不错');
    });

    test('only returns reviews for specified route', () async {
      await datasource.addReview(RouteReview(
        id: 'r1',
        routeId: 'route-a',
        rating: 5.0,
        comment: 'Great!',
        createdAt: DateTime.now(),
      ));
      await datasource.addReview(RouteReview(
        id: 'r2',
        routeId: 'route-b',
        rating: 3.0,
        comment: 'Okay',
        createdAt: DateTime.now(),
      ));

      final reviewsA = await datasource.getReviewsForRoute('route-a');
      expect(reviewsA.length, 1);
      expect(reviewsA.first.routeId, 'route-a');
    });

    test('deletes a review', () async {
      await datasource.addReview(RouteReview(
        id: 'review-to-delete',
        routeId: 'route-1',
        rating: 2.0,
        comment: 'Bad',
        createdAt: DateTime.now(),
      ));

      await datasource.deleteReview('review-to-delete');
      final reviews = await datasource.getReviewsForRoute('route-1');
      expect(reviews, isEmpty);
    });

    test('calculates average rating correctly', () async {
      await datasource.addReview(RouteReview(
        id: 'r1',
        routeId: 'route-1',
        rating: 4.0,
        comment: '',
        createdAt: DateTime.now(),
      ));
      await datasource.addReview(RouteReview(
        id: 'r2',
        routeId: 'route-1',
        rating: 5.0,
        comment: '',
        createdAt: DateTime.now(),
      ));

      final avg = await datasource.getAverageRating('route-1');
      expect(avg, 4.5);
    });

    test('returns 0.0 for average rating when no reviews', () async {
      final avg = await datasource.getAverageRating('route-1');
      expect(avg, 0.0);
    });

    test('toggles favorite status', () async {
      expect(await datasource.isFavorite('route-1'), false);

      final added = await datasource.toggleFavorite('route-1');
      expect(added, true);
      expect(await datasource.isFavorite('route-1'), true);

      final removed = await datasource.toggleFavorite('route-1');
      expect(removed, false);
      expect(await datasource.isFavorite('route-1'), false);
    });

    test('returns all favorites', () async {
      await datasource.addFavorite('route-1');
      await datasource.addFavorite('route-2');

      final favorites = await datasource.getAllFavorites();
      expect(favorites.length, 2);
      expect(favorites.map((f) => f.routeId).toList()..sort(),
          ['route-1', 'route-2']);
    });
  });
}
