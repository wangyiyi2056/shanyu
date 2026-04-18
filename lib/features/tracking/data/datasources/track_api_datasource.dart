import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/shared/services/api_client.dart';

/// Remote track data source (connects to backend)
class TrackApiDatasource {
  TrackApiDatasource._();

  static TrackApiDatasource get instance => TrackApiDatasource._();

  final ApiClient _client = ApiClient.instance;

  /// Get all user tracks
  Future<List<HikingTrack>> getAllTracks({int limit = 20, int offset = 0}) async {
    final response = await _client.get(
      '/tracks',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
    );

    if (response.isSuccess && response.listData != null) {
      return response.listData!
          .cast<Map<String, dynamic>>()
          .map(_parseTrack)
          .toList();
    }
    return [];
  }

  /// Get public tracks
  Future<List<HikingTrack>> getPublicTracks({int limit = 20, int offset = 0}) async {
    final response = await _client.get(
      '/tracks/public',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
    );

    if (response.isSuccess && response.listData != null) {
      return response.listData!
          .cast<Map<String, dynamic>>()
          .map(_parseTrack)
          .toList();
    }
    return [];
  }

  /// Get public track by ID with points (no auth required)
  Future<TrackWithPoints?> getPublicTrackById(String id) async {
    final response = await _client.get('/tracks/public/$id');

    if (response.isSuccess && response.data != null) {
      final track = _parseTrack(response.data!);
      final points = (response.data!['points'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((p) => _parsePoint(p, track.id))
          .toList() ?? [];
      return TrackWithPoints(track: track, points: points);
    }
    return null;
  }

  /// Get track by ID with points
  Future<TrackWithPoints?> getTrackById(String id) async {
    final response = await _client.get('/tracks/$id');

    if (response.isSuccess && response.data != null) {
      final track = _parseTrack(response.data!);
      final points = (response.data!['points'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((p) => _parsePoint(p, track.id))
          .toList() ?? [];
      return TrackWithPoints(track: track, points: points);
    }
    return null;
  }

  /// Create a new track
  Future<HikingTrack?> createTrack(HikingTrack track, List<TrackPoint> points) async {
    final response = await _client.post(
      '/tracks',
      body: {
        'name': track.name,
        'start_time': track.startTime.toIso8601String(),
        'end_time': track.endTime?.toIso8601String(),
        'total_distance': track.totalDistance,
        'duration_seconds': track.durationSeconds,
        'elevation_gain': track.elevationGain,
        'elevation_loss': track.elevationLoss,
        'is_public': false,
        'points': points
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                  'elevation': p.elevation,
                  'timestamp': p.timestamp.toIso8601String(),
                  'speed': p.speed,
                })
            .toList(),
      },
    );

    if (response.isSuccess && response.data != null) {
      return _parseTrack(response.data!);
    }
    return null;
  }

  /// Add points to an existing track
  Future<bool> addPoints(String trackId, List<TrackPoint> points) async {
    final response = await _client.post(
      '/tracks/$trackId/points',
      body: points
          .map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
                'elevation': p.elevation,
                'timestamp': p.timestamp.toIso8601String(),
                'speed': p.speed,
              })
          .toList(),
    );
    return response.isSuccess;
  }

  /// Update track (e.g., mark as completed)
  Future<HikingTrack?> updateTrack(HikingTrack track) async {
    final response = await _client.put(
      '/tracks/${track.id}',
      body: {
        'name': track.name,
        'end_time': track.endTime?.toIso8601String(),
        'total_distance': track.totalDistance,
        'duration_seconds': track.durationSeconds,
        'elevation_gain': track.elevationGain,
        'elevation_loss': track.elevationLoss,
      },
    );

    if (response.isSuccess && response.data != null) {
      return _parseTrack(response.data!);
    }
    return null;
  }

  /// Delete track
  Future<bool> deleteTrack(String id) async {
    final response = await _client.delete('/tracks/$id');
    return response.isSuccess;
  }

  HikingTrack _parseTrack(Map<String, dynamic> data) {
    return HikingTrack(
      id: data['id'] as String,
      name: data['name'] as String,
      startTime: DateTime.parse(data['start_time'] as String),
      endTime: data['end_time'] != null
          ? DateTime.parse(data['end_time'] as String)
          : null,
      totalDistance: (data['total_distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: data['duration_seconds'] as int? ?? 0,
      elevationGain: (data['elevation_gain'] as num?)?.toDouble() ?? 0.0,
      elevationLoss: (data['elevation_loss'] as num?)?.toDouble() ?? 0.0,
      pointCount: data['point_count'] as int? ?? 0,
    );
  }

  TrackPoint _parsePoint(Map<String, dynamic> data, String trackId) {
    return TrackPoint(
      id: data['id'] as String? ?? '',
      trackId: trackId,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      elevation: (data['elevation'] as num?)?.toDouble(),
      timestamp: DateTime.parse(data['timestamp'] as String),
      speed: (data['speed'] as num?)?.toDouble(),
    );
  }
}

/// Track with points
class TrackWithPoints {
  final HikingTrack track;
  final List<TrackPoint> points;

  const TrackWithPoints({required this.track, required this.points});
}