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
    _lastActiveAirspaceIds = List<String>.of(activeIds);
    _lastInactiveAirspaceIds = List<String>.of(inactiveIds);

    try {
      await AirspaceHighlightLayers().updateLayers(
        style,
        activeIds: activeIds,
        inactiveIds: inactiveIds,
      );
    } catch (e) {
      debugPrint(
        'AirspaceActivityController: failed to apply highlight layers: $e',
      );
    }
  }
}
