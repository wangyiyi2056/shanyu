import 'package:hiking_assistant/features/chat/domain/tools/chat_tool.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';

/// 路线搜索工具
class RouteSearchTool extends ChatTool {
  final RouteRecommendationUseCase _routeUseCase;

  RouteSearchTool(this._routeUseCase);

  @override
  String get name => 'search_routes';

  @override
  String get displayName => '路线搜索';

  @override
  String get description =>
      '根据用户位置、难度偏好、时间等条件搜索附近的爬山/徒步路线。当用户想找路线、询问某个山的信息、或需要路线推荐时使用。';

  @override
  List<ToolParameter> get parameters => [
        ToolParameter(
          name: 'user_latitude',
          type: 'number',
          description: '用户当前纬度，例如 39.9042',
          required: false,
        ),
        ToolParameter(
          name: 'user_longitude',
          type: 'number',
          description: '用户当前经度，例如 116.4074',
          required: false,
        ),
        ToolParameter(
          name: 'difficulty',
          type: 'string',
          description: '难度偏好: 新手/简单, 中级/一般, 难/挑战',
          required: false,
        ),
        ToolParameter(
          name: 'max_duration_minutes',
          type: 'integer',
          description: '最大时长（分钟），例如 120 表示 2 小时',
          required: false,
        ),
        ToolParameter(
          name: 'max_distance_km',
          type: 'number',
          description: '最大距离（公里），例如 5.0',
          required: false,
        ),
        ToolParameter(
          name: 'location_name',
          type: 'string',
          description: '地点名称，例如 "香山", "百望山"',
          required: false,
        ),
      ];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    try {
      final preferences = RoutePreferences(
        preferredDifficulty: arguments['difficulty'] as String?,
        maxDuration: (arguments['max_duration_minutes'] as num?)?.toInt(),
        maxDistance: (arguments['max_distance_km'] as num?)?.toDouble(),
        userLatitude: (arguments['user_latitude'] as num?)?.toDouble(),
        userLongitude: (arguments['user_longitude'] as num?)?.toDouble(),
      );

      final results = await _routeUseCase.getRecommendations(
        preferences: preferences,
        limit: 3,
      );

      if (results.isEmpty) {
        return '未找到符合条件的路线，建议放宽条件或尝试其他地点。';
      }

      final buffer = StringBuffer();
      buffer.writeln('找到 ${results.length} 条推荐路线:');
      for (int i = 0; i < results.length; i++) {
        final rec = results[i];
        final route = rec.route;
        buffer.writeln();
        buffer.writeln('${i + 1}. ${route.name}');
        buffer.writeln('   - 位置: ${route.location}');
        buffer.writeln('   - 难度: ${route.difficultyLabel}');
        buffer.writeln('   - 距离: ${route.distance} km');
        buffer.writeln('   - 预计时长: ${route.estimatedDuration} 分钟');
        buffer.writeln('   - 爬升: ${route.elevationGain} m');
        buffer.writeln('   - 评分: ${route.rating}');
        if (route.warnings.isNotEmpty) {
          buffer.writeln('   - 注意: ${route.warnings.join(", ")}');
        }
        buffer.writeln('   - 推荐理由: ${rec.matchReasons.join("; ")}');
      }

      return buffer.toString();
    } on Exception catch (e) {
      return '路线搜索失败: $e';
    }
  }
}
