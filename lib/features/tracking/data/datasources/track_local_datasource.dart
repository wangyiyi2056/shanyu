import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';

/// 轨迹本地数据源（SQLite）
class TrackLocalDatasource {
  static final TrackLocalDatasource _instance =
      TrackLocalDatasource._internal();
  factory TrackLocalDatasource() => _instance;
  TrackLocalDatasource._internal();

  Database? _database;

  @visibleForTesting
  Future<void> closeAndReset() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    final db = _database ??= await _initDatabase();
    return db;
  }

  Future<Database> _initDatabase() async {
    // Web 平台使用 sqflite_common_ffi_web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hiking_tracks.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tracks (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT,
            totalDistance REAL DEFAULT 0,
            durationSeconds INTEGER DEFAULT 0,
            elevationGain REAL DEFAULT 0,
            elevationLoss REAL DEFAULT 0,
            pointCount INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE track_points (
            id TEXT PRIMARY KEY,
            trackId TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            elevation REAL,
            timestamp TEXT NOT NULL,
            speed REAL,
            FOREIGN KEY (trackId) REFERENCES tracks (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_track_points_trackId ON track_points(trackId)',
        );
      },
    );
  }

  /// 创建新轨迹
  Future<HikingTrack> createTrack(String name) async {
    final db = await database;
    final track = HikingTrack(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      startTime: DateTime.now(),
    );
    await db.insert('tracks', track.toJson());
    return track;
  }

  /// 获取所有轨迹
  Future<List<HikingTrack>> getAllTracks() async {
    final db = await database;
    final maps = await db.query('tracks', orderBy: 'startTime DESC');
    return maps.map((m) => HikingTrack.fromJson(m)).toList();
  }

  /// 根据 ID 获取轨迹
  Future<HikingTrack?> getTrackById(String id) async {
    final db = await database;
    final maps = await db.query('tracks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return HikingTrack.fromJson(maps.first);
  }

  /// 更新轨迹
  Future<void> updateTrack(HikingTrack track) async {
    final db = await database;
    await db.update(
      'tracks',
      track.toJson(),
      where: 'id = ?',
      whereArgs: [track.id],
    );
  }

  /// 删除轨迹
  Future<void> deleteTrack(String id) async {
    final db = await database;
    await db.delete('tracks', where: 'id = ?', whereArgs: [id]);
  }

  /// 添加轨迹点
  Future<void> addTrackPoint(TrackPoint point) async {
    final db = await database;
    await db.insert('track_points', point.toJson());
  }

  /// 批量添加轨迹点
  Future<void> addTrackPoints(List<TrackPoint> points) async {
    final db = await database;
    final batch = db.batch();
    for (final point in points) {
      batch.insert('track_points', point.toJson());
    }
    await batch.commit(noResult: true);
  }

  /// 获取轨迹的所有点
  Future<List<TrackPoint>> getTrackPoints(String trackId) async {
    final db = await database;
    final maps = await db.query(
      'track_points',
      where: 'trackId = ?',
      whereArgs: [trackId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => TrackPoint.fromJson(m)).toList();
  }

  /// 获取轨迹点数量
  Future<int> getTrackPointCount(String trackId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM track_points WHERE trackId = ?',
      [trackId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// 清除所有轨迹数据
  Future<void> clearAllTracks() async {
    final db = await database;
    await db.delete('track_points');
    await db.delete('tracks');
  }
}
