import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/chat/domain/entities/message.dart';
import 'package:hiking_assistant/features/chat/presentation/widgets/chat_bubble.dart';

void main() {
  const platform = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (call) async {
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

  testWidgets('ChatBubble rejects dangerous link schemes',
      (WidgetTester tester) async {
    final message = Message(
      id: '1',
      conversationId: 'c1',
      role: MessageRole.assistant,
      content: '[link](javascript:alert(1))',
      createdAt: DateTime(2024, 1, 1, 12, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(message: message),
        ),
      ),
    );

    // Tap the link rendered by MarkdownBody
    await tester.tap(find.text('link'));
    await tester.pump();

    expect(find.text('不支持的链接类型'), findsOneWidget);
  });

  testWidgets('ChatBubble allows https links', (WidgetTester tester) async {
    final message = Message(
      id: '2',
      conversationId: 'c1',
      role: MessageRole.assistant,
      content: '[google](https://google.com)',
      createdAt: DateTime(2024, 1, 1, 12, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(message: message),
        ),
      ),
    );

    await tester.tap(find.text('google'));
    await tester.pump();

    // No error snackbar should appear
    expect(find.text('不支持的链接类型'), findsNothing);
  });
}
