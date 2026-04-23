import 'package:hiking_assistant/features/chat/domain/tools/chat_tool.dart';
import 'package:hiking_assistant/shared/services/location_service.dart';

/// 位置查询工具
class LocationTool extends ChatTool {
  final LocationService _locationService;

  LocationTool(this._locationService);

  @override
  String get name => 'get_current_location';

  @override
  String get displayName => '当前位置';

  @override
  String get description =>
      '获取用户的当前位置信息（经纬度和地址）。当用户需要知道自己在哪里、或需要提供位置信息给其他功能时使用。';

  @override
  List<ToolParameter> get parameters => [];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (!location.isSuccess) {
        return '无法获取当前位置，请检查定位权限是否开启。';
      }

      return '''当前位置信息:
- 地址: ${location.address}
- 纬度: ${location.latitude}
- 经度: ${location.longitude}''';
    } on Exception catch (e) {
      return '位置获取失败: $e';
    }
  }
}
