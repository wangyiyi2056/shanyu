import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 语音服务（语音输入 + 语音输出）
class SpeechService {
  SpeechService._();

  static SpeechService? _instance;
  static SpeechService get instance => _instance ??= SpeechService._();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _speechEnabled;
  String get lastWords => _lastWords;

  // 状态监听
  final _listeningController = StreamController<bool>.broadcast();
  final _speakingController = StreamController<bool>.broadcast();
  final _wordsController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get wordsStream => _wordsController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// 初始化语音服务
  Future<void> initialize() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          _isListening = false;
          _listeningController.add(false);
          _errorController.add(error.errorMsg);
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            _listeningController.add(false);
          }
        },
      );

      // 配置 TTS
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _speakingController.add(false);
        _errorController.add(msg);
      });
    } on Exception catch (e) {
      _speechEnabled = false;
      _errorController.add('语音服务初始化失败: $e');
    }
  }

  /// 开始语音识别
  Future<bool> startListening() async {
    if (!_speechEnabled) {
      await initialize();
    }

    if (!_speechEnabled) {
      _errorController.add('语音识别不可用，请检查权限');
      return false;
    }

    if (_isListening) return true;

    _lastWords = '';
    _isListening = true;
    _listeningController.add(true);

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        _wordsController.add(_lastWords);

        if (result.finalResult) {
          _isListening = false;
          _listeningController.add(false);
        }
      },
      localeId: 'zh_CN',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
    );

    return true;
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
    _listeningController.add(false);
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (!_isListening) return;
    await _speech.cancel();
    _isListening = false;
    _lastWords = '';
    _listeningController.add(false);
  }

  /// 语音合成（朗读文字）
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;

    // 如果正在说话，先停止
    if (_isSpeaking) {
      await stopSpeaking();
    }

    _isSpeaking = true;
    _speakingController.add(true);

    try {
      await _tts.speak(text);
      return true;
    } on Exception catch (e) {
      _isSpeaking = false;
      _speakingController.add(false);
      _errorController.add('语音播放失败: $e');
      return false;
    }
  }

  /// 停止语音播放
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    await _tts.stop();
    _isSpeaking = false;
    _speakingController.add(false);
  }

  /// 释放资源
  void dispose() {
    _listeningController.close();
    _speakingController.close();
    _wordsController.close();
    _errorController.close();
    _speech.cancel();
    _tts.stop();
  }
}
