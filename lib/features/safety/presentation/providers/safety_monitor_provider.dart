import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/safety/data/services/safety_analysis_service.dart';
import 'package:hiking_assistant/features/safety/domain/entities/safety_alert.dart';
import 'package:hiking_assistant/features/weather/data/services/weather_api_service.dart';

/// 安全分析服务 Provider
final safetyAnalysisServiceProvider = Provider<SafetyAnalysisService>((ref) {
  final claudeAPI = ref.watch(claudeAPIServiceProvider);
  return SafetyAnalysisService(claudeAPI: claudeAPI);
});

/// 安全监控状态
class SafetyMonitorState {
  final List<SafetyAlert> alerts;
  final SafetyAlert? currentAlert;
  final bool isAnalyzing;
  final SafetyLevel overallLevel;

  const SafetyMonitorState({
    this.alerts = const [],
    this.currentAlert,
    this.isAnalyzing = false,
    this.overallLevel = SafetyLevel.safe,
  });

  SafetyMonitorState copyWith({
    List<SafetyAlert>? alerts,
    SafetyAlert? currentAlert,
    bool? isAnalyzing,
    SafetyLevel? overallLevel,
  }) {
    return SafetyMonitorState(
      alerts: alerts ?? this.alerts,
      currentAlert: currentAlert ?? this.currentAlert,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      overallLevel: overallLevel ?? this.overallLevel,
    );
  }

  /// 未读警报数量
  int get unreadCount => alerts.where((a) => !a.isRead).length;

  /// 是否有紧急警报
  bool get hasEmergency =>
      alerts.any((a) => a.level == SafetyLevel.emergency);

  /// 计算整体安全等级
  static SafetyLevel _calculateOverallLevel(List<SafetyAlert> alerts) {
    if (alerts.isEmpty) return SafetyLevel.safe;
    final levels = alerts.map((a) => a.level).toList();
    if (levels.contains(SafetyLevel.emergency)) return SafetyLevel.emergency;
    if (levels.contains(SafetyLevel.danger)) return SafetyLevel.danger;
    if (levels.contains(SafetyLevel.warning)) return SafetyLevel.warning;
    if (levels.contains(SafetyLevel.caution)) return SafetyLevel.caution;
    return SafetyLevel.safe;
  }
}

/// 安全监控 Notifier
class SafetyMonitorNotifier extends StateNotifier<SafetyMonitorState> {
  final SafetyAnalysisService _analysisService;
  final WeatherApiService _weatherService;

  SafetyMonitorNotifier(this._analysisService, this._weatherService)
      : super(const SafetyMonitorState());

  /// 分析用户消息的安全风险
  Future<SafetyAnalysisResult> analyzeUserMessage(
    String message, {
    String? weatherContext,
    String? locationContext,
    bool isTracking = false,
  }) async {
    state = state.copyWith(isAnalyzing: true);

    try {
      final result = await _analysisService.analyzeMessageSafety(
        message,
        weatherContext: weatherContext,
        locationContext: locationContext,
        isTracking: isTracking,
      );

      // 如果有建议的警报，添加到列表
      if (result.suggestedAlerts.isNotEmpty) {
        final newAlerts = [...state.alerts, ...result.suggestedAlerts];
        state = state.copyWith(
          alerts: newAlerts,
          isAnalyzing: false,
          overallLevel: SafetyMonitorState._calculateOverallLevel(newAlerts),
        );
      } else {
        state = state.copyWith(isAnalyzing: false);
      }

      return result;
    } on Exception catch (_) {
      state = state.copyWith(isAnalyzing: false);
      return SafetyAnalysisResult.safe();
    }
  }

  /// 检查天气预警
  Future<void> checkWeatherAlert(double lat, double lon) async {
    try {
      final weather = await _weatherService.getWeather(lat, lon);
      final alert = _analysisService.generateWeatherAlert(
        weather.description,
        weather.temperature,
        weather.windSpeed,
      );

      if (alert != null) {
        // 避免重复添加相同类型的天气预警（最近1小时内）
        final recentWeatherAlert = state.alerts.any((a) {
          if (a.type != SafetyAlertType.weatherAlert) return false;
          final age = DateTime.now().difference(a.createdAt);
          return age.inMinutes < 60;
        });

        if (!recentWeatherAlert) {
          final newAlerts = [...state.alerts, alert];
          state = state.copyWith(
            alerts: newAlerts,
            currentAlert: alert,
            overallLevel: SafetyMonitorState._calculateOverallLevel(newAlerts),
          );
        }
      }
    } on Exception catch (_) {
      // 天气检查失败，静默处理
    }
  }

  /// 添加自定义警报
  void addAlert(SafetyAlert alert) {
    final newAlerts = [...state.alerts, alert];
    state = state.copyWith(
      alerts: newAlerts,
      currentAlert: alert,
      overallLevel: SafetyMonitorState._calculateOverallLevel(newAlerts),
    );
  }

  /// 标记警报为已读
  void markAlertAsRead(String alertId) {
    final newAlerts = state.alerts.map((alert) {
      if (alert.id == alertId) {
        return alert.copyWith(isRead: true);
      }
      return alert;
    }).toList();

    state = state.copyWith(
      alerts: newAlerts,
      overallLevel: SafetyMonitorState._calculateOverallLevel(newAlerts),
    );
  }

  /// 清除所有警报
  void clearAlerts() {
    state = const SafetyMonitorState();
  }

  /// 清除单个警报
  void removeAlert(String alertId) {
    final newAlerts = state.alerts.where((a) => a.id != alertId).toList();
    state = state.copyWith(
      alerts: newAlerts,
      overallLevel: SafetyMonitorState._calculateOverallLevel(newAlerts),
    );
  }

  /// 关闭当前弹窗警报
  void dismissCurrentAlert() {
    state = state.copyWith(currentAlert: null);
  }
}

/// 安全监控 Provider
final safetyMonitorProvider =
    StateNotifierProvider<SafetyMonitorNotifier, SafetyMonitorState>((ref) {
  final analysisService = ref.watch(safetyAnalysisServiceProvider);
  final weatherService = ref.watch(weatherApiServiceProvider);
  return SafetyMonitorNotifier(analysisService, weatherService);
});
