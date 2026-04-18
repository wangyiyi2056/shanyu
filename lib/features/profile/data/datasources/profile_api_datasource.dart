import 'package:hiking_assistant/shared/services/api_client.dart';

/// Remote user profile data source
class ProfileApiDatasource {
  ProfileApiDatasource._();

  static ProfileApiDatasource get instance => ProfileApiDatasource._();

  final ApiClient _client = ApiClient.instance;

  /// Get current user profile
  Future<UserProfile?> getProfile() async {
    final response = await _client.get('/users/me');

    if (response.isSuccess && response.data != null) {
      return UserProfile.fromJson(response.data!);
    }
    return null;
  }

  /// Update profile
  Future<UserProfile?> updateProfile({String? name, String? avatarUrl}) async {
    final response = await _client.put(
      '/users/me',
      body: {'name': name, 'avatar_url': avatarUrl},
    );

    if (response.isSuccess && response.data != null) {
      return UserProfile.fromJson(response.data!);
    }
    return null;
  }

  /// Get favorite routes
  Future<List<String>> getFavorites() async {
    final response = await _client.get('/users/me/favorites');

    if (response.isSuccess && response.listData != null) {
      return response.listData!.map((r) => r['id'] as String).toList();
    }
    return [];
  }

  /// Add favorite
  Future<bool> addFavorite(String routeId) async {
    final response = await _client.post('/users/me/favorites/$routeId');
    return response.isSuccess;
  }

  /// Remove favorite
  Future<bool> removeFavorite(String routeId) async {
    final response = await _client.delete('/users/me/favorites/$routeId');
    return response.isSuccess;
  }

  /// Get achievements
  Future<List<UserAchievement>> getAchievements() async {
    final response = await _client.get('/users/me/achievements');

    if (response.isSuccess && response.listData != null) {
      return response.listData!
          .map((a) => UserAchievement.fromJson(a))
          .toList();
    }
    return [];
  }
}

/// User profile from backend
class UserProfile {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final bool isGuest;
  final DateTime createdAt;
  final int favoritesCount;
  final int tracksCount;
  final List<UserAchievement> achievements;

  const UserProfile({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    required this.isGuest,
    required this.createdAt,
    this.favoritesCount = 0,
    this.tracksCount = 0,
    this.achievements = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      favoritesCount: json['favorites_count'] as int? ?? 0,
      tracksCount: json['tracks_count'] as int? ?? 0,
      achievements: (json['achievements'] as List?)
          ?.map((a) => UserAchievement.fromJson(a))
          .toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'is_guest': isGuest,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// User achievement
class UserAchievement {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String? icon;
  final DateTime earnedAt;

  const UserAchievement({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.icon,
    required this.earnedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}