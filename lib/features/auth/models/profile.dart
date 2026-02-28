enum ProfileRole { owner, admin, user }

class Profile {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  const Profile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName:
          json['display_name'] as String? ??
          json['full_name'] as String?, // cover both cases
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }
}
