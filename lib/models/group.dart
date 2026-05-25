class Group {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String? createdBy;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    this.createdBy,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        inviteCode: json['invite_code'] as String,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
