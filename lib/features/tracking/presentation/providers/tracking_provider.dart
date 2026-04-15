import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hiking_assistant/features/tracking/data/datasources/track_local_datasource.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/domain/repositories/track_repository.dart';

/// 轨迹本地数据源 Provider
final trackLocalDatasourceProvider = Provider<TrackLocalDatasource>((ref) {
  return TrackLocalDatasource();
});

/// 轨迹仓储 Provider
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepositoryImpl(ref.watch(trackLocalDatasourceProvider));
});

/// 所有轨迹列表
final tracksProvider = FutureProvider<List<HikingTrack>>((ref) async {
  final repository = ref.watch(trackRepositoryProvider);
  return repository.getAllTracks();
});

/// 指定轨迹详情
final trackDetailProvider =
    FutureProvider.family<(HikingTrack, List<TrackPoint>), String>(
  (ref, trackId) async {
    final repository = ref.watch(trackRepositoryProvider);
    final track = await repository.getTrackById(trackId);
    final points = await repository.getTrackPoints(trackId);
    if (track == null) {
      throw StateError('Track not found for id $trackId');
    }
    return (track, points);
  },
);

/// 记录状态
enum RecordingStatus {
  idle,
  recording,
  paused,
}

/// 记录器状态
class RecorderState {
  final RecordingStatus status;
  final HikingTrack? currentTrack;
  final List<TrackPoint> points;
  final Duration elapsed;
  final String? error;

  const RecorderState({
    this.status = RecordingStatus.idle,
    this.currentTrack,
    this.points = const [],
    this.elapsed = Duration.zero,
    this.error,
  });

  RecorderState copyWith({
    RecordingStatus? status,
    HikingTrack? currentTrack,
    List<TrackPoint>? points,
    Duration? elapsed,
    String? error,
  }) {
    return RecorderState(
      status: status ?? this.status,
      currentTrack: currentTrack,
      points: points ?? this.points,
      elapsed: elapsed ?? this.elapsed,
      error: error,
    );
  }
}

/// 轨迹记录 Notifier
class TrackRecorderNotifier extends StateNotifier<RecorderState> {
  final TrackRepository _repository;
  final Ref _ref;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _elapsedTimer;
  DateTime? _recordingStartTime;
  DateTime? _lastPointTime;
  Duration _minPointInterval = const Duration(seconds: 3);

  TrackRecorderNotifier(this._repository, this._ref)
      : super(const RecorderState());

  /// 开始记录
  Future<void> startRecording({
    String? trackName,
    Stream<Position>? positionStream,
    LocationPermission? testPermission,
    Duration? testMinPointInterval,
  }) async {
    try {
      // 检查定位权限
      final permission = testPermission ?? await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = testPermission != null
            ? LocationPermission.whileInUse
            : await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          state = state.copyWith(
            error: '需要定位权限才能记录轨迹',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          error: '定位权限已被永久拒绝，请在系统设置中开启',
        );
        return;
      }

      final name =
          trackName ?? '轨迹记录 ${DateTime.now().toString().substring(0, 16)}';
      final track = await _repository.createTrack(name);

      _recordingStartTime = DateTime.now();
      _lastPointTime = null;
      _minPointInterval = testMinPointInterval ?? const Duration(seconds: 3);

      state = RecorderState(
        status: RecordingStatus.recording,
        currentTrack: track,
        points: const [],
        elapsed: Duration.zero,
      );

      // 启动计时器
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordingStartTime != null) {
          state = state.copyWith(
            elapsed: DateTime.now().difference(_recordingStartTime!),
          );
        }
      });

      // 开始监听位置
      _positionSubscription =
          (positionStream ?? _createPositionStream()).listen(_onPositionUpdate);
    } on Exception catch (e) {
      state = state.copyWith(error: '开始记录失败: $e');
    }
  }

  Stream<Position> _createPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // 每 10 米记录一个点
      ),
    );
  }

  Future<void> _onPositionUpdate(Position position) async {
    try {
      final track = state.currentTrack;
      if (track == null || state.status != RecordingStatus.recording) return;

      // 频率限制：同步检查并立即更新时间戳，防止并发重叠
      final lastTime = _lastPointTime;
      if (lastTime != null) {
        if (DateTime.now().difference(lastTime) < _minPointInterval) {
          return;
        }
      }
      _lastPointTime = DateTime.now();

      final point = TrackPoint(
        id: '${track.id}_${DateTime.now().millisecondsSinceEpoch}',
        trackId: track.id,
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
        timestamp: DateTime.now(),
        speed: position.speed >= 0 ? position.speed : 0,
      );

      // 计算距离和海拔变化
      double newDistance = track.totalDistance;
      double newElevationGain = track.elevationGain;
      double newElevationLoss = track.elevationLoss;

      if (state.points.isNotEmpty) {
        final last = state.points.last;
        newDistance += _haversineDistance(
          last.latitude,
          last.longitude,
          point.latitude,
          point.longitude,
        );

        final lastElevation = last.elevation;
        final pointElevation = point.elevation;
        if (lastElevation != null && pointElevation != null) {
          final diff = pointElevation - lastElevation;
          if (diff > 0) {
            newElevationGain += diff;
          } else {
            newElevationLoss += diff.abs();
          }
        }
      }

      final updatedTrack = track.copyWith(
        totalDistance: newDistance,
        elevationGain: newElevationGain,
        elevationLoss: newElevationLoss,
        pointCount: track.pointCount + 1,
      );

      await _repository.addTrackPoint(point);
      await _repository.updateTrack(updatedTrack);

      state = state.copyWith(
        currentTrack: updatedTrack,
        points: [...state.points, point],
      );
    } on Exception catch (e) {
      state = state.copyWith(error: '位置更新失败: $e');
    }
  }

  /// 暂停记录
  Future<void> pauseRecording() async {
    _positionSubscription?.pause();
    _elapsedTimer?.cancel();
    state = state.copyWith(status: RecordingStatus.paused);
  }

  /// 恢复记录
  Future<void> resumeRecording() async {
    _positionSubscription?.resume();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartTime != null) {
        state = state.copyWith(
          elapsed: DateTime.now().difference(_recordingStartTime!),
        );
      }
    });
    state = state.copyWith(status: RecordingStatus.recording);
  }

  /// 停止记录
  Future<void> stopRecording() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    final track = state.currentTrack;
    if (track != null) {
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inSeconds
          : 0;

      final finalTrack = track.copyWith(
        endTime: DateTime.now(),
        durationSeconds: duration,
      );
      await _repository.updateTrack(finalTrack);
    }

    _recordingStartTime = null;
    _lastPointTime = null;

    // 刷新轨迹列表
    _ref.invalidate(tracksProvider);

    state = const RecorderState();
  }

  /// 计算两点间球面距离（米）
  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(lat1)) *
            _cos(_toRad(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;
  double _sin(double x) => sin(x);
  double _cos(double x) => cos(x);
  double _sqrt(double x) => sqrt(x);
  double _atan2(double y, double x) => atan2(y, x);

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }
}

/// 轨迹记录器 Provider
final trackRecorderProvider =
    StateNotifierProvider<TrackRecorderNotifier, RecorderState>((ref) {
  final repository = ref.watch(trackRepositoryProvider);
  return TrackRecorderNotifier(repository, ref);
});
