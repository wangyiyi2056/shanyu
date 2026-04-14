class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = '爬山助手';
  static const String appVersion = '1.0.0';

  // AI 配置
  static const int maxMessageLength = 2000;
  static const int maxConversationHistory = 50;
  static const Duration aiResponseTimeout = Duration(seconds: 30);

  // 地图配置
  static const double defaultMapZoom = 13.0;
  static const double defaultLatitude = 39.9042; // 北京
  static const double defaultLongitude = 116.4074;

  // 轨迹记录
  static const int locationUpdateInterval = 5; // 秒
  static const int minDistanceFilter = 10; // 米

  // 缓存
  static const String routesCacheKey = 'cached_routes';
  static const String userPrefsCacheKey = 'user_preferences';
  static const Duration cacheExpiry = Duration(hours: 24);
}
