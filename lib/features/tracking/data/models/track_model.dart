/// 轨迹记录模型
class HikingTrack {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistance; // 米
  final int durationSeconds;
  final double elevationGain; // 米
  final double elevationLoss; // 米
  final int pointCount;

  const HikingTrack({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.totalDistance = 0.0,
    this.durationSeconds = 0,
    this.elevationGain = 0.0,
    this.elevationLoss = 0.0,
    this.pointCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalDistance': totalDistance,
      'durationSeconds': durationSeconds,
      'elevationGain': elevationGain,
      'elevationLoss': elevationLoss,
      'pointCount': pointCount,
    };
  }

  factory HikingTrack.fromJson(Map<String, dynamic> json) {
    return HikingTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalDistance: (json['totalDistance'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      elevationGain: (json['elevationGain'] as num).toDouble(),
      elevationLoss: (json['elevationLoss'] as num).toDouble(),
      pointCount: json['pointCount'] as int,
    );
  }

  HikingTrack copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistance,
    int? durationSeconds,
    double? elevationGain,
    double? elevationLoss,
    int? pointCount,
  }) {
    return HikingTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime,
      totalDistance: totalDistance ?? this.totalDistance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      pointCount: pointCount ?? this.pointCount,
    );
  }

  String get durationText {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  String get distanceText {
    if (totalDistance >= 1000) {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
    return '${totalDistance.toStringAsFixed(0)} m';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(startTime);
    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}周前';
    }
    return '${startTime.month}/${startTime.day}';
  }
}

/// 轨迹点模型
class TrackPoint {
  final String id;
  final String trackId;
  final double latitude;
  final double longitude;
  final double? elevation;
  final DateTime timestamp;
  final double? speed; // m/s

  const TrackPoint({
    required this.id,
    required this.trackId,
    required this.latitude,
    required this.longitude,
    this.elevation,
    required this.timestamp,
    this.speed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }

  factory TrackPoint.fromJson(Map<String, dynamic> json) {
    return TrackPoint(
      id: json['id'] as String,
      trackId: json['trackId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevation: json['elevation'] != null
          ? (json['elevation'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
    );
  }
}
