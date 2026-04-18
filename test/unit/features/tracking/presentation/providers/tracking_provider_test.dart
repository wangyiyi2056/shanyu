import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hiking_assistant/features/tracking/data/datasources/track_api_datasource.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/domain/repositories/track_repository.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

class FakeTrackApiDatasource implements TrackApiDatasource {
  final List<HikingTrack> _publicTracks = [];
  final Map<String, List<TrackPoint>> _trackPoints = {};

  void addPublicTrack(HikingTrack track) {
    _publicTracks.add(track);
  }

  void addTrackPoints(String trackId, List<TrackPoint> points) {
    _trackPoints[trackId] = points;
  }

  @override
  Future<List<HikingTrack>> getAllTracks({int limit = 20, int offset = 0}) async => [];

  @override
  Future<List<HikingTrack>> getPublicTracks({int limit = 20, int offset = 0}) async => _publicTracks;

  @override
  Future<TrackWithPoints?> getPublicTrackById(String id) async {
    final track = _publicTracks.firstWhere((t) => t.id == id, orElse: () => throw StateError('Track not found'));
    return TrackWithPoints(track: track, points: _trackPoints[id] ?? []);
  }

  @override
  Future<TrackWithPoints?> getTrackById(String id) async => null;

  @override
  Future<HikingTrack?> createTrack(HikingTrack track, List<TrackPoint> points) async => track;

  @override
  Future<bool> addPoints(String trackId, List<TrackPoint> points) async => true;

  @override
  Future<HikingTrack?> updateTrack(HikingTrack track) async => track;

  @override
  Future<bool> deleteTrack(String id) async => true;
}

class FakeTrackRepository implements TrackRepository {
  final _tracks = <String, HikingTrack>{};
  final _points = <String, List<TrackPoint>>{};

  @override
  Future<HikingTrack> createTrack(String name) async {
    final track = HikingTrack(
      id: 'track_${_tracks.length + 1}',
      name: name,
      startTime: DateTime.now(),
    );
    _tracks[track.id] = track;
    _points[track.id] = [];
    return track;
  }

  @override
  Future<List<HikingTrack>> getAllTracks() async => _tracks.values.toList();

  @override
  Future<HikingTrack?> getTrackById(String id) async => _tracks[id];

  @override
  Future<void> updateTrack(HikingTrack track) async {
    _tracks[track.id] = track;
  }

  @override
  Future<void> deleteTrack(String id) async {
    _tracks.remove(id);
    _points.remove(id);
  }

  @override
  Future<void> addTrackPoint(TrackPoint point) async {
    _points.putIfAbsent(point.trackId, () => []).add(point);
  }

  @override
  Future<void> addTrackPoints(List<TrackPoint> points) async {
    for (final point in points) {
      await addTrackPoint(point);
    }
  }

  @override
  Future<List<TrackPoint>> getTrackPoints(String trackId) async {
    return _points[trackId] ?? [];
  }

  @override
  Future<int> getTrackPointCount(String trackId) async {
    return _points[trackId]?.length ?? 0;
  }

  @override
  Future<void> clearAllTracks() async {
    _tracks.clear();
    _points.clear();
  }
}

