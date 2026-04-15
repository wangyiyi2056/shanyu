import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';

void main() {
  late RouteLocalDatasource datasource;

  setUp(() {
    datasource = RouteLocalDatasource();
  });

  group('RouteLocalDatasource', () {
    test('getAllRoutes returns sample routes', () async {
      final routes = await datasource.getAllRoutes();
      expect(routes.length, 8);
      expect(routes.first.name, '香山公园-亲子线');
    });

    test('getRouteById returns correct route', () async {
      final route = await datasource.getRouteById('2');
      expect(route, isNotNull);
      expect(route!.name, '香山公园-主路线');
      expect(route.difficulty, 'moderate');
    });

    test('getRouteById returns null for unknown id', () async {
      final route = await datasource.getRouteById('999');
      expect(route, isNull);
    });

    test('searchRoutes matches name', () async {
      final routes = await datasource.searchRoutes('香山');
      expect(routes.length, 2);
      for (final route in routes) {
        expect(route.name.contains('香山'), isTrue);
      }
    });

    test('searchRoutes matches location', () async {
      final routes = await datasource.searchRoutes('昌平');
      expect(routes.length, 1);
      expect(routes.first.name, '白虎涧');
    });

    test('searchRoutes matches tags', () async {
      final routes = await datasource.searchRoutes('红叶');
      expect(routes.length, 2);
      for (final route in routes) {
        expect(route.tags, contains('红叶'));
      }
    });

    test('searchRoutes is case insensitive', () async {
      final routesLower = await datasource.searchRoutes('xiangshan');
      final routesUpper = await datasource.searchRoutes('XIANGSHAN');
      expect(routesLower.length, routesUpper.length);
    });

    test('searchRoutes returns empty list for no matches', () async {
      final routes = await datasource.searchRoutes('火星');
      expect(routes, isEmpty);
    });

    test('getRoutesByDifficulty filters correctly', () async {
      final easyRoutes = await datasource.getRoutesByDifficulty('easy');
      expect(easyRoutes.length, 2);
      for (final route in easyRoutes) {
        expect(route.difficulty, 'easy');
      }

      final hardRoutes = await datasource.getRoutesByDifficulty('hard');
      expect(hardRoutes.length, 2);
      for (final route in hardRoutes) {
        expect(route.difficulty, 'hard');
      }
    });

    test('recommendRoutes filters by difficulty', () async {
      final routes = await datasource.recommendRoutes(
        preferredDifficulty: '简单',
      );
      expect(routes, isNotEmpty);
      for (final route in routes) {
        expect(route.difficulty, 'easy');
      }
    });

    test('recommendRoutes filters by maxDuration', () async {
      final routes = await datasource.recommendRoutes(maxDuration: 90);
      for (final route in routes) {
        expect(route.estimatedDuration, lessThanOrEqualTo(90));
      }
    });

    test('recommendRoutes filters by maxDistance', () async {
      final routes = await datasource.recommendRoutes(maxDistance: 2.5);
      for (final route in routes) {
        expect(route.distance, lessThanOrEqualTo(2.5));
      }
    });

    test('recommendRoutes filters by requiredTags', () async {
      final routes = await datasource.recommendRoutes(
        requiredTags: ['亲子'],
      );
      expect(routes, isNotEmpty);
      for (final route in routes) {
        expect(route.tags, contains('亲子'));
      }
    });

    test('recommendRoutes returns routes sorted by rating desc', () async {
      final routes = await datasource.recommendRoutes();
      for (int i = 0; i < routes.length - 1; i++) {
        expect(
          routes[i].rating,
          greaterThanOrEqualTo(routes[i + 1].rating),
        );
      }
    });

    test('recommendRoutesSync returns same results as recommendRoutes',
        () async {
      final asyncRoutes = await datasource.recommendRoutes(
        preferredDifficulty: '中级',
        maxDuration: 200,
        maxDistance: 5.0,
      );
      final syncRoutes = datasource.recommendRoutesSync(
        preferredDifficulty: '中级',
        maxDuration: 200,
        maxDistance: 5.0,
      );

      expect(syncRoutes.length, asyncRoutes.length);
      for (int i = 0; i < syncRoutes.length; i++) {
        expect(syncRoutes[i].id, asyncRoutes[i].id);
      }
    });

    test('recommendRoutes handles multiple filters simultaneously', () async {
      final routes = await datasource.recommendRoutes(
        preferredDifficulty: '新手',
        maxDuration: 120,
        maxDistance: 3.0,
        requiredTags: ['新手'],
      );
      for (final route in routes) {
        expect(route.difficulty, 'easy');
        expect(route.estimatedDuration, lessThanOrEqualTo(120));
        expect(route.distance, lessThanOrEqualTo(3.0));
        expect(route.tags, contains('新手'));
      }
    });

    test('recommendRoutes returns empty when criteria are too strict',
        () async {
      final routes = await datasource.recommendRoutes(
        preferredDifficulty: '专家级',
        maxDuration: 30,
        maxDistance: 1.0,
        requiredTags: ['不存在'],
      );
      expect(routes, isEmpty);
    });
  });
}
