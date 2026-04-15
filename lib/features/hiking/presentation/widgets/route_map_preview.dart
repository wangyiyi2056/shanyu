import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

class RouteMapPreview extends StatelessWidget {
  final HikingRoute route;

  const RouteMapPreview({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final points =
        route.waypoints.map((wp) => LatLng(wp.latitude, wp.longitude)).toList();

    if (points.isEmpty) return const SizedBox.shrink();

    final center = points.length > 1
        ? LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) /
                points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) /
                points.length,
          )
        : points.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.hiking_assistant',
              tileProvider: NetworkTileProvider(silenceExceptions: true),
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  color: AppColors.primary,
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: points.first,
                  width: 32,
                  height: 32,
                  child: Icon(Icons.play_circle,
                      color: AppColors.success, size: 32),
                ),
                Marker(
                  point: points.last,
                  width: 32,
                  height: 32,
                  child: Icon(Icons.flag, color: AppColors.secondary, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
