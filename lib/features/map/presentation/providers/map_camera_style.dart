part of 'map_camera_provider.dart';

typedef _PreparedOverlaySnapshot = ({
  Object inputs,
  Map<String, String> sources,
  ForecastPalette palette,
  List<_NotamMapFeature> notams,
  List<String> activeIds,
  List<String> inactiveIds,
});

extension MapCameraStyle on MapCamera {
  /// Builds every local overlay before the native map exists. Online-only
  /// data starts empty and is filled by the existing live subscriptions.
  String prepareStyle(String baseStyle) {
    _preparedOverlayInputs = _overlayInputs();
    final overlays = _prepareOverlays();
    _preparedSourceData = {
      for (final source in overlays.sources) source.id: source.data,
    };
    _preparedForecastPalette = _forecastPalette();
    final activities = splitAirspaceActivityIds(
      refAccess.read(airspaceActivityProvider),
      clock.now(),
    );
    _preparedActiveAirspaceIds = List.of(activities.activeIds);
    _preparedInactiveAirspaceIds = List.of(activities.inactiveIds);
    final preparedStyle = overlays.embedIn(
      baseStyle,
      filters: {
        for (final id in ['active-airspaces-fill', 'active-airspaces-line'])
          id: airspaceSourceIdFilter(_preparedActiveAirspaceIds),
        for (final id in ['inactive-airspaces-fill', 'inactive-airspaces-line'])
          id: airspaceSourceIdFilter(_preparedInactiveAirspaceIds),
      },
    );
    _preparedStyles[preparedStyle] = (
      inputs: _preparedOverlayInputs!,
      sources: Map.unmodifiable(_preparedSourceData),
      palette: _preparedForecastPalette!,
      notams: List.unmodifiable(_preparedNotamFeatures),
      activeIds: List.unmodifiable(_preparedActiveAirspaceIds),
      inactiveIds: List.unmodifiable(_preparedInactiveAirspaceIds),
    );
    // The widget coalesces style requests. An evicted snapshot is safe too:
    // handleStyleLoaded performs a full catch-up rather than assuming it matches.
    while (_preparedStyles.length > 8) {
      _preparedStyles.remove(_preparedStyles.keys.first);
    }
    return preparedStyle;
  }

  Object _overlayInputs() => (
    refAccess.read(telemetryProvider),
    refAccess.read(navigationProvider).value,
    refAccess.read(favoritesProvider).value,
    refAccess.read(notamsProvider),
    refAccess.read(flightWeatherPlanProvider),
    refAccess.read(routePointWindsProvider),
    refAccess.read(displayPreferencesProvider).value,
    refAccess.read(appSettingsProvider).value,
    refAccess.read(filteredTrafficProvider),
  );

  MapOverlayStyle _prepareOverlays() {
    final telemetry = refAccess.read(telemetryProvider);
    final settings = refAccess.read(appSettingsProvider).value;
    final noticesState = refAccess.read(notamsProvider);
    final notices =
        (noticesState.hasError ? null : noticesState.value)?.notams ?? [];
    final visible = <_NotamMapFeature>[
      for (final notam in notices)
        if (notam.radius > 0)
          (
            key: notam.key,
            id: notam.id,
            title: notam.featureName.isEmpty ? notam.msg : notam.featureName,
            lat: notam.latitude,
            lon: notam.longitude,
            radius: notam.radius,
          ),
    ];
    _preparedNotamFeatures = visible;
    return MapOverlayStyle.build(
      fontScale: settings?.mapFontSize ?? 1,
      palette: _forecastPalette(),
      data: {
        'course-line-source': GeoJsonBuilder.buildCourseLineGeoJson(
          telemetry,
          settings,
        ),
        'navigation-route-source': _buildNavigationGeoJson(),
        'notams-source': _buildNotamGeoJson(visible),
        'aircraft-source': GeoJsonBuilder.buildAircraftGeoJson(
          telemetry.latitude,
          telemetry.longitude,
          telemetry.heading,
        ),
        'traffic-source': _buildTrafficGeoJson(
          refAccess.read(filteredTrafficProvider),
        ),
        'favorites-source': _buildFavoritesGeoJson(),
        forecastSource: buildFlightWeatherGeoJson(_flightWeatherInput()),
      },
    );
  }

  Future<void> handleStyleLoaded(
    StyleController style, {
    bool overlaysPrepared = false,
    String? preparedStyle,
  }) async {
    bool isCurrentStyle() =>
        refAccess.mounted && identical(style, _mapController?.style);

    if (!isCurrentStyle()) return;
    final generation = ++_styleLoadGeneration;
    final snapshot = overlaysPrepared ? _preparedStyles[preparedStyle] : null;
    final hasSnapshot = snapshot != null;
    _notamStyle = null;
    _flightWeatherStyle = null;
    try {
      if (!overlaysPrepared) {
        final overlays = _prepareOverlays();
        for (final source in overlays.sources) {
          await style.addSource(source);
          if (!isCurrentStyle()) return;
        }
        for (final layer in overlays.layers) {
          await style.addLayer(layer);
          if (!isCurrentStyle()) return;
        }
      }
      if (generation != _styleLoadGeneration || !isCurrentStyle()) return;
      final inputsChanged = !hasSnapshot || snapshot.inputs != _overlayInputs();
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
      if (inputsChanged) {
        _updateNavigationRouteOnMap(force: true);
        updateNotamsOnMap();
        updateFavoritesOnMap();
        updateTrafficOnMap();
        try {
          final telemetry = refAccess.read(telemetryProvider);
          await style.updateGeoJsonSource(
            id: 'aircraft-source',
            data: GeoJsonBuilder.buildAircraftGeoJson(
              telemetry.latitude,
              telemetry.longitude,
              telemetry.heading,
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
    }
  }

  Future<void> _updateCourseLineOnMap(String data) async {
    final style = _mapController?.style;
    if (style == null) return;

    final update = (style: style, data: data);
    if (update == _lastCourseLineUpdate) return;

    _lastCourseLineUpdate = update;
    try {
      await style.updateGeoJsonSource(id: 'course-line-source', data: data);
    } catch (_) {
      if (_lastCourseLineUpdate == update) _lastCourseLineUpdate = null;
      rethrow;
    }
  }
}
