/// 天气数据模型
class WeatherData {
  final double temperature; // 当前温度 °C
  final double windSpeed; // 风速 km/h
  final int weatherCode; // WMO Weather interpretation code
  final String description; // 天气描述
  final double? maxTemp; // 最高温度
  final double? minTemp; // 最低温度
  final DateTime updatedAt;

  const WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
    this.maxTemp,
    this.minTemp,
    required this.updatedAt,
  });

  /// 获取天气图标
  String get iconEmoji {
    return switch (weatherCode) {
      0 => '☀️',
      1 || 2 || 3 => '🌤️',
      45 || 48 => '☁️',
      51 || 53 || 55 || 56 || 57 => '🌧️',
      61 || 63 || 65 || 66 || 67 => '🌧️',
      71 || 73 || 75 || 77 || 85 || 86 => '❄️',
      80 || 81 || 82 => '🌦️',
      95 || 96 || 99 => '⛈️',
      _ => '🌤️',
    };
  }

  /// 是否适合爬山
  bool get isGoodForHiking {
    // 不适合爬山的天气：下雨、下雪、雷暴
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99]
        .contains(weatherCode)) {
      return false;
    }
    // 风速太大也不适合
    if (windSpeed > 30) return false;
    return true;
  }

  /// 爬山建议
  String get hikingAdvice {
    if (!isGoodForHiking) {
      return '当前天气条件不太适合爬山，建议改期或选择室内活动。';
    }
    if (windSpeed > 20) {
      return '天气尚可，但风力较大，建议注意防风保暖。';
    }
    if (temperature > 30) {
      return '天气晴朗，但气温较高，建议做好防晒和补水。';
    }
    if (temperature < 5) {
      return '天气不错，但气温较低，建议携带保暖衣物。';
    }
    return '天气条件良好，非常适合爬山！';
  }
}

/// WMO 天气代码转中文描述
String weatherCodeToDescription(int code) {
  return switch (code) {
    0 => '晴朗',
    1 => '主要晴朗',
    2 => '多云',
    3 => '阴天',
    45 => '雾',
    48 => '雾凇',
    51 => '毛毛雨',
    53 => '中雨',
    55 => '大雨',
    56 => '冻雨',
    57 => '强冻雨',
    61 => '小雨',
    63 => '中雨',
    65 => '暴雨',
    66 => '冻雨',
    67 => '强冻雨',
    71 => '小雪',
    73 => '中雪',
    75 => '大雪',
    77 => '雪粒',
    80 => '阵雨',
    81 => '中度阵雨',
    82 => '强阵雨',
    85 => '阵雪',
    86 => '强阵雪',
    95 => '雷雨',
    96 => '雷伴有小冰雹',
    99 => '雷伴有大冰雹',
    _ => '未知',
  };
}
