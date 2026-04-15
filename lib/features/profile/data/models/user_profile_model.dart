/// 用户资料数据模型
class UserProfile {
  final String nickname;
  final String levelTitle;
  final String bio;

  const UserProfile({
    this.nickname = '爬山爱好者',
    this.levelTitle = 'Lv.1 初级选手',
    this.bio = '',
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'levelTitle': levelTitle,
        'bio': bio,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'] as String? ?? '爬山爱好者',
        levelTitle: json['levelTitle'] as String? ?? 'Lv.1 初级选手',
        bio: json['bio'] as String? ?? '',
      );

  UserProfile copyWith({
    String? nickname,
    String? levelTitle,
    String? bio,
  }) =>
      UserProfile(
        nickname: nickname ?? this.nickname,
        levelTitle: levelTitle ?? this.levelTitle,
        bio: bio ?? this.bio,
      );
}
