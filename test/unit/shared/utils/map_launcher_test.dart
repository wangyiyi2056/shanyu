import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/shared/utils/map_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const platform = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (call) async {
      if (call.method == 'canLaunch') {
        final url = call.arguments['url'] as String;
        // Mock Apple Maps available on iOS-like URLs
        if (url.contains('maps.apple.com')) {
          return true;
        }
        // Mock Google Maps available universally
        if (url.contains('google.com')) {
          return true;
        }
        return false;
      }
      if (call.method == 'launch') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, null);
  });

  test('launchMapNavigation uses Apple Maps when available', () async {
    final result = await launchMapNavigation(
      latitude: 39.9042,
      longitude: 116.4074,
      label: '香山公园',
    );
    expect(result, isTrue);
  });

  test('launchMapNavigation falls back to Google Maps', () async {
    // Override handler so Apple Maps is unavailable
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (call) async {
      if (call.method == 'canLaunch') {
        final url = call.arguments['url'] as String;
        if (url.contains('maps.apple.com')) {
          return false;
        }
        if (url.contains('google.com')) {
          return true;
        }
        return false;
      }
      if (call.method == 'launch') {
        return true;
      }
      return null;
    });

    final result = await launchMapNavigation(
      latitude: 39.9042,
      longitude: 116.4074,
    );
    expect(result, isTrue);
  });

  test('launchMapNavigation returns false when no map app is available',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (call) async {
      if (call.method == 'canLaunch') {
        return false;
      }
      return null;
    });

    final result = await launchMapNavigation(
      latitude: 39.9042,
      longitude: 116.4074,
    );
    expect(result, isFalse);
  });
}
