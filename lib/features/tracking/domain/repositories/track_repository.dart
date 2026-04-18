import 'package:hiking_assistant/features/tracking/data/datasources/track_local_datasource.dart';
import 'package:hiking_assistant/features/tracking/data/datasources/track_api_datasource.dart';
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

/// 轨迹仓储实现 - 支持 API 和本地数据源
class TrackRepositoryImpl implements TrackRepository {
  final TrackApiDatasource _apiDatasource;
  final TrackLocalDatasource _localDatasource;

  TrackRepositoryImpl({
    required TrackApiDatasource apiDatasource,
    required TrackLocalDatasource localDatasource,
  })  : _apiDatasource = apiDatasource,
        _localDatasource = localDatasource;

  @override
  Future<HikingTrack> createTrack(String name) =>
      _localDatasource.createTrack(name);

  @override
  Future<List<HikingTrack>> getAllTracks() async {
    try {
      return await _apiDatasource.getAllTracks();
    } catch (e) {
      return await _localDatasource.getAllTracks();
    }
  }

  @override
  Future<HikingTrack?> getTrackById(String id) async {
    try {
      final result = await _apiDatasource.getPublicTrackById(id);
      if (result != null) return result.track;
    } catch (e) {
      // Fall back to local
    }
    return await _localDatasource.getTrackById(id);
  }

  @override
  Future<void> updateTrack(HikingTrack track) =>
      _localDatasource.updateTrack(track);

  @override
  Future<void> deleteTrack(String id) async {
    try {
      await _apiDatasource.deleteTrack(id);
    } catch (e) {
      // Ignore API errors for delete
    }
    await _localDatasource.deleteTrack(id);
  }

  @override
  Future<void> addTrackPoint(TrackPoint point) =>
      _localDatasource.addTrackPoint(point);

  @override
  Future<void> addTrackPoints(List<TrackPoint> points) =>
      _localDatasource.addTrackPoints(points);

  @override
  Future<List<TrackPoint>> getTrackPoints(String trackId) async {
    try {
      final result = await _apiDatasource.getPublicTrackById(trackId);
      if (result != null && result.points.isNotEmpty) return result.points;
    } catch (e) {
      // Fall back to local
    }
    return await _localDatasource.getTrackPoints(trackId);
  }

  @override
  Future<int> getTrackPointCount(String trackId) =>
      _localDatasource.getTrackPointCount(trackId);

  @override
  Future<void> clearAllTracks() => _localDatasource.clearAllTracks();
}
