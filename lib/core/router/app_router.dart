import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:hiking_assistant/features/chat/presentation/screens/chat_screen.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/home_screen.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/map_screen.dart';
import 'package:hiking_assistant/features/hiking/presentation/screens/route_detail_screen.dart';
import 'package:hiking_assistant/features/profile/presentation/screens/achievements_screen.dart';
import 'package:hiking_assistant/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:hiking_assistant/features/profile/presentation/screens/favorites_screen.dart';
import 'package:hiking_assistant/features/profile/presentation/screens/profile_screen.dart';
import 'package:hiking_assistant/features/profile/presentation/screens/settings_screen.dart';
import 'package:hiking_assistant/features/tracking/presentation/screens/track_detail_screen.dart';
import 'package:hiking_assistant/features/tracking/presentation/screens/track_list_screen.dart';
import 'package:hiking_assistant/shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,
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
          final extra = state.extra;
          if (extra is! HikingRoute) {
            return const Scaffold(
              body: Center(child: Text('路线信息缺失')),
            );
          }
          return RouteDetailScreen(route: extra);
        },
      ),

      // 轨迹列表页
      GoRoute(
        path: '/tracks',
        name: 'trackList',
        builder: (context, state) => const TrackListScreen(),
      ),

      // 轨迹详情页
      GoRoute(
        path: '/track/:id',
        name: 'trackDetail',
        builder: (context, state) {
          final trackId = state.pathParameters['id'] ?? '';
          return TrackDetailScreen(trackId: trackId);
        },
      ),

      // 设置页
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // 收藏路线页
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // 编辑资料页
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // 成就徽章页
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
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
            pageBuilder: (context, state) => NoTransitionPage(
              child: ChatScreen(
                initialMessage: state.uri.queryParameters['message'],
              ),
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
