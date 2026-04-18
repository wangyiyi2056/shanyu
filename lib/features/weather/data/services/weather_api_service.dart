import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

/// 天气 API 服务（基于 Open-Meteo，无需 API Key）
class WeatherApiService {
  static final WeatherApiService _instance = WeatherApiService._internal();
  factory WeatherApiService() => _instance;
  WeatherApiService._internal();

  static WeatherApiService get instance => _instance;

  final http.Client _client = http.Client();
  static const String _baseUrl = 'api.open-meteo.com';

  /// 获取指定位置的天气信息
  Future<WeatherData> getWeather(double latitude, double longitude) async {
    try {
      final uri = Uri.https(_baseUrl, '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current_weather': 'true',
        'daily': 'temperature_2m_max,temperature_2m_min,weathercode',
        'timezone': 'auto',
        'forecast_days': '3',
      });

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseWeatherData(data);
      } else {
        throw Exception('天气服务暂时不可用 (HTTP ${response.statusCode})');
      }
    } on Exception catch (_) {
      // 网络错误时返回默认数据
      return _getFallbackWeather(latitude, longitude);
    }
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final current = data['current_weather'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>?;

    final weatherCode = current['weathercode'] as int;

    // Parse daily forecast
    List<DailyForecast>? forecast;
    if (daily != null) {
      final dates = (daily['time'] as List<dynamic>?)?.cast<String>() ?? [];
      final maxTemps = (daily['temperature_2m_max'] as List<dynamic>?)?.cast<num>() ?? [];
      final minTemps = (daily['temperature_2m_min'] as List<dynamic>?)?.cast<num>() ?? [];
      final codes = (daily['weathercode'] as List<dynamic>?)?.cast<int>() ?? [];

      forecast = [];
      for (var i = 0; i < dates.length && i < maxTemps.length && i < minTemps.length && i < codes.length; i++) {
        forecast.add(DailyForecast(
          date: DateTime.parse(dates[i]),
          maxTemp: maxTemps[i].toDouble(),
          minTemp: minTemps[i].toDouble(),
          weatherCode: codes[i],
          description: weatherCodeToDescription(codes[i]),
        ));
      }
    }

    return WeatherData(
      temperature: (current['temperature'] as num).toDouble(),
      windSpeed: (current['windspeed'] as num).toDouble(),
      weatherCode: weatherCode,
      description: weatherCodeToDescription(weatherCode),
      maxTemp: daily != null
          ? (daily['temperature_2m_max'] as List<dynamic>?)?.isNotEmpty == true
              ? (daily['temperature_2m_max'][0] as num).toDouble()
              : null
          : null,
      minTemp: daily != null
          ? (daily['temperature_2m_min'] as List<dynamic>?)?.isNotEmpty == true
              ? (daily['temperature_2m_min'][0] as num).toDouble()
              : null
          : null,
      updatedAt: DateTime.now(),
      forecast: forecast,
    );
  }

  /// 获取默认位置（北京）的天气
  Future<WeatherData> getDefaultWeather() async {
    return getWeather(39.9042, 116.4074);
  }

  /// 根据路线获取天气（使用路线第一个 waypoint 的位置）
  Future<WeatherData> getWeatherForRoute(List<Waypoint> waypoints) async {
    if (waypoints.isEmpty) {
      return getDefaultWeather();
    }
    final first = waypoints.first;
    return getWeather(first.latitude, first.longitude);
  }

  WeatherData _getFallbackWeather(double latitude, double longitude) {
    return WeatherData(
      temperature: 22,
      windSpeed: 8,
      weatherCode: 1,
      description: '主要晴朗',
      maxTemp: 26,
      minTemp: 15,
      updatedAt: DateTime.now(),
    );
  }
}
