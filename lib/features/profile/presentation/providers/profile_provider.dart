import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/auth/presentation/providers/auth_provider.dart';
import 'package:hiking_assistant/features/profile/data/datasources/profile_api_datasource.dart'
    as api;
import 'package:hiking_assistant/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hiking_assistant/features/profile/data/models/user_profile_model.dart';

/// API 数据源 Provider
final profileApiDatasourceProvider = Provider<api.ProfileApiDatasource>((ref) {
  return api.ProfileApiDatasource.instance;
});

/// 本地数据源 Provider
final profileLocalDatasourceProvider = Provider<ProfileLocalDatasource>((ref) {
  return ProfileLocalDatasource();
});

/// 用户资料仓储接口
abstract interface class ProfileRepository {
  Future<UserProfile> getProfile();
  Future<void> updateProfile(UserProfile profile);
}

/// 用户资料仓储实现 - 支持 API 和本地数据源
class ProfileRepositoryImpl implements ProfileRepository {
  final api.ProfileApiDatasource _apiDatasource;
  final ProfileLocalDatasource _localDatasource;
  final bool _isAuthenticated;

  ProfileRepositoryImpl({
    required api.ProfileApiDatasource apiDatasource,
    required ProfileLocalDatasource localDatasource,
    required bool isAuthenticated,
  })  : _apiDatasource = apiDatasource,
        _localDatasource = localDatasource,
        _isAuthenticated = isAuthenticated;

  @override
  Future<UserProfile> getProfile() async {
    if (_isAuthenticated) {
      try {
        final apiProfile = await _apiDatasource.getProfile();
        if (apiProfile != null) {
          // Map API profile to local model
          return UserProfile(
            nickname: apiProfile.name ?? '爬山爱好者',
            levelTitle: 'Lv.${_calculateLevel(apiProfile.tracksCount)} ${_getLevelTitle(apiProfile.tracksCount)}',
            bio: '',
          );
        }
      } catch (e) {
        // Fall back to local on API error
      }
    }
    return _localDatasource.getProfile();
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (_isAuthenticated) {
      try {
        await _apiDatasource.updateProfile(name: profile.nickname);
        return;
      } catch (e) {
        // Fall back to local on API error
      }
    }
    await _localDatasource.saveProfile(profile);
  }

  int _calculateLevel(int tracksCount) {
    if (tracksCount >= 50) return 5;
    if (tracksCount >= 20) return 4;
    if (tracksCount >= 10) return 3;
    if (tracksCount >= 5) return 2;
    return 1;
  }

  String _getLevelTitle(int tracksCount) {
    if (tracksCount >= 50) return '资深行者';
    if (tracksCount >= 20) return '登山达人';
    if (tracksCount >= 10) return '中级选手';
    if (tracksCount >= 5) return '初级选手';
    return '新手入门';
  }
}

/// 用户资料仓储 Provider (uses API when authenticated, local otherwise)
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authState = ref.watch(authProvider);
  final apiDatasource = ref.watch(profileApiDatasourceProvider);
  final localDatasource = ref.watch(profileLocalDatasourceProvider);

  return ProfileRepositoryImpl(
    apiDatasource: apiDatasource,
    localDatasource: localDatasource,
    isAuthenticated: authState is AuthAuthenticated,
  );
});

/// 用户资料 Provider
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});

/// 用户资料操作 Provider
final profileActionsProvider = Provider<ProfileActions>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileActions(repository, ref);
});

class ProfileActions {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileActions(this._repository, this._ref);

  Future<void> updateProfile(UserProfile profile) async {
    await _repository.updateProfile(profile);
    _ref.invalidate(userProfileProvider);
  }
}