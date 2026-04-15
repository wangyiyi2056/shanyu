import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/star_rating_widget.dart';

void main() {
  group('StarRatingWidget', () {
    testWidgets('displays correct stars for rating 3.5',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(rating: 3.5),
          ),
        ),
      );

      final stars = find.byType(Icon);
      expect(stars, findsNWidgets(5));

      final icons = tester.widgetList<Icon>(stars).toList();
      expect(icons[0].icon, Icons.star);
      expect(icons[1].icon, Icons.star);
      expect(icons[2].icon, Icons.star);
      expect(icons[3].icon, Icons.star_half);
      expect(icons[4].icon, Icons.star_border);
    });

    testWidgets('calls onRatingChanged when tapped in interactive mode',
        (WidgetTester tester) async {
      double? capturedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 0,
              interactive: true,
              onRatingChanged: (value) => capturedRating = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Icon).at(2));
      await tester.pump();

      expect(capturedRating, 3.0);
    });

    testWidgets('does not call onRatingChanged when not interactive',
        (WidgetTester tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 2,
              onRatingChanged: (_) => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Icon).first);
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('does not crash when interactive but no callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 2,
              interactive: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Icon).first);
      await tester.pump();

      // Should complete without error
      expect(find.byType(StarRatingWidget), findsOneWidget);
    });
  });

  group('ReviewInputDialog', () {
    testWidgets('shows route name in title and returns review data',
        (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final resultFuture = showDialog<Map<String, dynamic>>(
        context: capturedContext,
        builder: (_) => const ReviewInputDialog(routeName: '香山公园'),
      );
      await tester.pumpAndSettle();

      expect(find.text('评价 香山公园'), findsOneWidget);
      expect(find.byType(StarRatingWidget), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter a comment
      await tester.enterText(find.byType(TextField), '风景很美');
      await tester.pump();

      // Submit
      await tester.tap(find.text('提交'));
      await tester.pump();

      final result = await resultFuture;
      expect(result, isNotNull);
      expect(result!['rating'], 5.0);
      expect(result['comment'], '风景很美');
    });

    testWidgets('uses default comment when text is empty',
        (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final resultFuture = showDialog<Map<String, dynamic>>(
        context: capturedContext,
        builder: (_) => const ReviewInputDialog(routeName: '百望山'),
      );
      await tester.pumpAndSettle();

      // Change rating to 4 stars without entering text
      await tester.tap(find.byType(Icon).at(3));
      await tester.pump();

      await tester.tap(find.text('提交'));
      await tester.pump();

      final result = await resultFuture;
      expect(result, isNotNull);
      expect(result!['rating'], 4.0);
      expect(result['comment'], '用户体验不错');
    });

    testWidgets('can cancel the dialog', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final resultFuture = showDialog<Map<String, dynamic>?>(
        context: capturedContext,
        builder: (_) => const ReviewInputDialog(routeName: '测试路线'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pump();

      final result = await resultFuture;
      expect(result, isNull);
    });
  });
}
