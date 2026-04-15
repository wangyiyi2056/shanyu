import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hiking_assistant/features/profile/data/models/user_profile_model.dart';

final profileDatasourceProvider = Provider<ProfileLocalDatasource>((ref) {
  return ProfileLocalDatasource();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final datasource = ref.watch(profileDatasourceProvider);
  return datasource.getProfile();
});

final profileActionsProvider = Provider<ProfileActions>((ref) {
  final datasource = ref.watch(profileDatasourceProvider);
  return ProfileActions(datasource, ref);
});

class ProfileActions {
  final ProfileLocalDatasource _datasource;
  final Ref _ref;

  ProfileActions(this._datasource, this._ref);

  Future<void> updateProfile(UserProfile profile) async {
    await _datasource.saveProfile(profile);
    _ref.invalidate(userProfileProvider);
  }
}
