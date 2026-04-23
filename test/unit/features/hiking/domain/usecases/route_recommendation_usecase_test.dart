import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_api_datasource.dart';
import 'package:hiking_assistant/features/hiking/data/repositories/route_repository_impl.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/shared/utils/geo_utils.dart';

void main() {
  late RouteRepositoryImpl repository;
  late RouteRecommendationUseCase useCase;

  setUp(() {
    final localDatasource = RouteLocalDatasource();
    repository = RouteRepositoryImpl(
      apiDatasource: RouteApiDatasource.instance,
      localDatasource: localDatasource,
    );
    useCase = RouteRecommendationUseCase(repository);
  });

  group('RouteRecommendationUseCase', () {
    test('getRecommendations returns routes sorted by rating by default',
        () async {
      final recommendations = await useCase.getRecommendations(
        preferences: const RoutePreferences(),
      );
      expect(recommendations, isNotEmpty);
      // Default limit is 5
      expect(recommendations.length, lessThanOrEqualTo(5));
      // First route should have highest rating among sample routes
      expect(recommendations.first.route.rating, greaterThanOrEqualTo(4.2));
    });

    test('getRecommendationsSync filters by difficulty', () {
      final recommendations = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(preferredDifficulty: '新手'),
      );
      expect(recommendations, isNotEmpty);
      for (final rec in recommendations) {
        expect(rec.route.difficulty, 'easy');
      }
    });

    test('getRecommendations filters by maxDuration', () async {
      final recommendations = await useCase.getRecommendations(
        preferences: const RoutePreferences(maxDuration: 90),
      );
      for (final rec in recommendations) {
        expect(rec.route.estimatedDuration, lessThanOrEqualTo(90));
      }
    });

    test('getRecommendations filters by maxDistance', () async {
      final recommendations = await useCase.getRecommendations(
        preferences: const RoutePreferences(maxDistance: 3.0),
      );
      for (final rec in recommendations) {
        expect(rec.route.distance, lessThanOrEqualTo(3.0));
      }
    });

    test('getRecommendations filters by requiredTags', () async {
      final recommendations = await useCase.getRecommendations(
        preferences: const RoutePreferences(requiredTags: ['亲子']),
      );
      expect(recommendations, isNotEmpty);
      for (final rec in recommendations) {
        expect(rec.route.tags, contains('亲子'));
      }
    });

    test('returns empty list when no routes match criteria', () async {
      final recommendations = await useCase.getRecommendations(
        preferences: const RoutePreferences(
          preferredDifficulty: '专家级',
          maxDuration: 30,
          maxDistance: 1.0,
          requiredTags: ['不存在标签'],
        ),
      );
      expect(recommendations, isEmpty);
    });

    test('sorts by distance when user location is provided', () {
      // 香山公园附近坐标
      const userLat = 39.9042;
      const userLng = 116.4074;

      final recommendations = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(
          userLatitude: userLat,
          userLongitude: userLng,
        ),
        limit: 8,
      );

      expect(recommendations, isNotEmpty);
      // First route should be closest to user location
      final firstRoute = recommendations.first.route;
      final minDistance =
          _minWaypointDistance(firstRoute.waypoints, userLat, userLng);

      for (int i = 1; i < recommendations.length; i++) {
        final dist = _minWaypointDistance(
          recommendations[i].route.waypoints,
          userLat,
          userLng,
        );
        expect(minDistance, lessThanOrEqualTo(dist));
      }
    });

    test('searchByLocation returns matching routes with full score', () async {
      final recommendations = await useCase.searchByLocation('香山');
      expect(recommendations, isNotEmpty);
      for (final rec in recommendations) {
        expect(rec.matchScore, 1.0);
        expect(rec.matchReasons.first, contains('香山'));
        final nameLower = rec.route.name.toLowerCase();
        final locationLower = rec.route.location.toLowerCase();
        expect(
          nameLower.contains('香山') || locationLower.contains('香山'),
          isTrue,
        );
      }
    });

    test('searchByLocation returns empty list for unknown location', () async {
      final recommendations = await useCase.searchByLocation('火星');
      expect(recommendations, isEmpty);
    });

    test('matchScore reflects difficulty match', () {
      final easyRecs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(preferredDifficulty: '新手'),
      );
      for (final rec in easyRecs) {
        if (rec.route.difficulty == 'easy') {
          expect(rec.matchScore, greaterThan(0.5));
        } else {
          expect(rec.matchScore, lessThan(0.5));
        }
      }
    });

    test('matchScore reflects duration match', () {
      final recs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(maxDuration: 120),
      );
      for (final rec in recs) {
        if (rec.route.estimatedDuration <= 120) {
          expect(rec.matchScore, greaterThanOrEqualTo(0.5));
        }
      }
    });

    test('matchReasons includes difficulty when matched', () {
      final recs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(preferredDifficulty: '简单'),
      );
      for (final rec in recs) {
        if (rec.route.difficulty == 'easy') {
          expect(
            rec.matchReasons.any((r) => r.contains('难度')),
            isTrue,
          );
        }
      }
    });

    test('matchReasons includes duration when matched', () {
      final recs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(maxDuration: 200),
      );
      for (final rec in recs) {
        if (rec.route.estimatedDuration <= 200) {
          expect(
            rec.matchReasons.any((r) => r.contains('时长')),
            isTrue,
          );
        }
      }
    });

    test('matchReasons includes rating for highly rated routes', () {
      final recs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(),
      );
      for (final rec in recs) {
        if (rec.route.rating >= 4.5) {
          expect(
            rec.matchReasons.any((r) => r.contains('评分')),
            isTrue,
          );
        }
      }
    });

    test('matchReasons includes warnings when present', () {
      final recs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(),
      );
      final routeWithWarnings = recs.firstWhere(
        (r) => r.route.warnings.isNotEmpty,
        orElse: () => throw TestFailure('No route with warnings found'),
      );
      expect(
        routeWithWarnings.matchReasons.any((r) => r.contains('注意')),
        isTrue,
      );
    });

    test('matchScore is clamped between 0 and 1', () {
      // Using very restrictive preferences on sample data should not yield >1
      final recs = useCase.getRecommendationsSync(
        preferences: const RoutePreferences(
          preferredDifficulty: '新手',
          maxDuration: 1000,
          maxDistance: 100.0,
        ),
      );
      for (final rec in recs) {
        expect(rec.matchScore, greaterThanOrEqualTo(0.0));
        expect(rec.matchScore, lessThanOrEqualTo(1.0));
      }
    });
  });
}

double _minWaypointDistance(
  List<Waypoint> waypoints,
  double userLat,
  double userLng,
) {
  double minDist = double.infinity;
  for (final wp in waypoints) {
    final dist = GeoUtils.haversineDistance(userLat, userLng, wp.latitude, wp.longitude) / 1000;
    if (dist < minDist) minDist = dist;
  }
  return minDist;
}
