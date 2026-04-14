/// 错误类型
enum FailureType {
  server,
  network,
  cache,
  auth,
  ai,
  location,
  unknown,
}

/// 应用失败类型
class Failure {
  final FailureType type;
  final String message;
  final int? code;

  const Failure({
    required this.type,
    required this.message,
    this.code,
  });

  const Failure.server({required String message, int? code})
      : this(type: FailureType.server, message: message, code: code);

  const Failure.network({required String message})
      : this(type: FailureType.network, message: message);

  const Failure.cache({required String message})
      : this(type: FailureType.cache, message: message);

  const Failure.auth({required String message})
      : this(type: FailureType.auth, message: message);

  const Failure.ai({required String message})
      : this(type: FailureType.ai, message: message);

  const Failure.location({required String message})
      : this(type: FailureType.location, message: message);

  const Failure.unknown({required String message})
      : this(type: FailureType.unknown, message: message);

  String get displayMessage => message;

  bool get isNetworkError => type == FailureType.network;
  bool get isAuthError => type == FailureType.auth;
}
