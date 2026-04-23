import 'dart:math';

/// Geographic utility functions for distance calculations
class GeoUtils {
  GeoUtils._();

  /// Earth radius in meters
  static const double earthRadius = 6371000.0;

  /// Calculate distance between two points using Haversine formula
  ///
  /// Returns distance in meters
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRad(double degrees) => degrees * pi / 180;

  /// Convert radians to degrees
  static double toDeg(double radians) => radians * 180 / pi;

  /// Calculate bearing between two points
  /// Returns bearing in degrees (0-360)
  static double bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRad(lon2 - lon1);
    final lat1Rad = _toRad(lat1);
    final lat2Rad = _toRad(lat2);

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearingRad = atan2(y, x);
    final bearingDeg = toDeg(bearingRad);

    return (bearingDeg + 360) % 360;
  }

  /// Calculate total distance of a path
  static double pathDistance(List<(double lat, double lon)> points) {
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final (lat1, lon1) = points[i];
      final (lat2, lon2) = points[i + 1];
      total += haversineDistance(lat1, lon1, lat2, lon2);
    }
    return total;
  }

  /// Check if a point is within a given radius of another point
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusMeters,
  ) {
    return haversineDistance(lat1, lon1, lat2, lon2) <= radiusMeters;
  }
}