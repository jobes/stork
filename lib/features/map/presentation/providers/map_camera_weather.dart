part of 'map_camera_provider.dart';

extension on MapCamera {
  Future<void> _addFlightWeatherLayers(
    StyleController style, {
    bool addSource = true,
  }) async {
    final palette = _forecastPalette();
    final overlays = MapOverlayStyle.build(
      data: {forecastSource: emptyFlightWeatherGeoJson},
      fontScale: refAccess.read(appSettingsProvider).value?.mapFontSize ?? 1,
      palette: palette,
    );
    if (addSource) await style.addSource(overlays.sources.single);
    for (final layer in overlays.layers.where(
      (layer) =>
          layer is StyleLayerWithSource && layer.sourceId == forecastSource,
    )) {
      await style.addLayer(layer);
    }
    _lastFlightWeatherPalette = palette;
  }

  ForecastPalette _forecastPalette() {
    final mode =
        refAccess.read(displayPreferencesProvider).value?.themeMode ??
        ThemeMode.system;
    final dark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            SchedulerBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    return dark ? forecastDark : forecastLight;
  }

  Future<void> _updateFlightWeatherPalette() async =>
      _updateFlightWeatherOnMap();

  Future<void> _replaceFlightWeatherPalette(StyleController style) async {
    for (final id in [
      forecastHitLayer,
      'flight-weather-markers',
      'flight-weather-point-wind',
      'flight-weather-point-label',
      forecastWindLayer,
      forecastLabelLayer,
    ]) {
      await style.removeLayer(id);
    }
    await _addFlightWeatherLayers(style, addSource: false);
  }

  void _updateFlightWeatherOnMap() {
    final style = _flightWeatherStyle;
    if (style == null || !identical(style, _mapController?.style)) return;
    _flightWeatherRevision++;
    if (_flightWeatherWriting || _flightWeatherWriteScheduled) return;
    _flightWeatherWriteScheduled = true;
    // The writer reads providers, which can flush dirty provider state. Keep
    // that work out of the notification stack that called this listener.
    Future.microtask(() {
      _flightWeatherWriteScheduled = false;
      if (refAccess.mounted) unawaited(_writeFlightWeatherOnMap());
    });
  }

  Future<void> _writeFlightWeatherOnMap() async {
    if (_flightWeatherWriting) return;
    _flightWeatherWriting = true;
    try {
      while (refAccess.mounted) {
        final style = _flightWeatherStyle;
        if (style == null || !identical(style, _mapController?.style)) return;
        final revision = _flightWeatherRevision;
        try {
          if (_lastFlightWeatherPalette != _forecastPalette()) {
            await _replaceFlightWeatherPalette(style);
            if (!refAccess.mounted || !identical(style, _flightWeatherStyle)) {
              continue;
            }
          }
          final input = _flightWeatherInput();
          final geoJson = input.points.isEmpty || !input.enabled
              ? emptyFlightWeatherGeoJson
              : await compute(
                  buildFlightWeatherGeoJson,
                  input,
                  debugLabel: 'Prepare flight forecast GeoJSON',
                );
          if (!refAccess.mounted) return;
          if (revision != _flightWeatherRevision ||
              !identical(style, _flightWeatherStyle) ||
              !identical(style, _mapController?.style)) {
            continue;
          }
          if (geoJson != _lastFlightWeatherGeoJson) {
            await style.updateGeoJsonSource(id: forecastSource, data: geoJson);
            if (identical(style, _flightWeatherStyle)) {
              _lastFlightWeatherGeoJson = geoJson;
            }
          }
        } catch (error) {
          debugPrint('Could not update flight forecast markers: $error');
        }
        if (revision == _flightWeatherRevision) return;
      }
    } finally {
      _flightWeatherWriting = false;
    }
  }

  FlightWeatherMapInput _flightWeatherInput() {
    final settings = refAccess.read(appSettingsProvider).value;
    final enabled = settings?.showFlightWeather ?? false;
    final points = refAccess.read(flightWeatherPlanProvider);
    final route = refAccess.read(navigationProvider).value?.points ?? [];
    final favorites = refAccess.read(favoritesProvider).value ?? [];
    final start = points.isEmpty ? null : points.first;
    final aircraftAtStart = start != null && isAircraftForecastPoint(start.id);
    if (!enabled || !aircraftAtStart) {
      return (
        enabled: enabled,
        points: points,
        route: route,
        favorites: favorites,
        winds: const {},
      );
    }
    final unit = settings?.windSpeedUnit ?? app.SpeedUnit.kmh;
    final language =
        refAccess.read(displayPreferencesProvider).value?.language ??
        AppLanguage.system;
    final l10n = lookupAppLocalizations(language.resolvedLocale);
    final unitLabel = unit.getAbbreviation(l10n);
    final pointWinds = refAccess.read(routePointWindsProvider);
    final winds = <String, ForecastWindMarker>{};
    for (final point in points) {
      final data = pointWinds[point.id];
      final isAircraft = isAircraftForecastPoint(point.id);
      if (data == null && !isAircraft) continue;
      final wind = data?.wind;
      final speed = wind == null
          ? null
          : unit.convertFromMs(wind.speedMs).round();
      final gust = data?.gustMs;
      winds[point.id] = (
        arrow: wind == null
            ? '·'
            : wind.speedMs < 0.05
            ? '○'
            : '↑',
        direction: wind == null ? 0.0 : (wind.directionFrom + 180) % 360,
        label: [
          if (speed != null) '$speed $unitLabel',
          if (gust != null)
            '${l10n.weatherGustMapLabel} ${unit.convertFromMs(gust).round()}',
        ].join('\n'),
      );
    }
    return (
      enabled: enabled,
      points: points,
      route: route,
      favorites: favorites,
      winds: winds,
    );
  }
}
