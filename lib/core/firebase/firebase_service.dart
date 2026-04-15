import 'package:flutter/foundation.dart';

/// Firebase 服务（简化版，无需实际配置即可运行）
class FirebaseService {
  FirebaseService._();

  static FirebaseService get instance => FirebaseService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 演示模式：不实际初始化 Firebase
      // 实际项目中使用时，取消注释以下代码：
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );

      _isInitialized = true;
      debugPrint('[FirebaseService] Running in demo mode');
    } on Exception catch (e) {
      debugPrint('[FirebaseService] Init error: $e');
      _isInitialized = true;
    }
  }

  bool get isInitialized => _isInitialized;

  /// 是否运行在演示模式
  bool get isDemoMode => true;
}
