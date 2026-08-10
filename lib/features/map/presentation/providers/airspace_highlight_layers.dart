import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre/maplibre.dart';

/// Ids of the real-time airspace activity (AUP/UUP) highlight layers,
/// defined in `assets/openaip/styles.json` on the existing `openaip-data`
/// source (same pattern as the style's built-in `highlighted-*` layers).
const List<String> airspaceHighlightLayerIds = [
  'active-airspaces-fill',
  'active-airspaces-line',
  'inactive-airspaces-fill',
  'inactive-airspaces-line',
];

/// Parsed `assets/openaip/styles.json`, loaded lazily and cached so the AUP
/// highlight layer paints are read only once per app run.
Future<Map<String, dynamic>>? _openaipStyleJson;

Future<Map<String, dynamic>> _loadOpenAipStyleJson() {
  return _openaipStyleJson ??= () async {
    try {
      final raw = await rootBundle.loadString('assets/openaip/styles.json');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Clear the cached future so a failed load/decode can be retried on a
      // later call instead of reusing the failed future forever.
      _openaipStyleJson = null;
      rethrow;
    }
  }();
}

/// Builds a `source_id` filter matching the given openAIP airspace ids, using
/// the same pattern as the style's built-in `highlighted-*` layers. An empty
/// list matches nothing.
List<Object> airspaceSourceIdFilter(List<String> ids) {
  return [
    'all',
    [
      'in',
      ['get', 'source_id'],
      ['literal', ids],
    ],
  ];
}

/// Applies the real-time airspace activity (AUP/UUP) highlight layers to a
/// map style.
///
/// The visual layer definitions (colors, z-order) live in
/// `assets/openaip/styles.json` on the existing `openaip-data` source — no
/// geometry is duplicated. Because the MapLibre API does not expose a
/// `setFilter` method, the layers are removed and re-added with the current
/// `source_id` filters. The paint is read back from the style JSON so the
/// colors live in exactly one place.
class AirspaceHighlightLayers {
  AirspaceHighlightLayers({
    Future<Map<String, dynamic>> Function()? styleLoader,
  }) : _styleLoader = styleLoader ?? _loadOpenAipStyleJson;

  /// Loads `assets/openaip/styles.json` (injectable for tests).
  final Future<Map<String, dynamic>> Function() _styleLoader;

  /// Whether the style defines a layer with [layerId].
  static bool styleHasLayer(Map<String, dynamic> style, String layerId) {
    final layers = style['layers'];
    if (layers is! List) return false;
    for (final entry in layers) {
      if (entry is Map && entry['id'] == layerId) return true;
    }
    return false;
  }

  /// Returns the `paint` of the layer with [layerId] from [style] — the
  /// single source of truth for the AUP highlight visual properties (colors,
  /// opacity, line width). Returns `null` when the layer is not defined in
  /// the style.
  static Map<String, Object>? layerPaint(
    Map<String, dynamic> style,
    String layerId,
  ) {
    final layers = style['layers'];
    if (layers is! List) return null;
    for (final entry in layers) {
      if (entry is Map && entry['id'] == layerId) {
        final paint = entry['paint'];
        if (paint is Map) return Map<String, Object>.from(paint);
        return null;
      }
    }
    return null;
  }

  /// Removes any previously applied highlight layers. Safe to call when the
  /// layers do not exist (first call or after a style reload) — failures are
  /// ignored.
  Future<void> removeAll(StyleController style) async {
    for (final id in airspaceHighlightLayerIds) {
      try {
        await style.removeLayer(id);
      } catch (_) {}
    }
  }

  /// Re-applies the highlight layers for [activeIds] / [inactiveIds],
  /// positioned below the transparent hit-test layer (`airspace_clicktarget`)
  /// when the style defines it — otherwise the highlight layers are appended
  /// at the end of the layer stack. Layers missing from the style fall back to
  /// the MapLibre defaults (`const {}`). When both id lists are empty, all
  /// highlight layers are removed so no stale highlight remains.
  Future<void> updateLayers(
    StyleController style, {
    required List<String> activeIds,
    required List<String> inactiveIds,
  }) async {
    await removeAll(style);

    if (activeIds.isEmpty && inactiveIds.isEmpty) return;

    final styleJson = await _styleLoader();
    final below = styleHasLayer(styleJson, 'airspace_clicktarget')
        ? 'airspace_clicktarget'
        : null;
    final activeFillPaint = layerPaint(styleJson, 'active-airspaces-fill');
    final activeLinePaint = layerPaint(styleJson, 'active-airspaces-line');
    final inactiveFillPaint = layerPaint(styleJson, 'inactive-airspaces-fill');
    final inactiveLinePaint = layerPaint(styleJson, 'inactive-airspaces-line');

    await style.addLayer(
      FillStyleLayer(
        id: 'active-airspaces-fill',
        sourceId: 'openaip-data',
        sourceLayerId: 'airspaces',
        filter: airspaceSourceIdFilter(activeIds),
        paint: activeFillPaint ?? const {},
      ),
      belowLayerId: below,
    );
    await style.addLayer(
      LineStyleLayer(
        id: 'active-airspaces-line',
        sourceId: 'openaip-data',
        sourceLayerId: 'airspaces',
        filter: airspaceSourceIdFilter(activeIds),
        paint: activeLinePaint ?? const {},
      ),
      belowLayerId: below,
    );
    await style.addLayer(
      FillStyleLayer(
        id: 'inactive-airspaces-fill',
        sourceId: 'openaip-data',
        sourceLayerId: 'airspaces',
        filter: airspaceSourceIdFilter(inactiveIds),
        paint: inactiveFillPaint ?? const {},
      ),
      belowLayerId: below,
    );
    await style.addLayer(
      LineStyleLayer(
        id: 'inactive-airspaces-line',
        sourceId: 'openaip-data',
        sourceLayerId: 'airspaces',
        filter: airspaceSourceIdFilter(inactiveIds),
        paint: inactiveLinePaint ?? const {},
      ),
      belowLayerId: below,
    );
  }
}
