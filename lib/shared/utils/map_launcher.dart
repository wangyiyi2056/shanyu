import 'package:url_launcher/url_launcher.dart';

/// 启动外部地图导航
Future<bool> launchMapNavigation({
  required double latitude,
  required double longitude,
  String? label,
}) async {
  final query = label != null ? Uri.encodeComponent(label) : '$latitude,$longitude';

  // iOS: Apple Maps
  final appleMapsUrl = Uri.parse(
    'https://maps.apple.com/?q=$query&ll=$latitude,$longitude',
  );

  // Android / Web / Universal: Google Maps
  final googleMapsUrl = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );

  // 尝试 Apple Maps（iOS）
  if (await canLaunchUrl(appleMapsUrl)) {
    return launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
  }

  // 回退到 Google Maps
  if (await canLaunchUrl(googleMapsUrl)) {
    return launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
  }

  return false;
}
