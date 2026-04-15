import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hiking_assistant/features/tracking/data/datasources/track_local_datasource.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';

void main() {
  late TrackLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    datasource = TrackLocalDatasource();
    await datasource.closeAndReset();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hiking_tracks.db');
    if (File(path).existsSync()) {
      await File(path).delete();
    }
  });

  tearDown(() async {
    await datasource.closeAndReset();
  });

  group('TrackLocalDatasource', () {
    test('creates and retrieves a track', () async {
      final track = await datasource.createTrack('测试轨迹');
      expect(track.name, '测试轨迹');
      expect(track.totalDistance, 0.0);
      expect(track.pointCount, 0);

      final retrieved = await datasource.getTrackById(track.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, '测试轨迹');
    });

    test('returns all tracks ordered by startTime desc', () async {
      await datasource.createTrack('轨迹 A');
      await Future.delayed(const Duration(milliseconds: 10));
      await datasource.createTrack('轨迹 B');

      final tracks = await datasource.getAllTracks();
      expect(tracks.length, 2);
      expect(tracks.first.name, '轨迹 B');
      expect(tracks.last.name, '轨迹 A');
    });

    test('updates a track', () async {
      final track = await datasource.createTrack('原始名称');
      final updated = track.copyWith(
        name: '更新名称',
        totalDistance: 1500.0,
        pointCount: 10,
      );

      await datasource.updateTrack(updated);
      final retrieved = await datasource.getTrackById(track.id);
      expect(retrieved!.name, '更新名称');
      expect(retrieved.totalDistance, 1500.0);
      expect(retrieved.pointCount, 10);
    });

    test('deletes a track and cascades points', () async {
      final track = await datasource.createTrack('待删除');
      await datasource.addTrackPoint(TrackPoint(
        id: 'p1',
        trackId: track.id,
        latitude: 39.9,
        longitude: 116.4,
        timestamp: DateTime.now(),
      ));

      await datasource.deleteTrack(track.id);
      final retrieved = await datasource.getTrackById(track.id);
      expect(retrieved, isNull);

      final points = await datasource.getTrackPoints(track.id);
      expect(points, isEmpty);
    });

    test('adds and retrieves track points', () async {
      final track = await datasource.createTrack('轨迹');
      final point1 = TrackPoint(
        id: 'p1',
        trackId: track.id,
        latitude: 39.9,
        longitude: 116.4,
        elevation: 100.0,
        timestamp: DateTime(2024, 1, 1, 10, 0),
        speed: 1.5,
      );
      final point2 = TrackPoint(
        id: 'p2',
        trackId: track.id,
        latitude: 39.91,
        longitude: 116.41,
        timestamp: DateTime(2024, 1, 1, 10, 5),
      );

      await datasource.addTrackPoint(point1);
      await datasource.addTrackPoint(point2);

      final points = await datasource.getTrackPoints(track.id);
      expect(points.length, 2);
      expect(points.first.latitude, 39.9);
      expect(points.first.elevation, 100.0);
      expect(points.first.speed, 1.5);
      expect(points.last.latitude, 39.91);
    });

    test('adds track points in batch', () async {
      final track = await datasource.createTrack('批量轨迹');
      final points = [
        TrackPoint(
          id: 'bp1',
          trackId: track.id,
          latitude: 39.1,
          longitude: 116.1,
          timestamp: DateTime.now(),
        ),
        TrackPoint(
          id: 'bp2',
          trackId: track.id,
          latitude: 39.2,
          longitude: 116.2,
          timestamp: DateTime.now(),
        ),
      ];

      await datasource.addTrackPoints(points);
      final retrieved = await datasource.getTrackPoints(track.id);
      expect(retrieved.length, 2);
    });

    test('returns correct track point count', () async {
      final track = await datasource.createTrack('计数轨迹');
      expect(await datasource.getTrackPointCount(track.id), 0);

      await datasource.addTrackPoint(TrackPoint(
        id: 'c1',
        trackId: track.id,
        latitude: 39.0,
        longitude: 116.0,
        timestamp: DateTime.now(),
      ));
      expect(await datasource.getTrackPointCount(track.id), 1);
    });

    test('only returns points for specified track', () async {
      final trackA = await datasource.createTrack('轨迹 A');
      final trackB = await datasource.createTrack('轨迹 B');

      await datasource.addTrackPoint(TrackPoint(
        id: 'a1',
        trackId: trackA.id,
        latitude: 39.0,
        longitude: 116.0,
        timestamp: DateTime.now(),
      ));
      await datasource.addTrackPoint(TrackPoint(
        id: 'b1',
        trackId: trackB.id,
        latitude: 40.0,
        longitude: 117.0,
        timestamp: DateTime.now(),
      ));

      final pointsA = await datasource.getTrackPoints(trackA.id);
      expect(pointsA.length, 1);
      expect(pointsA.first.id, 'a1');
    });
  });
}
