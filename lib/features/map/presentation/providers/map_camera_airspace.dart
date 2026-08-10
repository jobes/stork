part of 'map_camera_provider.dart';

/// Keeps the real-time airspace activity (AUP/UUP) highlight layers in sync
/// with the currently active / inactive airspaces.
extension MapCameraAirspace on MapCamera {
  /// Re-applies the real-time airspace activity (AUP/UUP) highlight layers.
  ///
  /// The visual layer definitions (colors, z-order) live in
  /// `assets/openaip/styles.json` on the existing `openaip-data` source — no
  /// geometry is duplicated. This only updates their `source_id` filters for
  /// the currently active / inactive airspaces (evaluated at the current time
  /// via [splitAirspaceActivityIds]). Because the MapLibre API does not expose
  /// a `setFilter` method, the layers are removed and re-added — but only when
  /// the active/inactive id lists actually changed. The style mutation itself
  /// is delegated to [AirspaceHighlightLayers], which reads the paints back
  /// from `styles.json` so the colors live in exactly one place.
  Future<void> updateAirspacesOnMap() async {
    if (_mapController == null ||
        !_isAircraftSymbolInitialized ||
        _mapController?.style == null) {
      return;
    }

    // Serialize executions: loop until there is no in-flight highlight
    // application so concurrent airspaceActivityProvider emissions cannot
    // interleave removeLayer/addLayer mutations on the map style. The guard
    // must be re-read after each await — otherwise two calls waiting on the
    // same prior future would both resume and start new work concurrently.
    while (_airspaceHighlightInFlight != null) {
      final prior = _airspaceHighlightInFlight!;
      await prior.catchError((_) {});
    }

    final style = _mapController!.style!;
    final activities = refAccess.read(airspaceActivityProvider);

    final split = splitAirspaceActivityIds(activities, clock.now());
    final activeIds = split.activeIds;
    final inactiveIds = split.inactiveIds;

    // Nothing changed since the last application -> keep the current layers.
    if (listEquals(_lastActiveAirspaceIds, activeIds) &&
        listEquals(_lastInactiveAirspaceIds, inactiveIds)) {
      return;
    }

    final work = _applyAirspaceHighlights(
      style,
      activeIds: activeIds,
      inactiveIds: inactiveIds,
    );
    _airspaceHighlightInFlight = work;
    try {
      await work;
    } finally {
      // Clear the guard only when it still references this work, so a newer
      // execution that took over the guard is not cleared prematurely.
      if (identical(_airspaceHighlightInFlight, work)) {
        _airspaceHighlightInFlight = null;
      }
    }
  }

  /// Applies the active/inactive highlight layers to the map style and caches
  /// the applied id lists only on success, so a failed application is retried
  /// on the next call. Never throws — errors are logged via [debugPrint].
  Future<void> _applyAirspaceHighlights(
    StyleController style, {
    required List<String> activeIds,
    required List<String> inactiveIds,
  }) async {
    try {
      await AirspaceHighlightLayers().updateLayers(
        style,
        activeIds: activeIds,
        inactiveIds: inactiveIds,
      );
    } catch (e) {
      debugPrint('MapCameraAirspace: failed to apply highlight layers: $e');
      return;
    }

    // Cache only after the layers were successfully applied, so a failed
    // application is retried on the next call.
    _lastActiveAirspaceIds = List<String>.of(activeIds);
    _lastInactiveAirspaceIds = List<String>.of(inactiveIds);
  }
}
