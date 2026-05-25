import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../core/nottingham_bounds.dart';
import '../core/theme.dart';
import '../models/walk.dart';

/// Full-screen Mapbox map displaying community prayer walk routes.
///
/// Routes are colour-coded per user using data-driven styling.
/// Pass a pre-filtered [walks] list; the widget re-renders on every change.
class CommunityWalksMap extends StatefulWidget {
  const CommunityWalksMap({
    super.key,
    required this.walks,
    this.highlightUserId,
    this.onRouteTap,
  });

  final List<Walk> walks;
  final String? highlightUserId;
  final ValueChanged<Walk>? onRouteTap;

  @override
  State<CommunityWalksMap> createState() => _CommunityWalksMapState();
}

class _CommunityWalksMapState extends State<CommunityWalksMap> {
  MapboxMap? _map;
  bool _styleReady = false;

  static const _sourceId = 'community-walks';
  static const _layerId = 'community-walks-layer';
  static const _highlightLayerId = 'community-walks-highlight';

  @override
  void didUpdateWidget(covariant CommunityWalksMap old) {
    super.didUpdateWidget(old);
    _pushWalks();
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null) return;

    await map.setBounds(
      CameraBoundsOptions(
        bounds: NottinghamBounds.coordinateBounds,
        maxZoom: NottinghamBounds.maxZoom,
        minZoom: NottinghamBounds.minZoom,
      ),
    );

    final empty = jsonEncode({'type': 'FeatureCollection', 'features': []});

    // Main source for all routes
    await map.style.addSource(GeoJsonSource(id: _sourceId, data: empty));

    // Base layer — coloured per user via data-driven expression
    await map.style.addLayer(LineLayer(
      id: _layerId,
      sourceId: _sourceId,
      lineJoin: LineJoin.ROUND,
      lineCap: LineCap.ROUND,
      lineOpacity: 0.75,
      lineWidth: 3.5,
    ));

    // Set data-driven line colour expression
    await map.style.setStyleLayerProperty(
      _layerId,
      'line-color',
      jsonEncode(['get', 'line_color']),
    );

    // Highlight layer — thicker + full opacity for selected user
    await map.style.addLayer(LineLayer(
      id: _highlightLayerId,
      sourceId: _sourceId,
      lineJoin: LineJoin.ROUND,
      lineCap: LineCap.ROUND,
      lineOpacity: 1.0,
      lineWidth: 5.5,
    ));
    await map.style.setStyleLayerProperty(
      _highlightLayerId,
      'line-color',
      jsonEncode(['get', 'line_color']),
    );
    // Only render highlight layer for the highlighted user
    await map.style.setStyleLayerProperty(
      _highlightLayerId,
      'filter',
      jsonEncode([
        '==',
        ['get', 'user_id'],
        widget.highlightUserId ?? '__none__',
      ]),
    );

    try {
      await map.location.updateSettings(LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
      ));
    } catch (_) {}

    _styleReady = true;
    await _pushWalks();
  }

  Future<void> _pushWalks() async {
    if (!_styleReady || _map == null) return;

    final features = <Map<String, dynamic>>[];
    for (final w in widget.walks) {
      if (w.path.length < 2) continue;
      final hexColor = widget.highlightUserId != null
          ? (w.userId == widget.highlightUserId
              ? AppColors.routeHexForUser(w.userId)
              : '#334155') // dim non-highlighted routes
          : AppColors.routeHexForUser(w.userId);

      features.add({
        'type': 'Feature',
        'id': w.id,
        'geometry': {
          'type': 'LineString',
          'coordinates':
              w.path.map((c) => [c.longitude, c.latitude]).toList(),
        },
        'properties': {
          'walk_id': w.id,
          'user_id': w.userId,
          'line_color': hexColor,
        },
      });
    }

    final geoJson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    try {
      await _map!.style.setStyleSourceProperty(_sourceId, 'data', geoJson);
    } catch (e) {
      debugPrint('CommunityWalksMap push: $e');
    }

    // Update highlight filter when highlightUserId changes
    try {
      await _map!.style.setStyleLayerProperty(
        _highlightLayerId,
        'filter',
        jsonEncode([
          '==',
          ['get', 'user_id'],
          widget.highlightUserId ?? '__none__',
        ]),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('community-map'),
      styleUri: 'mapbox://styles/mapbox/dark-v11',
      cameraOptions: CameraOptions(
        center: NottinghamBounds.center,
        zoom: NottinghamBounds.defaultZoom,
      ),
      onMapCreated: (c) => _map = c,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }
}
