import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
import 'package:hiking_assistant/features/hiking/presentation/providers/route_provider.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/map_location_card.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/nearby_route_item.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/recording_status_panel.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:hiking_assistant/shared/utils/color_utils.dart';

// 默认位置（北京）
const LatLng _defaultCenter = LatLng(39.9042, 116.4074);
const double _defaultZoom = 13.0;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  // 用户位置
  LatLng? _userLocation;
  bool _locationLoaded = false;

  // 路线数据
  List<RouteRecommendation> _allRoutes = [];
  List<RouteRecommendation> _routes = [];
  bool _routesLoading = true;
  final Set<String> _selectedDifficulties = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadUserLocation();
    _loadRoutes();
  }

  Future<void> _loadUserLocation() async {
    final chatState = ref.read(chatNotifierProvider);
    final currentLocation = chatState.currentLocation;
    if (currentLocation != null) {
      final latLng = currentLocation.latLng;
      setState(() {
        _userLocation = latLng;
        _locationLoaded = true;
      });
      _mapController.move(latLng, _defaultZoom);
    }
  }

  void _loadRoutes() {
    final useCase = ref.read(routeRecommendationUseCaseProvider);
    final chatState = ref.read(chatNotifierProvider);
    // 同步加载本地数据
    final routes = useCase.getRecommendationsSync(
      preferences: RoutePreferences(
        userLatitude: chatState.currentLocation?.latitude,
        userLongitude: chatState.currentLocation?.longitude,
      ),
      limit: 8,
    );
    if (mounted) {
      setState(() {
        _allRoutes = routes;
        _applyFilter();
        _routesLoading = false;
      });
    }
  }

  void _refreshRoutes() {
    setState(() => _routesLoading = true);
    _loadRoutes();
  }

  void _applyFilter() {
    if (_selectedDifficulties.isEmpty) {
      _routes = List.from(_allRoutes);
    } else {
      _routes = _allRoutes
          .where((rec) =>
              _selectedDifficulties.contains(rec.route.difficultyLabel))
          .toList();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听位置变化
    final chatState = ref.watch(chatNotifierProvider);
    final recorderState = ref.watch(trackRecorderProvider);
    final isRecording = recorderState.status == RecordingStatus.recording;
    final isPaused = recorderState.status == RecordingStatus.paused;

    final currentLocation = chatState.currentLocation;
    final userLocation = _userLocation;
    if (currentLocation != null && !_locationLoaded) {
      final latLng = currentLocation.latLng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _userLocation = latLng;
          _locationLoaded = true;
        });
        _mapController.move(latLng, _defaultZoom);
        _refreshRoutes();
      });
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? _defaultCenter,
              initialZoom: _defaultZoom,
              onTap: (tapPosition, point) {
                _showLocationInfo(context, point);
              },
            ),
            children: [
              // 底图图层
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hiking_assistant',
                tileProvider: NetworkTileProvider(silenceExceptions: true),
              ),

              // 标记图层 - 所有路线的起点
              MarkerLayer(
                markers: [
                  // 用户位置
                  if (userLocation != null)
                    Marker(
                      point: userLocation,
                      width: 44,
                      height: 44,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 各路线的起点标记 - 山形图标
                  if (!_routesLoading)
                    ..._routes.map((rec) {
                      final waypoints = rec.route.waypoints;
                      if (waypoints.isEmpty) return null;
                      return Marker(
                        point: LatLng(
                          waypoints.first.latitude,
                          waypoints.first.longitude,
                        ),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _openRouteDetail(rec.route),
                          child: _MountainMarker(
                            color: hexToColor(rec.route.difficultyColor),
                          ),
                        ),
                      );
                    }).whereType<Marker>(),
                ],
              ),
            ],
          ),

          // 顶部渐变遮罩（增强可读性）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.paper.withValues(alpha: 0.9),
                    AppColors.paper.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 位置信息卡片
          if (currentLocation != null)
            Positioned(
              top: topPadding + AppSpacing.sm,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: MapLocationCard(
                address: currentLocation.address,
                onRefresh: () {
                  ref.read(chatNotifierProvider.notifier).refreshLocation();
                },
              ),
            ),

          // 搜索栏 - 毛玻璃效果
          Positioned(
            top: currentLocation != null
                ? topPadding + 64
                : topPadding + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    boxShadow: AppColors.softShadow(blur: 16),
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () => context.go('/chat'),
                    decoration: InputDecoration(
                      hintText: '搜索路线、地点...',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.inkMuted,
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.inkMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location,
                            color: AppColors.forest),
                        onPressed: _centerOnUserLocation,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 地图样式切换（左上角）
          Positioned(
            top: currentLocation != null
                ? topPadding + 128
                : topPadding + 72,
            left: AppSpacing.md,
            child: _GlassIconButton(
              icon: Icons.layers_outlined,
              onTap: () => _showMapStyleSelector(context),
            ),
          ),

          // 轨迹记录状态面板
          if (isRecording || isPaused)
            Positioned(
              top: currentLocation != null
                  ? topPadding + 188
                  : topPadding + 132,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: RecordingStatusPanel(
                state: recorderState,
                onPause: () =>
                    ref.read(trackRecorderProvider.notifier).pauseRecording(),
                onResume: () =>
                    ref.read(trackRecorderProvider.notifier).resumeRecording(),
              ),
            ),

          // 底部路线列表
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.14,
            maxChildSize: 0.68,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 等高线纹理装饰
                    SizedBox(
                      height: 24,
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width, 24),
                        painter: _TopographicPainter(),
                      ),
                    ),
                    // 拖动指示条
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6D3D1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Text(
                            '附近路线',
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showFilterDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paperDark,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tune,
                                    size: 14,
                                    color: AppColors.forest,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '筛选',
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.forest,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _routesLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.forest,
                              ),
                            )
                          : _routes.isEmpty
                              ? Center(
                                  child: Text(
                                    '附近暂无推荐路线',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  itemCount: _routes.length,
                                  itemBuilder: (context, index) {
                                    final rec = _routes[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: NearbyRouteItem(
                                        key: ValueKey(rec.route.id),
                                        route: rec.route,
                                        onTap: () =>
                                            _openRouteDetail(rec.route),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 自定义 FAB
          Positioned(
            right: AppSpacing.md,
            bottom: MediaQuery.of(context).size.height * 0.32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecording || isPaused)
                  FloatingActionButton.small(
                    heroTag: 'stop',
                    onPressed: () => _stopTracking(context, ref),
                    backgroundColor: AppColors.error,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.stop, color: Colors.white),
                  ),
                if (isRecording || isPaused) const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'record',
                  onPressed: () => _toggleTracking(context, ref),
                  backgroundColor:
                      isRecording ? AppColors.sun : AppColors.forest,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isRecording ? Icons.pause : Icons.play_arrow,
                    color: isRecording ? AppColors.ink : Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnUserLocation() {
    final userLocation = _userLocation;
    if (userLocation != null) {
      _mapController.move(userLocation, _defaultZoom);
    } else {
      ref.read(chatNotifierProvider.notifier).refreshLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在获取位置...')),
      );
    }
  }

  void _showMapStyleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '地图样式',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                _MapStyleTile(
                  icon: Icons.map,
                  label: '标准地图',
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1, indent: 56),
                _MapStyleTile(
                  icon: Icons.satellite,
                  label: '卫星地图',
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1, indent: 56),
                _MapStyleTile(
                  icon: Icons.terrain,
                  label: '地形图',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final difficulties = ['简单', '中等', '较难', '专家'];
          final difficultyColors = [
            AppColors.forest,
            AppColors.sun,
            AppColors.orange,
            AppColors.lavender,
          ];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppColors.softShadow(blur: 20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '筛选路线',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: difficulties.asMap().entries.map((entry) {
                          final index = entry.key;
                          final label = entry.value;
                          final isSelected =
                              _selectedDifficulties.contains(label);
                          final color = difficultyColors[index];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  _selectedDifficulties.remove(label);
                                } else {
                                  _selectedDifficulties.add(label);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.12)
                                    : AppColors.paperDark,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color:
                                      isSelected ? color : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                label,
                                style: AppTypography.label.copyWith(
                                  color: isSelected ? color : AppColors.ink,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedDifficulties.clear();
                                });
                              },
                              child: const Text('重置'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(_applyFilter);
                                Navigator.pop(context);
                              },
                              child: const Text('应用筛选'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLocationInfo(BuildContext context, LatLng point) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '位置信息',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '纬度: ${point.latitude.toStringAsFixed(6)}',
                    style: AppTypography.body,
                  ),
                  Text(
                    '经度: ${point.longitude.toStringAsFixed(6)}',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.flag),
                          label: const Text('设为终点'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.navigation),
                          label: const Text('导航'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRouteDetail(HikingRoute route) {
    context.push('/route/${route.id}', extra: route);
  }

  void _toggleTracking(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(trackRecorderProvider.notifier);
    final state = ref.read(trackRecorderProvider);

    if (state.status == RecordingStatus.idle) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text('开始轨迹记录', style: AppTypography.title),
          content: Text(
            '确定要开始记录轨迹吗？',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.startRecording();
              },
              child: const Text('开始'),
            ),
          ],
        ),
      );
    } else if (state.status == RecordingStatus.recording) {
      notifier.pauseRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('轨迹记录已暂停')),
      );
    } else if (state.status == RecordingStatus.paused) {
      notifier.resumeRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('轨迹记录已恢复')),
      );
    }
  }

  void _stopTracking(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('结束轨迹记录', style: AppTypography.title),
        content: Text(
          '确定要结束并保存这条轨迹吗？',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(trackRecorderProvider.notifier).stopRecording();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('轨迹已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _MapStyleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapStyleTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(label, style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _MountainMarker extends StatelessWidget {
  final Color color;

  const _MountainMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(24, 20),
          painter: _MountainPainter(color: color),
        ),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  final Color color;

  _MountainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // 山顶积雪
    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final snowPath = ui.Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.62, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.38, size.height * 0.45)
      ..close();

    canvas.drawPath(snowPath, snowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopographicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 4; i++) {
      final y = 6.0 + i * 5;
      final path = ui.Path();
      for (var x = 0.0; x <= size.width; x += 8) {
        final dy = y + (x % 16 < 8 ? -2 : 2);
        if (x == 0) {
          path.moveTo(x, dy);
        } else {
          path.lineTo(x, dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
