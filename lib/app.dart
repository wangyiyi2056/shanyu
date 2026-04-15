import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/router/app_router.dart';
import 'package:hiking_assistant/core/theme/app_theme.dart';
import 'package:hiking_assistant/features/profile/presentation/providers/settings_provider.dart';

class HikingAssistantApp extends ConsumerWidget {
  const HikingAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '爬山助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeModeAsync.valueOrNull ?? ThemeMode.system,
      routerConfig: router,
    );
  }
}
