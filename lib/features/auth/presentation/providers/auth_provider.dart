import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hiking_assistant/features/auth/data/services/auth_api_service.dart';
import 'package:hiking_assistant/shared/services/api_client.dart';

/// Secure storage for auth token
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// Auth API service provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService.instance;
});

/// Auth state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserInfo user;
  final String token;

  const AuthAuthenticated(this.user, this.token);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authApi;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  AuthNotifier(this._authApi, this._storage, this._ref)
      : super(const AuthInitial());

  /// Initialize auth state from stored token
  Future<void> initialize() async {
    state = const AuthLoading();
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        _ref.read(apiClientProvider).setAuthToken(token);
        final user = await _authApi.getCurrentUser();
        if (user != null) {
          state = AuthAuthenticated(user, token);
        } else {
          // Token invalid, clear and go to unauthenticated
          await _storage.delete(key: 'auth_token');
          state = const AuthUnauthenticated();
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Sign in as guest
  Future<bool> signInAsGuest({String? name}) async {
    state = const AuthLoading();
    try {
      final result = await _authApi.signInAsGuest(name: name);
      if (result.success && result.token != null && result.user != null) {
        await _storage.write(key: 'auth_token', value: result.token!);
        state = AuthAuthenticated(result.user!, result.token!);
        return true;
      } else {
        state = AuthError(result.error ?? '登录失败');
        return false;
      }
    } catch (e) {
      state = AuthError('登录失败: $e');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle(String googleToken) async {
    state = const AuthLoading();
    try {
      final result = await _authApi.signInWithGoogle(googleToken);
      if (result.success && result.token != null && result.user != null) {
        await _storage.write(key: 'auth_token', value: result.token!);
        state = AuthAuthenticated(result.user!, result.token!);
        return true;
      } else {
        state = AuthError(result.error ?? '登录失败');
        return false;
      }
    } catch (e) {
      state = AuthError('登录失败: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _authApi.logout();
    state = const AuthUnauthenticated();
  }

  /// Check if authenticated
  bool isAuthenticated() => state is AuthAuthenticated;

  /// Get current user
  UserInfo? getCurrentUser() =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;

  /// Get current token
  String? getCurrentToken() =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).token : null;
}

/// Auth state provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.watch(authApiServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(authApi, storage, ref);
});

/// API client provider (for dependency)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

/// Whether user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Current user info
final currentUserProvider = Provider<UserInfo?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});