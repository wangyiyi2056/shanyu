import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

/// 本地路线数据源（演示用）
/// 实际项目中会从 API 或数据库获取
class RouteLocalDatasource {
  /// 获取所有路线
  Future<List<HikingRoute>> getAllRoutes() async {
    return _sampleRoutes;
  }

  /// 根据 ID 获取路线
  Future<HikingRoute?> getRouteById(String id) async {
    return _sampleRoutes.where((route) => route.id == id).firstOrNull;
  }

  /// 根据地名搜索路线
  Future<List<HikingRoute>> searchRoutes(String query) async {
    final lowerQuery = query.toLowerCase();
    return _sampleRoutes.where((route) {
      return route.name.toLowerCase().contains(lowerQuery) ||
          route.location.toLowerCase().contains(lowerQuery) ||
          route.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 根据难度筛选
  Future<List<HikingRoute>> getRoutesByDifficulty(String difficulty) async {
    return _sampleRoutes
        .where((route) => route.difficulty == difficulty)
        .toList();
  }

  /// 根据用户偏好推荐路线
  Future<List<HikingRoute>> recommendRoutes({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  }) async {
    return recommendRoutesSync(
      preferredDifficulty: preferredDifficulty,
      maxDuration: maxDuration,
      maxDistance: maxDistance,
      requiredTags: requiredTags,
    );
  }

  /// 同步推荐路线
  List<HikingRoute> recommendRoutesSync({
    String? preferredDifficulty,
    int? maxDuration,
    double? maxDistance,
    List<String>? requiredTags,
  }) {
    var routes = _sampleRoutes.toList();

    // 按难度筛选
    if (preferredDifficulty != null) {
      routes = routes
          .where((r) => _matchDifficulty(r.difficulty, preferredDifficulty))
          .toList();
    }

    // 按时间筛选
    if (maxDuration != null) {
      routes = routes.where((r) => r.estimatedDuration <= maxDuration).toList();
    }

    // 按距离筛选
    if (maxDistance != null) {
      routes = routes.where((r) => r.distance <= maxDistance).toList();
    }

    // 按标签筛选
    if (requiredTags != null && requiredTags.isNotEmpty) {
      routes = routes.where((r) {
        return requiredTags.any((tag) => r.tags.contains(tag));
      }).toList();
    }

    // 按评分排序
    routes.sort((a, b) => b.rating.compareTo(a.rating));

    return routes;
  }

  bool _matchDifficulty(String routeDifficulty, String preferred) {
    final preferredLower = preferred.toLowerCase();
    if (preferredLower.contains('新手') || preferredLower.contains('简单')) {
      return routeDifficulty == 'easy';
    }
    if (preferredLower.contains('中级') || preferredLower.contains('一般')) {
      return routeDifficulty == 'moderate';
    }
    if (preferredLower.contains('难') || preferredLower.contains('挑战')) {
      return routeDifficulty == 'hard' || routeDifficulty == 'expert';
    }
    return true;
  }
}

/// 示例路线数据
final List<HikingRoute> _sampleRoutes = [
  const HikingRoute(
    id: '1',
    name: '香山公园-亲子线',
    location: '北京市海淀区',
    description: '非常适合亲子徒步的路线，以石板路为主，坡度平缓，沿途有多个休息亭。秋天红叶季节景色最美。',
    distance: 2.3,
    elevationGain: 150,
    maxElevation: 300,
    estimatedDuration: 90,
    difficulty: 'easy',
    surfaceType: 'paved',
    tags: ['亲子', '新手', '红叶', '有缆车'],
    waypoints: [
      Waypoint(
          id: '1-1',
          name: '东门',
          type: 'start',
          latitude: 39.9042,
          longitude: 116.4074,
          elevation: 150),
      Waypoint(
          id: '1-2',
          name: '香山寺',
          type: 'landmark',
          latitude: 39.9100,
          longitude: 116.4100,
          elevation: 220),
      Waypoint(
          id: '1-3',
          name: '山顶',
          type: 'end',
          latitude: 39.9150,
          longitude: 116.4080,
          elevation: 300),
    ],
    warnings: [],
    bestSeasons: ['春季', '秋季'],
    rating: 4.5,
    reviewCount: 1234,
    imageUrl:
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
  ),
  const HikingRoute(
    id: '2',
    name: '香山公园-主路线',
    location: '北京市海淀区',
    description: '香山经典路线，从东门到山顶需要一定体力，但路程不长，适合有一定基础的徒步者。',
    distance: 4.2,
    elevationGain: 450,
    maxElevation: 550,
    estimatedDuration: 150,
    difficulty: 'moderate',
    surfaceType: 'mixed',
    tags: ['经典', '有一定难度', '红叶'],
    waypoints: [
      Waypoint(
          id: '2-1',
          name: '东门',
          type: 'start',
          latitude: 39.9042,
          longitude: 116.4074,
          elevation: 100),
      Waypoint(
          id: '2-2',
          name: '香山寺',
          type: 'landmark',
          latitude: 39.9100,
          longitude: 116.4100,
          elevation: 250),
      Waypoint(
          id: '2-3',
          name: '鬼笑石',
          type: 'viewpoint',
          latitude: 39.9130,
          longitude: 116.4090,
          elevation: 450),
      Waypoint(
          id: '2-4',
          name: '香炉峰',
          type: 'end',
          latitude: 39.9150,
          longitude: 116.4080,
          elevation: 550),
    ],
    warnings: ['有一段较陡的石阶', '注意防晒'],
    bestSeasons: ['春季', '秋季'],
    rating: 4.6,
    reviewCount: 2345,
    imageUrl:
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
  ),
  const HikingRoute(
    id: '3',
    name: '百望山',
    location: '北京市海淀区',
    description: '距离市区较近的登山路线，山势平缓，植被茂密，空气清新。适合周末锻炼。',
    distance: 3.5,
    elevationGain: 350,
    maxElevation: 400,
    estimatedDuration: 120,
    difficulty: 'moderate',
    surfaceType: 'dirt',
    tags: ['新手进阶', '周末锻炼', '人少景美'],
    waypoints: [
      Waypoint(
          id: '3-1',
          name: '山脚',
          type: 'start',
          latitude: 39.9300,
          longitude: 116.3200,
          elevation: 50),
      Waypoint(
          id: '3-2',
          name: '望京楼',
          type: 'viewpoint',
          latitude: 39.9350,
          longitude: 116.3150,
          elevation: 300),
      Waypoint(
          id: '3-3',
          name: '山顶',
          type: 'end',
          latitude: 39.9400,
          longitude: 116.3100,
          elevation: 400),
    ],
    warnings: [],
    bestSeasons: ['春季', '夏季', '秋季'],
    rating: 4.3,
    reviewCount: 876,
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
  ),
  const HikingRoute(
    id: '4',
    name: '凤凰岭-北线',
    location: '北京市海淀区',
    description: '凤凰岭最经典的路线，以奇峰怪石著称，需要一定的攀爬能力。景色壮美，挑战性强。',
    distance: 5.5,
    elevationGain: 800,
    maxElevation: 750,
    estimatedDuration: 240,
    difficulty: 'hard',
    surfaceType: 'rocky',
    tags: ['挑战', '攀爬', '奇峰怪石'],
    waypoints: [
      Waypoint(
          id: '4-1',
          name: '景区入口',
          type: 'start',
          latitude: 40.0500,
          longitude: 116.0800,
          elevation: 150),
      Waypoint(
          id: '4-2',
          name: '天梯',
          type: 'danger',
          latitude: 40.0550,
          longitude: 116.0850,
          elevation: 400),
      Waypoint(
          id: '4-3',
          name: '飞来石',
          type: 'landmark',
          latitude: 40.0600,
          longitude: 116.0900,
          elevation: 600),
      Waypoint(
          id: '4-4',
          name: '北线山顶',
          type: 'end',
          latitude: 40.0650,
          longitude: 116.0950,
          elevation: 750),
    ],
    warnings: ['部分路段需要攀爬', '建议带手套', '注意防晒', '带足饮水'],
    bestSeasons: ['春季', '秋季'],
    rating: 4.7,
    reviewCount: 1567,
    imageUrl:
        'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80',
  ),
  const HikingRoute(
    id: '5',
    name: '妙峰山-古道',
    location: '北京市门头沟区',
    description: '古老的朝圣路线，路面以碎石为主，有一定历史感。山顶有古庙，适合喜欢历史文化的朋友。',
    distance: 6.2,
    elevationGain: 900,
    maxElevation: 1200,
    estimatedDuration: 300,
    difficulty: 'hard',
    surfaceType: 'rocky',
    tags: ['历史', '朝圣', '古道', '有一定危险'],
    waypoints: [
      Waypoint(
          id: '5-1',
          name: '涧沟村',
          type: 'start',
          latitude: 40.0200,
          longitude: 116.0500,
          elevation: 300),
      Waypoint(
          id: '5-2',
          name: '玫瑰谷',
          type: 'rest_area',
          latitude: 40.0300,
          longitude: 116.0550,
          elevation: 600),
      Waypoint(
          id: '5-3',
          name: '妙顶峰',
          type: 'end',
          latitude: 40.0400,
          longitude: 116.0600,
          elevation: 1200),
    ],
    warnings: ['路程较长', '部分路段陡峭', '注意防寒', '带足饮水和补给'],
    bestSeasons: ['夏季', '秋季'],
    rating: 4.4,
    reviewCount: 654,
    imageUrl:
        'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800&q=80',
  ),
  const HikingRoute(
    id: '6',
    name: '雾灵山-穿越线',
    location: '河北省承德市',
    description: '北京周边最原始的徒步路线之一，保持了较好的自然生态环境。需要一定经验和体力。',
    distance: 8.5,
    elevationGain: 1200,
    maxElevation: 1800,
    estimatedDuration: 420,
    difficulty: 'expert',
    surfaceType: 'mixed',
    tags: ['穿越', '原始森林', '挑战极限'],
    waypoints: [
      Waypoint(
          id: '6-1',
          name: '北门',
          type: 'start',
          latitude: 40.6000,
          longitude: 117.5000,
          elevation: 600),
      Waypoint(
          id: '6-2',
          name: '清凉界',
          type: 'rest_area',
          latitude: 40.6200,
          longitude: 117.5200,
          elevation: 1000),
      Waypoint(
          id: '6-3',
          name: '曹官营',
          type: 'rest_area',
          latitude: 40.6400,
          longitude: 117.5400,
          elevation: 1400),
      Waypoint(
          id: '6-4',
          name: '主峰',
          type: 'end',
          latitude: 40.6500,
          longitude: 117.5600,
          elevation: 1800),
    ],
    warnings: ['需要有一定经验', '建议结伴而行', '带足装备和补给', '注意防寒'],
    bestSeasons: ['夏季', '秋季'],
    rating: 4.8,
    reviewCount: 432,
    imageUrl:
        'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=800&q=80',
  ),
  const HikingRoute(
    id: '7',
    name: '长城-慕田峪',
    location: '北京市怀柔区',
    description: '相对游客较少的长城段落，保留了长城的原始风貌。城墙有一定起伏，徒步乐趣十足。',
    distance: 4.0,
    elevationGain: 400,
    maxElevation: 600,
    estimatedDuration: 180,
    difficulty: 'moderate',
    surfaceType: 'paved',
    tags: ['长城', '历史', '有一定难度'],
    waypoints: [
      Waypoint(
          id: '7-1',
          name: '景区入口',
          type: 'start',
          latitude: 40.4500,
          longitude: 116.5500,
          elevation: 200),
      Waypoint(
          id: '7-2',
          name: '正关台',
          type: 'landmark',
          latitude: 40.4600,
          longitude: 116.5600,
          elevation: 400),
      Waypoint(
          id: '7-3',
          name: '烽火台',
          type: 'end',
          latitude: 40.4700,
          longitude: 116.5700,
          elevation: 600),
    ],
    warnings: ['部分路段陡峭', '注意防晒'],
    bestSeasons: ['春季', '秋季'],
    rating: 4.5,
    reviewCount: 1876,
    imageUrl:
        'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80',
  ),
  const HikingRoute(
    id: '8',
    name: '白虎涧',
    location: '北京市昌平区',
    description: '以溪流和瀑布著称的峡谷路线，夏天可以玩水避暑。路线平缓，适合新手和家庭。',
    distance: 2.0,
    elevationGain: 100,
    maxElevation: 200,
    estimatedDuration: 60,
    difficulty: 'easy',
    surfaceType: 'dirt',
    tags: ['亲子', '玩水', '避暑', '新手'],
    waypoints: [
      Waypoint(
          id: '8-1',
          name: '景区入口',
          type: 'start',
          latitude: 40.1000,
          longitude: 116.2000,
          elevation: 100),
      Waypoint(
          id: '8-2',
          name: '瀑布',
          type: 'viewpoint',
          latitude: 40.1050,
          longitude: 116.2050,
          elevation: 150),
      Waypoint(
          id: '8-3',
          name: '山顶亭',
          type: 'end',
          latitude: 40.1100,
          longitude: 116.2100,
          elevation: 200),
    ],
    warnings: [],
    bestSeasons: ['夏季'],
    rating: 4.2,
    reviewCount: 987,
    imageUrl:
        'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800&q=80',
  ),
];
