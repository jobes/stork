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
    if (addSource) await style.sources.add(overlays.sources.single);
    for (final layer in overlays.layers.where(
      (layer) =>
          layer is StyleLayerWithSource && layer.sourceId == forecastSource,
    )) {
      await style.layers.add(layer);
    }
    _lastFlightWeatherPalette = palette;
  }

  ForecastPalette _forecastPalette() => _styleData.forecastPalette();

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
      await style.layers.remove(id);
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
            await style.sources.updateGeoJsonData(
              forecastSource,
              GeoJsonData.text(geoJson),
            );
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

  FlightWeatherMapInput _flightWeatherInput() =>
      _styleData.flightWeatherInput();
}
