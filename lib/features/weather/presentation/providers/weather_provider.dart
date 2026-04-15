import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';
import 'package:hiking_assistant/features/weather/data/services/weather_api_service.dart';

/// 天气服务 Provider
final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService.instance;
});

/// 指定位置的天气数据
final weatherProvider = FutureProvider.family<WeatherData, (double, double)>(
  (ref, coords) async {
    final service = ref.watch(weatherApiServiceProvider);
    return service.getWeather(coords.$1, coords.$2);
  },
);

/// 默认位置（北京）的天气
final defaultWeatherProvider = FutureProvider<WeatherData>((ref) async {
  final service = ref.watch(weatherApiServiceProvider);
  return service.getDefaultWeather();
});
