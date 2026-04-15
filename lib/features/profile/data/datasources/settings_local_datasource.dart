import 'package:shared_preferences/shared_preferences.dart';

/// 设置本地数据源
class SettingsLocalDatasource {
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _notificationsKey = 'settings_notifications_enabled';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// 获取主题模式
  Future<AppThemeMode> getThemeMode() async {
    final prefs = await _prefs;
    final value = prefs.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// 获取通知开关状态
  Future<bool> getNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_notificationsKey) ?? true;
  }

  /// 设置通知开关状态
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_notificationsKey, enabled);
  }
}

enum AppThemeMode {
  system,
  light,
  dark,
}
