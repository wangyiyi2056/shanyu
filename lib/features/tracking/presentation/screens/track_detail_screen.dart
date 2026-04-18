import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';
import 'dart:io';

class TrackDetailScreen extends ConsumerWidget {
  final String trackId;

  const TrackDetailScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackDetailAsync = ref.watch(trackDetailProvider(trackId));
    final trackData = trackDetailAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('轨迹详情'),
        actions: [
          if (trackData != null) ...[
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: '导出 GPX',
              onPressed: () => _exportGpx(context, trackData.$1, trackData.$2),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareTrack(context, trackData.$1),
            ),
          ],
        ],
      ),
      body: trackDetailAsync.when(
        data: (data) {
          final (track, points) = data;
          return _TrackDetailView(track: track, points: points);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败: $error'),
            ],
          ),
        ),
      ),
    );
  }

  void _shareTrack(BuildContext context, HikingTrack track) {
    final buffer = StringBuffer()
      ..writeln('我在爬山助手记录了一次徒步：')
      ..writeln('')
      ..writeln(track.name)
      ..writeln('距离：${track.distanceText}')
      ..writeln('时长：${track.durationText}')
      ..writeln('爬升：${track.elevationGain.toStringAsFixed(0)} m')
      ..writeln('日期：${_formatDate(track.startTime)}');
    Share.share(buffer.toString());
  }

  Future<void> _exportGpx(
    BuildContext context,
    HikingTrack track,
    List<TrackPoint> points,
  ) async {
    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有轨迹点数据，无法导出')),
      );
      return;
    }

    try {
      // Generate GPX content
      final gpxContent = _generateGpx(track, points);

      // Write to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = '${track.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}.gpx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(gpxContent);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '轨迹导出: ${track.name}',
        text: '这是从爬山助手导出的轨迹文件',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPX 文件已生成')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  String _generateGpx(HikingTrack track, List<TrackPoint> points) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="Hiking Assistant" ')
      ..writeln('xmlns="http://www.topografix.com/GPX/1/1" ')
      ..writeln('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ')
      ..writeln(
          'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">')
      ..writeln('  <metadata>')
      ..writeln('    <name>${_escapeXml(track.name)}</name>')
      ..writeln('    <desc>${track.distanceText}, ${track.durationText}</desc>')
      ..writeln(
          '    <time>${track.startTime.toUtc().toIso8601String()}</time>')
      ..writeln('  </metadata>')
      ..writeln('  <trk>')
      ..writeln('    <name>${_escapeXml(track.name)}</name>')
      ..writeln('    <trkseg>');

    for (final point in points) {
      buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      if (point.elevation != null) {
        buffer.writeln('        <ele>${point.elevation!.toStringAsFixed(1)}</ele>');
      }
      buffer.writeln('        <time>${point.timestamp.toUtc().toIso8601String()}</time>');
      if (point.speed != null && point.speed! > 0) {
        buffer.writeln('        <extensions>');
        buffer.writeln('          <speed>${point.speed!.toStringAsFixed(2)}</speed>');
        buffer.writeln('        </extensions>');
      }
      buffer.writeln('      </trkpt>');
    }

    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');

    return buffer.toString();
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _TrackDetailView extends StatelessWidget {
  final HikingTrack track;
  final List<TrackPoint> points;

  const _TrackDetailView({
    required this.track,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final firstElevation = points.firstOrNull?.elevation;
    final lastElevation = points.lastOrNull?.elevation;
    final endTime = track.endTime;

    return Column(
      children: [
        // 地图区域
        Expanded(
          flex: 2,
          child: _TrackMap(points: points),
        ),

        // 信息面板
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatDate(track.startTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (endTime != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '结束时间: ${_formatDate(endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _StatsGrid(track: track),
                const SizedBox(height: AppSpacing.lg),
                if (points.any((p) => p.elevation != null)) ...[
                  Text(
                    '海拔剖面',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 160,
                    child: _ElevationProfileChart(points: points),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (points.isNotEmpty) ...[
                  Text(
                    '轨迹信息',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    label: '记录点数',
                    value: '${points.length} 个点',
                  ),
                  _InfoRow(
                    label: '起点坐标',
                    value:
                        '${points.first.latitude.toStringAsFixed(4)}, ${points.first.longitude.toStringAsFixed(4)}',
                  ),
                  _InfoRow(
                    label: '终点坐标',
                    value:
                        '${points.last.latitude.toStringAsFixed(4)}, ${points.last.longitude.toStringAsFixed(4)}',
                  ),
                  if (firstElevation != null)
                    _InfoRow(
                      label: '起点海拔',
                      value: '${firstElevation.toStringAsFixed(1)} m',
                    ),
                  if (lastElevation != null)
                    _InfoRow(
                      label: '终点海拔',
                      value: '${lastElevation.toStringAsFixed(1)} m',
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackMap extends StatelessWidget {
  final List<TrackPoint> points;

  const _TrackMap({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Text('无轨迹数据'),
        ),
      );
    }

    final polylinePoints =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final center = _calculateCenter(polylinePoints);
    final zoom = _calculateZoom(polylinePoints);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
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
              points: polylinePoints,
              color: AppColors.primary,
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // 起点
            Marker(
              point: polylinePoints.first,
              width: 24,
              height: 24,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            // 终点
            Marker(
              point: polylinePoints.last,
              width: 24,
              height: 24,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  LatLng _calculateCenter(List<LatLng> points) {
    double latSum = 0;
    double lonSum = 0;
    for (final p in points) {
      latSum += p.latitude;
      lonSum += p.longitude;
    }
    return LatLng(latSum / points.length, lonSum / points.length);
  }

  double _calculateZoom(List<LatLng> points) {
    if (points.length < 2) return 15;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    if (maxDiff == 0) return 15;
    // 粗略的 zoom 估算
    return 14 - (maxDiff / 0.5).clamp(0, 8);
  }
}

class _StatsGrid extends StatelessWidget {
  final HikingTrack track;

  const _StatsGrid({required this.track});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.8,
      children: [
        _StatCard(
          icon: Icons.straighten,
          label: '总距离',
          value: track.distanceText,
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.timer,
          label: '总时长',
          value: track.durationText,
          color: AppColors.secondary,
        ),
        _StatCard(
          icon: Icons.trending_up,
          label: '累计爬升',
          value: '${track.elevationGain.toStringAsFixed(0)} m',
          color: AppColors.info,
        ),
        _StatCard(
          icon: Icons.trending_down,
          label: '累计下降',
          value: '${track.elevationLoss.toStringAsFixed(0)} m',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ElevationProfileChart extends StatelessWidget {
  final List<TrackPoint> points;

  const _ElevationProfileChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final elevationPoints = points.where((p) => p.elevation != null).toList();
    if (elevationPoints.length < 2) {
      return const Center(child: Text('海拔数据不足'));
    }

    final elevationValues =
        elevationPoints.map((p) => p.elevation).whereType<double>().toList();
    if (elevationValues.length < 2) {
      return const Center(child: Text('海拔数据不足'));
    }

    final minElevation =
        elevationValues.reduce((a, b) => a < b ? a : b);
    final maxElevation =
        elevationValues.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _ElevationProfilePainter(
                  elevations: elevationValues,
                  minElevation: minElevation,
                  maxElevation: maxElevation,
                  color: AppColors.primary,
                  fillColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最低 ${minElevation.toStringAsFixed(0)} m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  '最高 ${maxElevation.toStringAsFixed(0)} m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ElevationProfilePainter extends CustomPainter {
  final List<double> elevations;
  final double minElevation;
  final double maxElevation;
  final Color color;
  final Color fillColor;

  _ElevationProfilePainter({
    required this.elevations,
    required this.minElevation,
    required this.maxElevation,
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevations.length < 2) return;

    final padding = const EdgeInsets.only(top: 8, bottom: 4);
    final drawWidth = size.width;
    final drawHeight = size.height - padding.top - padding.bottom;
    final range = (maxElevation - minElevation).clamp(1.0, double.infinity);

    final path = ui.Path();
    final linePath = ui.Path();

    for (var i = 0; i < elevations.length; i++) {
      final x = (i / (elevations.length - 1)) * drawWidth;
      final y = padding.top +
          drawHeight -
          ((elevations[i] - minElevation) / range) * drawHeight;

      if (i == 0) {
        path.moveTo(x, size.height);
        path.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }

      if (i == elevations.length - 1) {
        path.lineTo(x, size.height);
        path.close();
      }
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
