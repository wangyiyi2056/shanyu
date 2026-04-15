import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/review_provider.dart';
import 'package:hiking_assistant/features/profile/data/models/achievement_model.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

/// 所有可能的成就定义
final _allAchievements = [
  const Achievement(
    id: 'first_step',
    name: '初出茅庐',
    description: '完成第一次徒步记录',
    icon: Icons.hiking,
    color: Colors.green,
  ),
  const Achievement(
    id: 'seasoned_hiker',
    name: '徒步老手',
    description: '累计完成 5 次徒步记录',
    icon: Icons.terrain,
    color: Colors.teal,
  ),
  const Achievement(
    id: 'master_hiker',
    name: '山野行者',
    description: '累计完成 10 次徒步记录',
    icon: Icons.landscape,
    color: Colors.blue,
  ),
  const Achievement(
    id: 'distance_10k',
    name: '十里长征',
    description: '累计徒步距离达到 10 公里',
    icon: Icons.straighten,
    color: Colors.orange,
  ),
  const Achievement(
    id: 'distance_50k',
    name: '跋山涉水',
    description: '累计徒步距离达到 50 公里',
    icon: Icons.map,
    color: Colors.deepOrange,
  ),
  const Achievement(
    id: 'climb_1000',
    name: '步步高升',
    description: '累计爬升达到 1000 米',
    icon: Icons.trending_up,
    color: Colors.purple,
  ),
  const Achievement(
    id: 'climb_5000',
    name: '攀登者',
    description: '累计爬升达到 5000 米',
    icon: Icons.emoji_events,
    color: Colors.amber,
  ),
  const Achievement(
    id: 'collector',
    name: '收藏家',
    description: '收藏 3 条以上路线',
    icon: Icons.bookmark,
    color: Colors.pink,
  ),
];

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final tracksAsync = await ref.watch(tracksProvider.future);
  final favoritesAsync = await ref.watch(allFavoritesProvider.future);

  final trackCount = tracksAsync.length;
  final totalDistance = tracksAsync.fold<double>(
    0,
    (sum, t) => sum + t.totalDistance,
  );
  final totalElevation = tracksAsync.fold<double>(
    0,
    (sum, t) => sum + t.elevationGain,
  );
  final favoriteCount = favoritesAsync.length;

  return _allAchievements.map((a) {
    bool unlocked = false;
    switch (a.id) {
      case 'first_step':
        unlocked = trackCount >= 1;
      case 'seasoned_hiker':
        unlocked = trackCount >= 5;
      case 'master_hiker':
        unlocked = trackCount >= 10;
      case 'distance_10k':
        unlocked = totalDistance >= 10000;
      case 'distance_50k':
        unlocked = totalDistance >= 50000;
      case 'climb_1000':
        unlocked = totalElevation >= 1000;
      case 'climb_5000':
        unlocked = totalElevation >= 5000;
      case 'collector':
        unlocked = favoriteCount >= 3;
    }
    return a.copyWith(isUnlocked: unlocked);
  }).toList();
});
