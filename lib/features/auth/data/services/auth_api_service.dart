import 'package:hiking_assistant/shared/services/api_client.dart';

/// Remote authentication service (connects to backend)
class AuthApiService {
  AuthApiService._();

  static AuthApiService get instance => AuthApiService._();

  final ApiClient _client = ApiClient.instance;

  /// Authenticate with Google OAuth
  Future<AuthResult> signInWithGoogle(String googleToken) async {
    final response = await _client.post(
      '/auth/google',
      body: {'google_token': googleToken},
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['access_token'] as String;
      final user = _parseUser(response.data!['user']);
      _client.setAuthToken(token);
      return AuthResult.success(token, user);
    }
    return AuthResult.failure(response.error ?? 'Authentication failed');
  }

  /// Authenticate as guest
  Future<AuthResult> signInAsGuest({String? name}) async {
    final response = await _client.post(
      '/auth/guest',
      body: {'name': name ?? 'Guest'},
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['access_token'] as String;
      final user = _parseUser(response.data!['user']);
      _client.setAuthToken(token);
      return AuthResult.success(token, user);
    }
    return AuthResult.failure(response.error ?? 'Authentication failed');
  }

  /// Get current user info
  Future<UserInfo?> getCurrentUser() async {
    final response = await _client.get('/auth/me');
    if (response.isSuccess && response.data != null) {
      return _parseUser(response.data!);
    }
    return null;
  }

  /// Logout (clear token)
  void logout() {
    _client.clearAuthToken();
  }

  UserInfo _parseUser(Map<String, dynamic> data) {
    return UserInfo(
      id: data['id'] as String,
      email: data['email'] as String?,
      name: data['name'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      isGuest: data['is_guest'] as bool? ?? false,
    );
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final String? token;
  final UserInfo? user;
  final String? error;

  AuthResult.success(this.token, this.user)
      : success = true,
        error = null;
  AuthResult.failure(this.error)
      : success = false,
        token = null,
        user = null;
}

/// User info from backend
class UserInfo {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final bool isGuest;

  const UserInfo({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.isGuest = false,
  });

  String get displayName => name ?? email?.split('@').first ?? 'Guest';
}