import 'coordinate.dart';

class Walk {
  final String id;
  final String userId;
  final List<Coordinate> path;
  final double distance;
  final int duration;
  final DateTime createdAt;

  const Walk({
    required this.id,
    required this.userId,
    required this.path,
    required this.distance,
    required this.duration,
    required this.createdAt,
  });

  factory Walk.fromJson(Map<String, dynamic> json) => Walk(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        path: (json['path'] as List<dynamic>)
            .map((e) => Coordinate.fromJson(e as Map<String, dynamic>))
            .toList(),
        distance: (json['distance'] as num).toDouble(),
        duration: (json['duration'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
