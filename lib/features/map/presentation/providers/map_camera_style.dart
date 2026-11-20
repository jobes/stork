part of 'map_camera_provider.dart';

extension MapCameraStyle on MapCamera {
  PreparedMapStyle prepareStyle(String baseStyle) =>
      _styleData.prepare(baseStyle);

  Future<void> handleStyleLoaded(
    StyleController style, {
    bool overlaysPrepared = false,
    PreparedMapStyle? preparedStyle,
  }) async {
    bool isCurrentStyle() =>
        refAccess.mounted && identical(style, _mapController?.style);

    if (!isCurrentStyle()) return;
    final generation = ++_styleLoadGeneration;
    final snapshot = overlaysPrepared ? preparedStyle?.snapshot : null;
    final hasSnapshot = snapshot != null;
    _notamStyle = null;
    _flightWeatherStyle = null;
    try {
      if (!overlaysPrepared) {
        final overlays = _styleData.overlays();
        for (final source in overlays.sources) {
          if (style.sources[source.id] == null) await style.sources.add(source);
          if (!isCurrentStyle()) return;
        }
        for (final layer in overlays.layers) {
          if (style.layers[layer.id] == null) await style.layers.add(layer);
          if (!isCurrentStyle()) return;
        }
      }
      if (generation != _styleLoadGeneration || !isCurrentStyle()) return;
      final inputsChanged =
          !hasSnapshot || !snapshot.matchesInputs(_styleData.inputs());
      _routeUpdateTimer?.cancel();
      _routeUpdateTimer = null;
      _routeRetryTimer?.cancel();
      _routeRetryTimer = null;
      _routeRetryAttempts = 0;
      _lastRouteUpdateTime = null;
      final route = snapshot?.sources['navigation-route-source'];
      _lastNavigationRouteUpdate = hasSnapshot && route != null
          ? (style: style, data: route)
          : null;
      final course = snapshot?.sources['course-line-source'];
      _lastCourseLineUpdate = hasSnapshot && course != null
          ? (style: style, data: course)
          : null;
      _lastFlightWeatherPalette = hasSnapshot
          ? snapshot.palette
          : overlaysPrepared
          ? null
          : _forecastPalette();
      _lastFlightWeatherGeoJson = snapshot?.sources[forecastSource];
      _flightWeatherStyle = style;
      _isAircraftSymbolInitialized = true;
      _notamStyle = style;
      _lastNotamMapFeatures = hasSnapshot ? snapshot.notams : const [];
      // The embedded snapshot already contains these sources. Only catch up
      // if data actually changed while the native view was being created.
      if (inputsChanged || _lastFlightWeatherPalette != _forecastPalette()) {
        _updateFlightWeatherOnMap();
      }
      // The prepared route may use a last-known origin that differs from live
      // telemetry even when provider inputs did not change. Identical JSON is
      // still skipped by the route writer's style/data comparison.
      _updateNavigationRouteOnMap(force: true);
      if (inputsChanged) {
        updateNotamsOnMap();
        updateFavoritesOnMap();
        updateTrafficOnMap();
        try {
          final telemetry = refAccess.read(telemetryProvider);
          await style.sources.updateGeoJsonData(
            'aircraft-source',
            GeoJsonData.text(
              GeoJsonBuilder.buildAircraftGeoJson(
                telemetry.latitude,
                telemetry.longitude,
                telemetry.heading,
              ),
            ),
          );
        } catch (error) {
          debugPrint('Could not catch up aircraft source: $error');
        }
        if (!isCurrentStyle()) return;
        try {
          // An aircraft write may have yielded while a newer sample arrived.
          final telemetry = refAccess.read(telemetryProvider);
          final settings = refAccess.read(appSettingsProvider).value;
          await _updateCourseLineOnMap(
            GeoJsonBuilder.buildCourseLineGeoJson(telemetry, settings),
          );
        } catch (error) {
          debugPrint('Could not catch up course line: $error');
        }
        if (!isCurrentStyle()) return;
      }
      // Prepared styles already have the snapshot's airspace filters.
      _lastActiveAirspaceIds = snapshot?.activeIds;
      _lastInactiveAirspaceIds = snapshot?.inactiveIds;
      await updateAirspacesOnMap();
      if (!isCurrentStyle()) return;
      _updateTrafficFilter();
      debugPrint('Aircraft symbols initialized 😎');
    } catch (e) {
      debugPrint('Error initializing native aircraft symbol: $e');
      // The initial-view gate must expose a retry if interaction setup failed.
      // Recoverable live source writes are handled by their own retry paths.
      rethrow;
    }
  }

  Future<void> _updateCourseLineOnMap(String data) async {
    final style = _mapController?.style;
    if (style == null) return;

    final update = (style: style, data: data);
    if (update == _lastCourseLineUpdate) return;

    _lastCourseLineUpdate = update;
    try {
      await style.sources.updateGeoJsonData(
        'course-line-source',
        GeoJsonData.text(data),
      );
    } catch (_) {
      if (_lastCourseLineUpdate == update) _lastCourseLineUpdate = null;
      rethrow;
    }
  }
}
