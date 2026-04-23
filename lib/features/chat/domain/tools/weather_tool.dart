import 'package:hiking_assistant/features/chat/domain/tools/chat_tool.dart';
import 'package:hiking_assistant/features/weather/data/services/weather_api_service.dart';

/// 天气查询工具
class WeatherTool extends ChatTool {
  final WeatherApiService _weatherService;

  WeatherTool(this._weatherService);

  @override
  String get name => 'get_weather';

  @override
  String get displayName => '天气查询';

  @override
  String get description =>
      '获取指定位置的实时天气和预报信息。当用户询问天气、温度、降雨、风力等与天气相关的问题时使用。';

  @override
  List<ToolParameter> get parameters => [
    ToolParameter(
      name: 'latitude',
      type: 'number',
      description: '纬度坐标，例如 39.9042',
      required: true,
    ),
    ToolParameter(
      name: 'longitude',
      type: 'number',
      description: '经度坐标，例如 116.4074',
      required: true,
    ),
  ];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    try {
      final lat = (arguments['latitude'] as num?)?.toDouble() ?? 39.9042;
      final lon = (arguments['longitude'] as num?)?.toDouble() ?? 116.4074;

      final weather = await _weatherService.getWeather(lat, lon);

      return '''天气信息:
- 当前: ${weather.description}
- 温度: ${weather.temperature.toStringAsFixed(0)}°C
- 最高/最低: ${weather.maxTemp?.toStringAsFixed(0)}°C / ${weather.minTemp?.toStringAsFixed(0)}°C
- 风速: ${weather.windSpeed.toStringAsFixed(0)} km/h
- 爬山建议: ${weather.hikingAdvice}''';
    } on Exception catch (e) {
      return '天气查询失败: $e';
    }
  }
}
