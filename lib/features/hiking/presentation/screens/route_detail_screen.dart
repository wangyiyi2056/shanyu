import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';

class RouteDetailScreen extends StatelessWidget {
  final HikingRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部图片区域
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                route.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Icon(
                      Icons.terrain,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 评分和位置
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${route.rating}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        ' (${route.reviewCount}条评价)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.location_on,
                          color: AppColors.textHint, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        route.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 核心数据卡片
                  _buildStatsCard(context),

                  const SizedBox(height: AppSpacing.md),

                  // 难度标签
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildTag(route.difficultyLabel,
                          _hexToColor(route.difficultyColor)),
                      ...route.tags
                          .map((tag) => _buildTag(tag, AppColors.primary)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 路线描述
                  Text(
                    '路线介绍',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    route.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 风险提示
                  if (route.warnings.isNotEmpty) ...[
                    _buildWarningsCard(context),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 最佳季节
                  _buildSeasonsCard(context),

                  const SizedBox(height: AppSpacing.lg),

                  // 路线关键点
                  Text(
                    '路线关键点',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildWaypointsList(context),

                  const SizedBox(height: AppSpacing.lg),

                  // 小地图
                  Text(
                    '路线地图',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRouteMap(context),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('收藏功能开发中')),
                    );
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('收藏'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('开始导航')),
                    );
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('开始导航'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final stats = [
      {
        'icon': Icons.straighten,
        'label': '距离',
        'value': '${route.distance} km',
      },
      {
        'icon': Icons.timer,
        'label': '预计时长',
        'value': '${route.estimatedDuration} 分钟',
      },
      {
        'icon': Icons.trending_up,
        'label': '爬升',
        'value': '${route.elevationGain} m',
      },
      {
        'icon': Icons.landscape,
        'label': '最高点',
        'value': '${route.maxElevation} m',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                children: [
                  Icon(stat['icon'] as IconData,
                      color: AppColors.primary, size: 24),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    stat['value'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    stat['label'] as String,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWarningsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '安全提示',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...route.warnings.map((warning) {
            return Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.orange.shade700)),
                  Expanded(
                    child: Text(
                      warning,
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeasonsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '最佳季节: ${route.bestSeasons.join('、')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointsList(BuildContext context) {
    return Column(
      children: route.waypoints.asMap().entries.map((entry) {
        final index = entry.key;
        final wp = entry.value;
        final isLast = index == route.waypoints.length - 1;

        IconData iconData;
        Color iconColor;
        switch (wp.type) {
          case 'start':
            iconData = Icons.play_circle;
            iconColor = AppColors.success;
          case 'end':
            iconData = Icons.flag;
            iconColor = AppColors.secondary;
          case 'viewpoint':
            iconData = Icons.photo_camera;
            iconColor = AppColors.info;
          case 'rest_area':
            iconData = Icons.chair;
            iconColor = Colors.blue;
          case 'danger':
            iconData = Icons.warning;
            iconColor = Colors.red;
          case 'landmark':
            iconData = Icons.account_balance;
            iconColor = Colors.purple;
          default:
            iconData = Icons.place;
            iconColor = AppColors.primary;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor),
                  ),
                  child: Icon(iconData, color: iconColor, size: 18),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: AppColors.textHint.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wp.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '海拔 ${wp.elevation.toStringAsFixed(0)} m',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRouteMap(BuildContext context) {
    final points = route.waypoints
        .map((wp) => LatLng(wp.latitude, wp.longitude))
        .toList();

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
                  child:
                      Icon(Icons.flag, color: AppColors.secondary, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
