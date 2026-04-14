import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:hiking_assistant/features/chat/presentation/screens/chat_screen.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/home_screen.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/map_screen.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/route_detail_screen.dart';
import 'package:hiking_assistant/features/profile/presentation/screens/profile_screen.dart';
import 'package:hiking_assistant/shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/chat',
    debugLogDiagnostics: true,
    routes: [
      // 登录页
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 路线详情页
      GoRoute(
        path: '/route/:id',
        name: 'routeDetail',
        builder: (context, state) {
          final route = state.extra as HikingRoute?;
          if (route == null) {
            return const Scaffold(
              body: Center(child: Text('路线信息缺失')),
            );
          }
          return RouteDetailScreen(route: route);
        },
      ),

      // 主应用 Shell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // 首页
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // 地图页
          GoRoute(
            path: '/map',
            name: 'map',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapScreen(),
            ),
          ),

          // AI 聊天页（默认页）
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatScreen(),
            ),
          ),

          // 个人页
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/chat'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});
