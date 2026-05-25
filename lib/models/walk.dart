import 'coordinate.dart';

class Walk {
  final String id;
  final String userId;
  final List<Coordinate> path;
  final double distance;
  final int duration;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final String? title;
  final String? prayerNotes;
  final String? groupId;
  /// Populated when the query joins `profiles(display_name)`.
  final String? displayName;

  const Walk({
    required this.id,
    required this.userId,
    required this.path,
    required this.distance,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.title,
    this.prayerNotes,
    this.groupId,
    this.displayName,
  });

  factory Walk.fromJson(Map<String, dynamic> json) {
    final path = _parsePolyline(json);

    DateTime parseTs(String key) {
      final v = json[key];
      if (v is String) return DateTime.parse(v);
      throw FormatException('Missing timestamp $key');
    }

    final created =
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now().toUtc();
    DateTime start;
    DateTime end;
    try {
      start = parseTs('start_time');
      end = parseTs('end_time');
    } catch (_) {
      end = created;
      start = created;
    }

    // Optional embedded profile join: profiles(display_name)
    final profileData = json['profiles'];
    String? displayName;
    if (profileData is Map<String, dynamic>) {
      displayName = profileData['display_name'] as String?;
    }

    return Walk(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      path: path,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      startTime: start,
      endTime: end,
      createdAt: created,
      title: json['title'] as String?,
      prayerNotes: json['prayer_notes'] as String?,
      groupId: json['group_id'] as String?,
      displayName: displayName,
    );
  }

  /// Returns a display name with safe fallback.
  String get walkerName {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (userId.length >= 6) return 'Walker ${userId.substring(0, 6)}';
    return 'Prayer Walker';
  }

  List<List<double>> toPolylineDataLatLng() =>
      path.map((c) => [c.latitude, c.longitude]).toList();
}

List<Coordinate> _parsePolyline(Map<String, dynamic> json) {
  final poly = json['polyline_data'];
  if (poly is List && poly.isNotEmpty) {
    final out = <Coordinate>[];
    for (final e in poly) {
      if (e is List && e.length >= 2) {
        out.add(Coordinate(
          latitude: (e[0] as num).toDouble(),
          longitude: (e[1] as num).toDouble(),
        ));
      } else if (e is Map<String, dynamic>) {
        out.add(Coordinate.fromJson(e));
      }
    }
    if (out.isNotEmpty) return out;
  }

  final legacyPath = json['path'];
  if (legacyPath is List) {
    return legacyPath
        .map((e) => Coordinate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  return const [];
}
