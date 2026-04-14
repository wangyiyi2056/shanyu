import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/app.dart';
import 'package:hiking_assistant/core/firebase/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await FirebaseService.instance.initialize();

  runApp(
    const ProviderScope(
      child: HikingAssistantApp(),
    ),
  );
}