Position _fakePosition({
  required double latitude,
  required double longitude,
  double altitude = 0,
  double speed = 0,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    altitude: altitude,
    accuracy: 1,
    heading: 0,
    speed: speed,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}

void main() {
  group('TrackRecorderNotifier', () {
    late FakeTrackRepository fakeRepository;
    late ProviderContainer container;
    StreamController<Position>? activeController;

    setUp(() {
      fakeRepository = FakeTrackRepository();
      container = ProviderContainer(
        overrides: [
          trackRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() async {
      final notifier = container.read(trackRecorderProvider.notifier);
      await notifier.stopRecording();
      await activeController?.close();
      activeController = null;
      container.dispose();
    });

    test('initial state is idle', () {
      final state = container.read(trackRecorderProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.currentTrack, isNull);
      expect(state.points, isEmpty);
      expect(state.elapsed, Duration.zero);
    });

    test('startRecording creates a track and begins recording', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        trackName: '测试轨迹',
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );

      final state = container.read(trackRecorderProvider);
      expect(state.status, RecordingStatus.recording);
      expect(state.currentTrack, isNotNull);
      expect(state.currentTrack!.name, '测试轨迹');
    });

    test('records points from position stream', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );

      activeController!.add(_fakePosition(latitude: 39.9, longitude: 116.4));
      await Future.delayed(const Duration(milliseconds: 100));

      var state = container.read(trackRecorderProvider);
      expect(state.points.length, 1);
      expect(state.points.first.latitude, 39.9);

      activeController!.add(_fakePosition(latitude: 39.91, longitude: 116.41));
      await Future.delayed(const Duration(milliseconds: 100));

      state = container.read(trackRecorderProvider);
      expect(state.points.length, 2);
    });

    test('pause stops adding points', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );
      activeController!.add(_fakePosition(latitude: 39.9, longitude: 116.4));
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.pauseRecording();
      activeController!.add(_fakePosition(latitude: 39.95, longitude: 116.45));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(trackRecorderProvider);
      expect(state.status, RecordingStatus.paused);
      expect(state.points.length, 1);
    });

    test('resume continues recording', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );
      await notifier.pauseRecording();
      await notifier.resumeRecording();

      final state = container.read(trackRecorderProvider);
      expect(state.status, RecordingStatus.recording);
    });

    test('stopRecording saves final track and resets state', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );
      final trackId = container.read(trackRecorderProvider).currentTrack!.id;

      await notifier.stopRecording();

      final state = container.read(trackRecorderProvider);
      expect(state.status, RecordingStatus.idle);
      expect(state.currentTrack, isNull);

      final tracks = await fakeRepository.getAllTracks();
      final saved = tracks.firstWhere((t) => t.id == trackId);
      expect(saved.endTime, isNotNull);
    });

    test('distance accumulates across points', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );

      // ~111km apart in latitude
      activeController!.add(_fakePosition(latitude: 0, longitude: 0));
      await Future.delayed(const Duration(milliseconds: 100));
      activeController!.add(_fakePosition(latitude: 1, longitude: 0));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(trackRecorderProvider);
      expect(state.currentTrack!.totalDistance, greaterThan(100000));
    });

    test('elevation gain and loss accumulate', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );

      activeController!.add(_fakePosition(
        latitude: 39.9,
        longitude: 116.4,
        altitude: 100,
      ));
      await Future.delayed(const Duration(milliseconds: 100));
      activeController!.add(_fakePosition(
        latitude: 39.91,
        longitude: 116.41,
        altitude: 150,
      ));
      await Future.delayed(const Duration(milliseconds: 100));
      activeController!.add(_fakePosition(
        latitude: 39.92,
        longitude: 116.42,
        altitude: 120,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(trackRecorderProvider);
      expect(state.currentTrack!.elevationGain, 50.0);
      expect(state.currentTrack!.elevationLoss, 30.0);
    });

    test('rate limits points to at least minPointInterval apart', () async {
      activeController = StreamController<Position>();
      final notifier = container.read(trackRecorderProvider.notifier);

      await notifier.startRecording(
        positionStream: activeController!.stream,
        testPermission: LocationPermission.whileInUse,
        testMinPointInterval: const Duration(milliseconds: 50),
      );

      activeController!.add(_fakePosition(latitude: 39.9, longitude: 116.4));
      activeController!.add(_fakePosition(latitude: 39.91, longitude: 116.41));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(trackRecorderProvider);
      // Second point should be ignored due to rate limit
      expect(state.points.length, 1);
    });
  });

  group('tracksProvider', () {
    test('loads tracks from API datasource', () async {
      final track1 = HikingTrack(
        id: 'track_1',
        name: '轨迹 1',
        startTime: DateTime.now(),
      );
      final track2 = HikingTrack(
        id: 'track_2',
        name: '轨迹 2',
        startTime: DateTime.now(),
      );

      final fakeApiDatasource = FakeTrackApiDatasource();
      fakeApiDatasource.addPublicTrack(track1);
      fakeApiDatasource.addPublicTrack(track2);

      final container = ProviderContainer(
        overrides: [
          trackApiDatasourceProvider.overrideWithValue(fakeApiDatasource),
        ],
      );
      addTearDown(container.dispose);

      final tracks = await container.read(tracksProvider.future);
      expect(tracks.length, 2);
    });
  });

  group('trackDetailProvider', () {
    test('loads track and points', () async {
      final fakeRepo = FakeTrackRepository();
      final track = await fakeRepo.createTrack('详情轨迹');
      await fakeRepo.addTrackPoint(TrackPoint(
        id: 'p1',
        trackId: track.id,
        latitude: 39.9,
        longitude: 116.4,
        timestamp: DateTime.now(),
      ));

      final fakeApiDatasource = FakeTrackApiDatasource();

      final container = ProviderContainer(
        overrides: [
          trackApiDatasourceProvider.overrideWithValue(fakeApiDatasource),
          trackRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final (loadedTrack, points) =
          await container.read(trackDetailProvider(track.id).future);
      expect(loadedTrack.id, track.id);
      expect(points.length, 1);
    });
  });
}
