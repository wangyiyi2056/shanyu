import 'package:flutter/material.dart';

/// 天气数据模型
class WeatherData {
  final double temperature; // 当前温度 °C
  final double windSpeed; // 风速 km/h
  final int weatherCode; // WMO Weather interpretation code
  final String description; // 天气描述
  final double? maxTemp; // 最高温度
  final double? minTemp; // 最低温度
  final DateTime updatedAt;
  final List<DailyForecast>? forecast; // 未来几日预报

  const WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
    this.maxTemp,
    this.minTemp,
    required this.updatedAt,
    this.forecast,
  });

  /// 获取天气图标（Material 图标）
  IconData get iconData {
    return switch (weatherCode) {
      0 => Icons.wb_sunny,
      1 || 2 || 3 => Icons.wb_cloudy,
      45 || 48 => Icons.cloud,
      51 || 53 || 55 || 56 || 57 => Icons.water_drop,
      61 || 63 || 65 || 66 || 67 => Icons.water_drop,
      71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
      80 || 81 || 82 => Icons.grain,
      95 || 96 || 99 => Icons.bolt,
      _ => Icons.wb_cloudy,
    };
  }

  /// 获取天气图标颜色
  Color get iconColor {
    return switch (weatherCode) {
      0 => Colors.orange,
      1 || 2 || 3 => Colors.amber,
      45 || 48 => Colors.blueGrey,
      51 || 53 || 55 || 56 || 57 => Colors.lightBlue,
      61 || 63 || 65 || 66 || 67 => Colors.blue,
      71 || 73 || 75 || 77 || 85 || 86 => Colors.cyan,
      80 || 81 || 82 => Colors.indigo,
      95 || 96 || 99 => Colors.deepPurple,
      _ => Colors.amber,
    };
  }

  /// 是否适合爬山
  bool get isGoodForHiking {
    // 不适合爬山的天气：下雨、下雪、雷暴
    if ([
      51,
      53,
      55,
      56,
      57,
      61,
      63,
      65,
      66,
      67,
      71,
      73,
      75,
      77,
      80,
      81,
      82,
      85,
      86,
      95,
      96,
      99
    ].contains(weatherCode)) {
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

/// 每日天气预报
class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final String description;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.description,
  });

  IconData get iconData => _getIconForCode(weatherCode);

  Color get iconColor => _getColorForCode(weatherCode);

  bool get isGoodForHiking {
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99].contains(weatherCode)) {
      return false;
    }
    return true;
  }

  IconData _getIconForCode(int code) {
    return switch (code) {
      0 => Icons.wb_sunny,
      1 || 2 || 3 => Icons.wb_cloudy,
      45 || 48 => Icons.cloud,
      51 || 53 || 55 || 56 || 57 => Icons.water_drop,
      61 || 63 || 65 || 66 || 67 => Icons.water_drop,
      71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
      80 || 81 || 82 => Icons.grain,
      95 || 96 || 99 => Icons.bolt,
      _ => Icons.wb_cloudy,
    };
  }

  Color _getColorForCode(int code) {
    return switch (code) {
      0 => Colors.orange,
      1 || 2 || 3 => Colors.amber,
      45 || 48 => Colors.blueGrey,
      51 || 53 || 55 || 56 || 57 => Colors.lightBlue,
      61 || 63 || 65 || 66 || 67 => Colors.blue,
      71 || 73 || 75 || 77 || 85 || 86 => Colors.cyan,
      80 || 81 || 82 => Colors.indigo,
      95 || 96 || 99 => Colors.deepPurple,
      _ => Colors.amber,
    };
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
