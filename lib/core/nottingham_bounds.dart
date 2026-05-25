import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Approximate Nottingham, UK bounds (locks panning to the city region).
/// Coordinates follow Mapbox / GeoJSON order: longitude, latitude.
abstract final class NottinghamBounds {
  /// South-west corner (min lng, min lat).
  static final Point southWest =
      Point(coordinates: Position(-1.26, 52.86));

  /// North-east corner (max lng, max lat).
  static final Point northEast =
      Point(coordinates: Position(-1.02, 53.02));

  static CoordinateBounds get coordinateBounds => CoordinateBounds(
        southwest: southWest,
        northeast: northEast,
        infiniteBounds: false,
      );

  static Point get center => Point(coordinates: Position(-1.157, 52.954));

  static const double defaultZoom = 12.4;
  static const double minZoom = 10;
  static const double maxZoom = 18.5;
}
