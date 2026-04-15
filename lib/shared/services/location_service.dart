import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

/// 位置服务
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// 检查位置权限
  Future<bool> checkPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// 获取当前位置
  Future<LocationResult> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        return LocationResult.fallback(
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latlng = LatLng(position.latitude, position.longitude);
      final address = await _reverseGeocode(latlng);

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } on Exception catch (_) {
      return LocationResult.fallback(
        latitude: 39.9042,
        longitude: 116.4074,
        address: '北京市',
      );
    }
  }

  /// 根据地名查找位置
  Future<LocationResult> searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationResult.success(
          latitude: location.latitude,
          longitude: location.longitude,
          address: query,
        );
      }

      return LocationResult.fallback(
        latitude: 39.9042,
        longitude: 116.4074,
        address: '北京市',
      );
    } on Exception catch (_) {
      return LocationResult.fallback(
        latitude: 39.9042,
        longitude: 116.4074,
        address: '北京市',
      );
    }
  }

  /// 逆地理编码（坐标转地址）
  Future<String> _reverseGeocode(LatLng latlng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latlng.latitude,
        latlng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        if (parts.isNotEmpty) {
          return parts.join('');
        }
      }

      return '未知位置';
    } on Exception catch (_) {
      return '未知位置';
    }
  }
}

/// 位置结果
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final bool isSuccess;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isSuccess,
  });

  factory LocationResult.success({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    return LocationResult(
      latitude: latitude,
      longitude: longitude,
      address: address,
      isSuccess: true,
    );
  }

  factory LocationResult.fallback({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    return LocationResult(
      latitude: latitude,
      longitude: longitude,
      address: address,
      isSuccess: false,
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  String toString() => '$address ($latitude, $longitude)';
}
