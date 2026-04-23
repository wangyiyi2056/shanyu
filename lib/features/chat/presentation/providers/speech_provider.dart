import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/chat/data/services/speech_service.dart';

/// 语音服务 Provider
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService.instance;
  service.initialize();
  return service;
});

/// 语音状态
class SpeechState {
  final bool isListening;
  final bool isSpeaking;
  final bool isAvailable;
  final String recognizedWords;
  final String? error;

  const SpeechState({
    this.isListening = false,
    this.isSpeaking = false,
    this.isAvailable = false,
    this.recognizedWords = '',
    this.error,
  });

  SpeechState copyWith({
    bool? isListening,
    bool? isSpeaking,
    bool? isAvailable,
    String? recognizedWords,
    String? error,
  }) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      error: error ?? this.error,
    );
  }
}

/// 语音 Notifier
class SpeechNotifier extends StateNotifier<SpeechState> {
  final SpeechService _service;

  SpeechNotifier(this._service) : super(const SpeechState()) {
    _initListeners();
  }

  void _initListeners() {
    _service.listeningStream.listen((listening) {
      state = state.copyWith(isListening: listening);
    });

    _service.speakingStream.listen((speaking) {
      state = state.copyWith(isSpeaking: speaking);
    });

    _service.wordsStream.listen((words) {
      state = state.copyWith(recognizedWords: words);
    });

    _service.errorStream.listen((error) {
      state = state.copyWith(error: error);
    });

    // 初始化完成后更新可用状态
    _service.initialize().then((_) {
      state = state.copyWith(isAvailable: _service.isAvailable);
    });
  }

  /// 开始语音识别
  Future<bool> startListening() async {
    state = state.copyWith(recognizedWords: '', error: null);
    return _service.startListening();
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    await _service.stopListening();
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    await _service.cancelListening();
  }

  /// 播放语音
  Future<bool> speak(String text) async {
    state = state.copyWith(error: null);
    return _service.speak(text);
  }

  /// 停止播放
  Future<void> stopSpeaking() async {
    await _service.stopSpeaking();
  }

  /// 切换听写状态
  Future<void> toggleListening() async {
    if (state.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }
}

/// 语音 Provider
final speechNotifierProvider =
    StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  final service = ref.watch(speechServiceProvider);
  return SpeechNotifier(service);
});
