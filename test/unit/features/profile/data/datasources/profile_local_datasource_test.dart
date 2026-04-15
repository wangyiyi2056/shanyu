import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hiking_assistant/features/profile/data/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProfileLocalDatasource datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    datasource = ProfileLocalDatasource();
  });

  group('ProfileLocalDatasource', () {
    test('getProfile returns default profile when no data saved', () async {
      final profile = await datasource.getProfile();
      expect(profile.nickname, '爬山爱好者');
      expect(profile.levelTitle, 'Lv.1 初级选手');
      expect(profile.bio, '');
    });

    test('saveProfile persists profile data', () async {
      const profile = UserProfile(
        nickname: '登山达人',
        levelTitle: 'Lv.5 资深玩家',
        bio: '热爱大自然',
      );
      await datasource.saveProfile(profile);

      final retrieved = await datasource.getProfile();
      expect(retrieved.nickname, '登山达人');
      expect(retrieved.levelTitle, 'Lv.5 资深玩家');
      expect(retrieved.bio, '热爱大自然');
    });

    test('getProfile returns default when stored json is corrupted',
        () async {
      SharedPreferences.setMockInitialValues({
        'user_profile': 'not-valid-json',
      });
      final profile = await datasource.getProfile();
      expect(profile.nickname, '爬山爱好者');
      expect(profile.levelTitle, 'Lv.1 初级选手');
      expect(profile.bio, '');
    });

    test('getProfile handles partial json gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'user_profile': '{"nickname": "Partial"}',
      });
      final profile = await datasource.getProfile();
      expect(profile.nickname, 'Partial');
      expect(profile.levelTitle, 'Lv.1 初级选手');
      expect(profile.bio, '');
    });

    test('saveProfile overwrites existing profile', () async {
      const firstProfile = UserProfile(nickname: '第一次');
      const secondProfile = UserProfile(nickname: '第二次');

      await datasource.saveProfile(firstProfile);
      var retrieved = await datasource.getProfile();
      expect(retrieved.nickname, '第一次');

      await datasource.saveProfile(secondProfile);
      retrieved = await datasource.getProfile();
      expect(retrieved.nickname, '第二次');
    });

    test('saveProfile handles empty strings', () async {
      const profile = UserProfile(
        nickname: '',
        levelTitle: '',
        bio: '',
      );
      await datasource.saveProfile(profile);

      final retrieved = await datasource.getProfile();
      expect(retrieved.nickname, '');
      expect(retrieved.levelTitle, '');
      expect(retrieved.bio, '');
    });
  });
}
