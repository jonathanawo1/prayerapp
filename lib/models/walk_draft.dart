import 'coordinate.dart';

/// Transient in-memory walk before it is saved to the backend.
class WalkDraft {
  final List<Coordinate> path;
  final double distance;
  final int duration;
  final DateTime startTime;
  final DateTime endTime;

  const WalkDraft({
    required this.path,
    required this.distance,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });
}
