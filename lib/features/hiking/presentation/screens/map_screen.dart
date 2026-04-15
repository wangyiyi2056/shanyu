import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/chat/presentation/providers/chat_provider.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/features/hiking/data/datasources/route_local_datasource.dart';
import 'package:hiking_assistant/features/hiking/domain/usecases/route_recommendation_usecase.dart';
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
    if (chatState.currentLocation != null) {
      setState(() {
        _userLocation = chatState.currentLocation!.latLng;
        _locationLoaded = true;
      });
      _mapController.move(_userLocation!, _defaultZoom);
    }
  }

  void _loadRoutes() {
    final datasource = RouteLocalDatasource();
    final useCase = RouteRecommendationUseCase(datasource);
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
          .where((rec) => _selectedDifficulties.contains(rec.route.difficultyLabel))
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

    if (chatState.currentLocation != null && !_locationLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _userLocation = chatState.currentLocation!.latLng;
          _locationLoaded = true;
        });
        _mapController.move(_userLocation!, _defaultZoom);
        _refreshRoutes();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('地图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => _showMapStyleSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
          ),
        ],
      ),
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
              ),

              // 标记图层 - 所有路线的起点
              MarkerLayer(
                markers: [
                  // 用户位置
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.info,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.info,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 各路线的起点标记
                  if (!_routesLoading)
                    ..._routes.map((rec) {
                      final waypoints = rec.route.waypoints;
                      if (waypoints.isEmpty) return null;
                      return Marker(
                        point: LatLng(
                          waypoints.first.latitude,
                          waypoints.first.longitude,
                        ),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _openRouteDetail(rec.route),
                          child: Container(
                            decoration: BoxDecoration(
                              color: hexToColor(rec.route.difficultyColor),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                rec.route.name.isEmpty
                                    ? ''
                                    : rec.route.name.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).whereType<Marker>(),
                ],
              ),
            ],
          ),

          // 位置信息卡片
          if (chatState.currentLocation != null)
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: MapLocationCard(
                address: chatState.currentLocation!.address,
                onRefresh: () {
                  ref.read(chatNotifierProvider.notifier).refreshLocation();
                },
              ),
            ),

          // 搜索栏
          Positioned(
            top: chatState.currentLocation != null ? 80 : AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                readOnly: true,
                onTap: () => context.go('/chat'),
                decoration: const InputDecoration(
                  hintText: '搜索路线、地点...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),

          // 轨迹记录状态面板
          if (isRecording || isPaused)
            Positioned(
              top: chatState.currentLocation != null ? 140 : 72,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: RecordingStatusPanel(
                state: recorderState,
                onPause: () => ref.read(trackRecorderProvider.notifier).pauseRecording(),
                onResume: () => ref.read(trackRecorderProvider.notifier).resumeRecording(),
              ),
            ),

          // 底部路线列表
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 拖动指示条
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.sm),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _showFilterDialog(context),
                            child: const Text('筛选'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _routesLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _routes.isEmpty
                              ? const Center(
                                  child: Text('附近暂无推荐路线'),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  itemCount: _routes.length,
                                  itemBuilder: (context, index) {
                                    final rec = _routes[index];
                                    return NearbyRouteItem(
                                      route: rec.route,
                                      onTap: () =>
                                          _openRouteDetail(rec.route),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording || isPaused)
            FloatingActionButton.small(
              heroTag: 'stop',
              onPressed: () => _stopTracking(context, ref),
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop, color: Colors.white),
            ),
          if (isRecording || isPaused) const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'record',
            onPressed: () => _toggleTracking(context, ref),
            backgroundColor: isRecording ? Colors.orange : AppColors.primary,
            child: Icon(
              isRecording ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, _defaultZoom);
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '地图样式',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('标准地图'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.satellite),
                title: const Text('卫星地图'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.terrain),
                title: const Text('地形图'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final difficulties = ['简单', '中等', '较难', '专家'];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '筛选路线',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: difficulties.map((label) {
                      final isSelected = _selectedDifficulties.contains(label);
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedDifficulties.add(label);
                            } else {
                              _selectedDifficulties.remove(label);
                            }
                          });
                        },
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
          );
        },
      ),
    );
  }

  void _showLocationInfo(BuildContext context, LatLng point) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '位置信息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('纬度: ${point.latitude.toStringAsFixed(6)}'),
              Text('经度: ${point.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('设为终点'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
          title: const Text('开始轨迹记录'),
          content: const Text('确定要开始记录轨迹吗？'),
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
      builder: (context) => AlertDialog(
        title: const Text('结束轨迹记录'),
        content: const Text('确定要结束并保存这条轨迹吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
