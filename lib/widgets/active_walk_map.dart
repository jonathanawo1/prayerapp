import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../core/nottingham_bounds.dart';
import '../models/coordinate.dart';

/// Live Mapbox view for an in-progress walk (LineLayer updates).
class ActiveWalkMap extends StatefulWidget {
  const ActiveWalkMap({super.key, required this.path});

  final List<Coordinate> path;

  @override
  State<ActiveWalkMap> createState() => _ActiveWalkMapState();
}

class _ActiveWalkMapState extends State<ActiveWalkMap> {
  MapboxMap? _map;
  var _styleReady = false;

  static const _sourceId = 'active-walk-line';
  static const _layerId = 'active-walk-line-layer';

  @override
  void didUpdateWidget(covariant ActiveWalkMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path.length != widget.path.length) {
      _pushPath(followLatest: true);
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    final map = _map;
    if (map == null) return;

    await map.setBounds(
      CameraBoundsOptions(
        bounds: NottinghamBounds.coordinateBounds,
        maxZoom: NottinghamBounds.maxZoom,
        minZoom: NottinghamBounds.minZoom,
      ),
    );

    await map.style.addSource(
      GeoJsonSource(
        id: _sourceId,
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );

    await map.style.addLayer(
      LineLayer(
        id: _layerId,
        sourceId: _sourceId,
        lineJoin: LineJoin.ROUND,
        lineCap: LineCap.ROUND,
        lineColor: 0xFFFC4C02,
        lineOpacity: 1,
        lineWidth: 6,
      ),
    );

    try {
      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
        ),
      );
    } catch (e) {
      debugPrint('LocationComponentSettings: $e');
    }

    _styleReady = true;
    await _pushPath(followLatest: widget.path.length >= 2);
  }

  Future<void> _pushPath({required bool followLatest}) async {
    if (!_styleReady || _map == null || widget.path.length < 2) return;

    final coords =
        widget.path.map((c) => Position(c.longitude, c.latitude)).toList();

    final feature = Feature(
      id: 'active_walk',
      geometry: LineString(coordinates: coords),
    );

    try {
      await _map!.style.updateGeoJSONSourceFeatures(
        _sourceId,
        'active',
        [feature],
      );
    } catch (e) {
      debugPrint('ActiveWalkMap update: $e');
    }

    if (!followLatest) return;
    final last = widget.path.last;
    try {
      await _map!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(last.longitude, last.latitude)),
          zoom: 16,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 350),
      );
    } catch (e) {
      debugPrint('flyTo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('active-walk-map'),
      styleUri: 'mapbox://styles/mapbox/dark-v11',
      cameraOptions: CameraOptions(
        center: NottinghamBounds.center,
        zoom: 14,
      ),
      onMapCreated: (c) => _map = c,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }
}
