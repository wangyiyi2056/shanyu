import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/plant/data/services/plant_identification_service.dart';
import 'package:hiking_assistant/features/plant/domain/entities/plant_identification_result.dart';

/// 植物识别服务 Provider
final plantIdentificationServiceProvider = Provider<PlantIdentificationService>(
  (ref) => PlantIdentificationService.instance,
);

/// 植物识别状态
class PlantIdentificationState {
  final bool isLoading;
  final PlantIdentificationResult? result;
  final String? errorMessage;
  final Uint8List? selectedImageBytes;
  final String? selectedMediaType;

  const PlantIdentificationState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
    this.selectedImageBytes,
    this.selectedMediaType,
  });

  PlantIdentificationState copyWith({
    bool? isLoading,
    PlantIdentificationResult? result,
    String? errorMessage,
    Uint8List? selectedImageBytes,
    String? selectedMediaType,
  }) {
    return PlantIdentificationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedImageBytes: selectedImageBytes ?? this.selectedImageBytes,
      selectedMediaType: selectedMediaType ?? this.selectedMediaType,
    );
  }

  PlantIdentificationState clear() {
    return const PlantIdentificationState();
  }
}

/// 植物识别 Notifier
class PlantIdentificationNotifier
    extends StateNotifier<PlantIdentificationState> {
  final PlantIdentificationService _service;

  PlantIdentificationNotifier(this._service)
      : super(const PlantIdentificationState());

  /// 选择图片并识别
  Future<void> identifyFromBytes(Uint8List bytes, String mediaType) async {
    state = state.copyWith(
      isLoading: true,
      selectedImageBytes: bytes,
      selectedMediaType: mediaType,
      result: null,
      errorMessage: null,
    );

    try {
      final result = await _service.identifyFromImageBytes(bytes, mediaType);
      state = state.copyWith(
        isLoading: false,
        result: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '识别失败: $e',
      );
    }
  }

  /// 从 URL 识别
  Future<void> identifyFromUrl(String imageUrl) async {
    state = state.copyWith(
      isLoading: true,
      result: null,
      errorMessage: null,
      selectedImageBytes: null,
      selectedMediaType: null,
    );

    try {
      final result = await _service.identifyFromUrl(imageUrl);
      state = state.copyWith(
        isLoading: false,
        result: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '识别失败: $e',
      );
    }
  }

  /// 清除状态
  void clear() {
    state = state.clear();
  }

  /// 设置选中的图片（不识别）
  void setSelectedImage(Uint8List bytes, String mediaType) {
    state = state.copyWith(
      selectedImageBytes: bytes,
      selectedMediaType: mediaType,
      result: null,
      errorMessage: null,
    );
  }
}

/// 植物识别 Provider
final plantIdentificationProvider =
    StateNotifierProvider<PlantIdentificationNotifier, PlantIdentificationState>(
  (ref) {
    final service = ref.watch(plantIdentificationServiceProvider);
    return PlantIdentificationNotifier(service);
  },
);
