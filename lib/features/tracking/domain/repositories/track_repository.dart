import 'package:hiking_assistant/features/tracking/data/datasources/track_local_datasource.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';

/// 轨迹仓储接口
abstract interface class TrackRepository {
  Future<HikingTrack> createTrack(String name);
  Future<List<HikingTrack>> getAllTracks();
  Future<HikingTrack?> getTrackById(String id);
  Future<void> updateTrack(HikingTrack track);
  Future<void> deleteTrack(String id);
  Future<void> addTrackPoint(TrackPoint point);
  Future<void> addTrackPoints(List<TrackPoint> points);
  Future<List<TrackPoint>> getTrackPoints(String trackId);
  Future<int> getTrackPointCount(String trackId);
  Future<void> clearAllTracks();
}

/// 轨迹仓储实现
class TrackRepositoryImpl implements TrackRepository {
  final TrackLocalDatasource _datasource;

  TrackRepositoryImpl(this._datasource);

  @override
  Future<HikingTrack> createTrack(String name) => _datasource.createTrack(name);

  @override
  Future<List<HikingTrack>> getAllTracks() => _datasource.getAllTracks();

  @override
  Future<HikingTrack?> getTrackById(String id) => _datasource.getTrackById(id);

  @override
  Future<void> updateTrack(HikingTrack track) => _datasource.updateTrack(track);

  @override
  Future<void> deleteTrack(String id) => _datasource.deleteTrack(id);

  @override
  Future<void> addTrackPoint(TrackPoint point) =>
      _datasource.addTrackPoint(point);

  @override
  Future<void> addTrackPoints(List<TrackPoint> points) =>
      _datasource.addTrackPoints(points);

  @override
  Future<List<TrackPoint>> getTrackPoints(String trackId) =>
      _datasource.getTrackPoints(trackId);

  @override
  Future<int> getTrackPointCount(String trackId) =>
      _datasource.getTrackPointCount(trackId);

  @override
  Future<void> clearAllTracks() => _datasource.clearAllTracks();
}
