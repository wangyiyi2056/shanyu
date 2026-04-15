import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiking_assistant/features/profile/data/models/user_profile_model.dart';

/// 用户资料本地数据源
class ProfileLocalDatasource {
  static const _profileKey = 'user_profile';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<UserProfile> getProfile() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_profileKey);
    if (jsonString == null) return const UserProfile();
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } on Exception catch (_) {
      return const UserProfile();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _prefs;
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}
