import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';

import '../../../../core/utils/geo_utils.dart';
import 'airspace_highlight_layers.dart';
import 'map_overlay_style.dart';

typedef NotamMapFeature = ({
  String key,
  String id,
  String title,
  double lat,
  double lon,
  double radius,
});

@immutable
final class PreparedOverlaySnapshot {
  PreparedOverlaySnapshot({
    required Object inputs,
    required Map<String, String> sources,
    required this.palette,
    required List<NotamMapFeature> notams,
    required List<String> activeIds,
    required List<String> inactiveIds,
    // Keep the token private while accepting a public constructor argument.
    // ignore: prefer_initializing_formals
  }) : _inputs = inputs,
       sources = Map.unmodifiable(sources),
       notams = List.unmodifiable(notams),
       activeIds = List.unmodifiable(activeIds),
       inactiveIds = List.unmodifiable(inactiveIds);
  // Provider states form an opaque equality token. Only immutable rendered
  // data is exposed; callers cannot reach provider state through the snapshot.
  final Object _inputs;
  bool matchesInputs(Object inputs) => _inputs == inputs;
  final Map<String, String> sources;
  final ForecastPalette palette;
  final List<NotamMapFeature> notams;
  final List<String> activeIds;
  final List<String> inactiveIds;
}

@immutable
final class PreparedMapStyle {
  const PreparedMapStyle({required this.json, required this.snapshot});
  final String json;
  final PreparedOverlaySnapshot snapshot;
}

/// Pure style preparation: no providers, native map, clock or mutable cache.
class MapStylePreparer {
  const MapStylePreparer();

  PreparedMapStyle prepare({
    required String baseStyle,
    required Map<String, String> data,
    required double fontScale,
    required ForecastPalette palette,
    required Object inputs,
    required List<NotamMapFeature> notams,
    required List<String> activeIds,
    required List<String> inactiveIds,
  }) {
    final snapshot = PreparedOverlaySnapshot(
      inputs: inputs,
      sources: data,
      palette: palette,
      notams: notams,
      activeIds: activeIds,
      inactiveIds: inactiveIds,
    );
    final overlays = MapOverlayStyle.build(
      data: snapshot.sources,
      fontScale: fontScale,
      palette: palette,
    );
    return PreparedMapStyle(
      json: overlays.embedIn(
        baseStyle,
        filters: {
          for (final id in ['active-airspaces-fill', 'active-airspaces-line'])
            id: airspaceSourceIdFilter(snapshot.activeIds),
          for (final id in [
            'inactive-airspaces-fill',
            'inactive-airspaces-line',
          ])
            id: airspaceSourceIdFilter(snapshot.inactiveIds),
        },
      ),
      snapshot: snapshot,
    );
  }
}

String buildNotamGeoJson(List<NotamMapFeature> visible) {
  final features = <Map<String, dynamic>>[];
  for (final notam in visible) {
    final center = Geographic(lat: notam.lat, lon: notam.lon);
    const segments = 32;
    final ring = <List<double>>[];
    for (var i = 0; i < segments; i++) {
      final point = GeoUtils.calculateDestination(
        center,
        i * 360.0 / segments,
        notam.radius,
      );
      ring.add([point.lon, point.lat]);
    }
    ring.add(ring.first);

    features.add({
      'type': 'Feature',
      'id': notam.key,
      'properties': {'key': notam.key, 'id': notam.id, 'title': notam.title},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [ring],
      },
    });
  }

  return jsonEncode({'type': 'FeatureCollection', 'features': features});
}
