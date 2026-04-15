import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/chat/domain/entities/intent.dart';
import 'package:hiking_assistant/features/chat/domain/services/intent_service.dart';

void main() {
  late IntentService intentService;

  setUp(() {
    intentService = IntentService();
  });

  group('IntentService', () {
    test('detects emergency intent', () {
      final intent = intentService.detectIntent('我受伤了，救命');
      expect(intent.category, IntentCategory.emergency);
      expect(intent.confidence, 1.0);
      expect(intent.isEmergency, isTrue);
      expect(intent.quickResponse, isNotNull);
    });

    test('detects weather query intent', () {
      final intent = intentService.detectIntent('今天天气怎么样');
      expect(intent.category, IntentCategory.weatherQuery);
    });

    test('detects route search intent', () {
      final intent = intentService.detectIntent('附近有什么山可以爬');
      expect(intent.category, IntentCategory.routeSearch);
    });

    test('detects route recommendation intent', () {
      final intent = intentService.detectIntent('推荐一条适合新手的路线');
      expect(intent.category, IntentCategory.routeRecommendation);
    });

    test('detects navigation intent', () {
      final intent = intentService.detectIntent('导航到香山');
      expect(intent.category, IntentCategory.navigation);
    });

    test('detects plant identification intent', () {
      final intent = intentService.detectIntent('这是什么植物');
      expect(intent.category, IntentCategory.plantIdentification);
    });

    test('detects greeting intent with quick response', () {
      final intent = intentService.detectIntent('你好');
      expect(intent.category, IntentCategory.greeting);
      expect(intent.isGreeting, isTrue);
      expect(intent.isQuickResponse, isTrue);
      expect(intent.quickResponse, isNotNull);
    });

    test('detects farewell intent with quick response', () {
      final intent = intentService.detectIntent('再见');
      expect(intent.category, IntentCategory.farewell);
      expect(intent.isFarewell, isTrue);
      expect(intent.isQuickResponse, isTrue);
      expect(intent.quickResponse, isNotNull);
    });

    test('detects help intent with quick response', () {
      final intent = intentService.detectIntent('你能做什么');
      expect(intent.category, IntentCategory.help);
      expect(intent.isHelp, isTrue);
      expect(intent.isQuickResponse, isTrue);
      expect(intent.quickResponse, contains('路线推荐'));
    });

    test('returns unknown intent when no rules match', () {
      final intent = intentService.detectIntent('abcdefg 无意义输入');
      expect(intent.category, IntentCategory.unknown);
      expect(intent.confidence, 0.0);
    });

    test('extracts location entity for route search fallback', () {
      final intent = intentService.detectIntent('香山天气怎么样');
      expect(intent.category, IntentCategory.weatherQuery);
      expect(intent.entities['location'], '香山');
    });

    test('falls back to route search when only location is detected', () {
      final intent = intentService.detectIntent('百望山');
      expect(intent.category, IntentCategory.routeSearch);
      expect(intent.confidence, 0.5);
      expect(intent.entities['location'], '百望山');
    });

    test('extracts multiple known locations', () {
      final locations = ['香山', '百望山', '凤凰岭', '泰山'];
      for (final loc in locations) {
        final intent = intentService.detectIntent('$loc怎么走');
        expect(intent.entities['location'], loc);
      }
    });

    test('displayName returns correct Chinese names', () {
      final emergency = intentService.detectIntent('救命');
      expect(emergency.displayName, '紧急求助');

      final weather = intentService.detectIntent('天气');
      expect(weather.displayName, '天气查询');

      final unknown = intentService.detectIntent('xyz');
      expect(unknown.displayName, '未知');
    });

    test('quick response categories are identified correctly', () {
      expect(intentService.detectIntent('你好').isQuickResponse, isTrue);
      expect(intentService.detectIntent('再见').isQuickResponse, isTrue);
      expect(intentService.detectIntent('帮助').isQuickResponse, isTrue);
      expect(intentService.detectIntent('救命').isQuickResponse, isTrue);
      expect(intentService.detectIntent('天气').isQuickResponse, isFalse);
    });
  });
}
