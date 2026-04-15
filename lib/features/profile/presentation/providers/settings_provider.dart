import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/profile/data/datasources/settings_local_datasource.dart';

/// 设置数据源 Provider
final settingsDatasourceProvider = Provider<SettingsLocalDatasource>((ref) {
  return SettingsLocalDatasource();
});

/// 主题模式 Provider
final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final datasource = ref.watch(settingsDatasourceProvider);
  final mode = await datasource.getThemeMode();
  return switch (mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
});

/// 通知开关 Provider
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final datasource = ref.watch(settingsDatasourceProvider);
  return datasource.getNotificationsEnabled();
});

/// 设置操作 Notifier
class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final SettingsLocalDatasource _datasource;

  SettingsNotifier(this._datasource) : super(const AsyncValue.data(null));

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = const AsyncValue.loading();
    try {
      await _datasource.setThemeMode(mode);
      state = const AsyncValue.data(null);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = const AsyncValue.loading();
    try {
      await _datasource.setNotificationsEnabled(enabled);
      state = const AsyncValue.data(null);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 设置操作 Provider
final settingsActionsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  final datasource = ref.watch(settingsDatasourceProvider);
  return SettingsNotifier(datasource);
});
