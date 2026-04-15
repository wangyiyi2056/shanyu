import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/route_detail_screen.dart';

void main() {
  const testRoute = HikingRoute(
    id: '1',
    name: '香山公园-亲子线',
    location: '北京市海淀区',
    description: '非常适合亲子徒步的路线，以石板路为主，坡度平缓。',
    distance: 2.3,
    elevationGain: 150,
    maxElevation: 300,
    estimatedDuration: 90,
    difficulty: 'easy',
    surfaceType: 'paved',
    tags: ['亲子', '新手', '红叶'],
    waypoints: [
      Waypoint(
        id: '1-1',
        name: '东门',
        type: 'start',
        latitude: 39.9042,
        longitude: 116.4074,
        elevation: 150,
      ),
      Waypoint(
        id: '1-2',
        name: '山顶',
        type: 'end',
        latitude: 39.9150,
        longitude: 116.4080,
        elevation: 300,
      ),
    ],
    warnings: ['注意防晒'],
    bestSeasons: ['春季', '秋季'],
    rating: 4.5,
    reviewCount: 1234,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RouteDetailScreen displays route information',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RouteDetailScreen(route: testRoute),
        ),
      ),
    );
    await tester.pump();

    // Verify route name is displayed
    expect(find.text('香山公园-亲子线'), findsOneWidget);

    // Verify description is displayed
    expect(
      find.text('非常适合亲子徒步的路线，以石板路为主，坡度平缓。'),
      findsOneWidget,
    );

    // Verify stats are displayed
    expect(find.text('2.3 km'), findsOneWidget);
    expect(find.text('90 分钟'), findsOneWidget);
    expect(find.text('150.0 m'), findsOneWidget);
    expect(find.text('300.0 m'), findsOneWidget);

    // Verify difficulty label
    expect(find.text('简单'), findsOneWidget);

    // Verify tags
    expect(find.text('亲子'), findsOneWidget);
    expect(find.text('新手'), findsOneWidget);

    // Verify waypoints
    expect(find.text('东门'), findsOneWidget);
    expect(find.text('山顶'), findsOneWidget);

    // Verify warnings
    expect(find.text('安全提示'), findsOneWidget);
    expect(find.text('注意防晒'), findsOneWidget);

    // Verify best seasons
    expect(find.text('最佳季节: 春季、秋季'), findsOneWidget);

    // Verify action buttons
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('开始导航'), findsOneWidget);

    // Verify review section
    expect(find.text('用户评价'), findsOneWidget);
    expect(find.text('写评价'), findsOneWidget);
  });

  testWidgets('RouteDetailScreen scrolls to show all content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RouteDetailScreen(route: testRoute),
        ),
      ),
    );
    await tester.pump();

    // Scroll down to find the map section
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('路线地图'), findsOneWidget);
  });
}
