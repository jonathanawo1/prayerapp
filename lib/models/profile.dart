class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? groupId;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.groupId,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        groupId: json['group_id'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    String? groupId,
  }) =>
      Profile(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        groupId: groupId ?? this.groupId,
        createdAt: createdAt,
      );

  String get nameOrFallback => displayName?.isNotEmpty == true
      ? displayName!
      : 'Prayer Walker';

  String get initials {
    final name = nameOrFallback;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }
}
