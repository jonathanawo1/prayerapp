import 'dart:math';
import '../models/coordinate.dart';

const double _earthRadiusM = 6371000;

double haversine(Coordinate a, Coordinate b) {
  final dLat = _toRad(b.latitude - a.latitude);
  final dLon = _toRad(b.longitude - a.longitude);
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final h = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  return 2 * _earthRadiusM * asin(sqrt(h));
}

double totalPathDistance(List<Coordinate> path) {
  if (path.length < 2) return 0;
  double total = 0;
  for (int i = 1; i < path.length; i++) {
    total += haversine(path[i - 1], path[i]);
  }
  return total;
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatPace(double meters, int seconds) {
  if (meters < 10) return '--:-- /km';
  final secPerKm = seconds / (meters / 1000);
  final paceMin = secPerKm ~/ 60;
  final paceSec = (secPerKm % 60).round();
  return '$paceMin:${paceSec.toString().padLeft(2, '0')} /km';
}

double _toRad(double deg) => deg * pi / 180;
