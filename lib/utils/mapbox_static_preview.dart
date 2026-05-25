import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/coordinate.dart';
import '../models/walk.dart';

/// Mapbox Static Images API — lightweight route previews for the feed.
/// See: https://docs.mapbox.com/api/maps/static-images/
@immutable
abstract final class MapboxStaticPreview {
  static const int _maxPoints = 72;

  static String? urlForWalk(Walk walk) =>
      urlForPath(walk.path, width: 800, height: 320);

  static String? urlForPath(
    List<Coordinate> path, {
    int width = 800,
    int height = 320,
  }) {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    if (token.isEmpty || path.length < 2) return null;

    final coords = _sampleCoordinates(path, _maxPoints)
        .map((c) => [c.longitude, c.latitude])
        .toList();

    final geo = jsonEncode({
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {
        'type': 'LineString',
        'coordinates': coords,
      },
    });

    final encoded = Uri.encodeComponent(geo);

    return 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/'
        'geojson($encoded)/auto/${width}x$height@2x'
        '?access_token=$token&logo=false&attribution=false';
  }

  static List<Coordinate> _sampleCoordinates(
    List<Coordinate> path,
    int maxPoints,
  ) {
    if (path.length <= maxPoints) return List<Coordinate>.from(path);
    final out = <Coordinate>[path.first];
    final step = (path.length - 1) / (maxPoints - 1);
    for (var i = 1; i < maxPoints - 1; i++) {
      final idx = (i * step).round().clamp(1, path.length - 2);
      out.add(path[idx]);
    }
    out.add(path.last);
    return out;
  }
}
