part of 'map_camera_provider.dart';

const _forecastSource = 'flight-weather-source';
const _forecastHitLayer = 'flight-weather-hit';
const _forecastWindLayer = 'flight-weather-wind';
const _forecastLabelLayer = 'flight-weather-label';
typedef _ForecastPalette = ({
  String text,
  String halo,
  String marker,
  String waypoint,
  String sample,
});
const _forecastLight = (
  text: '#152E43',
  halo: '#FFFFFF',
  marker: '#FFFFFF',
  waypoint: '#D66900',
  sample: '#34576C',
);
const _forecastDark = (
  text: '#E4F2FC',
  halo: '#15202B',
  marker: '#203344',
  waypoint: '#FFB15C',
  sample: '#9CC9E2',
);

extension on MapCamera {
  Future<void> _addFlightWeatherLayers(
    StyleController style, {
    bool addSource = true,
  }) async {
    final palette = _forecastPalette();
    final fontScale =
        refAccess.read(appSettingsProvider).value?.mapFontSize ?? 1;
    final windArrowSize = 36.0 * fontScale;
    final windLabelSize = 15.0 * fontScale;
    final windOffsetX = 66.0 * fontScale;
    final windLabelOffsetY = 20.0 * fontScale;
    final pointArrowOffsetX = 22.0 * fontScale;
    final pointLabelOffsetX = 38.0 * fontScale;
    if (addSource) {
      await style.addSource(
        const GeoJsonSource(
          id: _forecastSource,
          data: emptyFlightWeatherGeoJson,
        ),
      );
    }
    await style.addLayer(
      const CircleStyleLayer(
        id: _forecastHitLayer,
        sourceId: _forecastSource,
        filter: ['!=', 'kind', 'aircraft'],
        paint: {'circle-radius': 14.0, 'circle-opacity': 0.0},
      ),
    );
    await style.addLayer(
      CircleStyleLayer(
        id: 'flight-weather-markers',
        sourceId: _forecastSource,
        filter: ['in', 'kind', 'waypoint', 'sample'],
        paint: {
          'circle-radius': [
            'match',
            ['get', 'kind'],
            'waypoint',
            5.0,
            3.0,
          ],
          'circle-color': palette.marker,
          'circle-stroke-color': [
            'match',
            ['get', 'kind'],
            'waypoint',
            palette.waypoint,
            palette.sample,
          ],
          'circle-stroke-width': 1.5,
        },
      ),
    );
    await style.addLayer(
      SymbolStyleLayer(
        id: 'flight-weather-point-wind',
        sourceId: _forecastSource,
        filter: ['!=', 'kind', 'aircraft'],
        layout: {
          'text-field': ['get', 'arrow'],
          'text-font': ['Roboto Regular,Noto Sans Regular'],
          'text-size': windArrowSize,
          'text-rotate': ['get', 'direction'],
          'text-rotation-alignment': 'map',
          'text-allow-overlap': true,
          'text-ignore-placement': true,
        },
        paint: {
          'text-color': palette.text,
          'text-halo-color': palette.halo,
          'text-halo-width': 2.0 * fontScale,
          'text-translate': [pointArrowOffsetX, 0.0],
          'text-translate-anchor': 'viewport',
        },
      ),
    );
    await style.addLayer(
      SymbolStyleLayer(
        id: 'flight-weather-point-label',
        sourceId: _forecastSource,
        filter: ['!=', 'kind', 'aircraft'],
        layout: {
          'text-field': ['get', 'label'],
          'text-font': ['Roboto Regular,Noto Sans Regular'],
          'text-size': windLabelSize,
          'text-anchor': 'left',
          'text-line-height': 0.95,
          'text-allow-overlap': true,
          'text-ignore-placement': true,
        },
        paint: {
          'text-color': palette.text,
          'text-halo-color': palette.halo,
          'text-halo-width': 2.0 * fontScale,
          'text-translate': [pointLabelOffsetX, 0.0],
          'text-translate-anchor': 'viewport',
        },
      ),
    );
    await style.addLayer(
      SymbolStyleLayer(
        id: _forecastWindLayer,
        sourceId: _forecastSource,
        filter: ['==', 'kind', 'aircraft'],
        layout: {
          'text-field': ['get', 'arrow'],
          'text-font': ['Roboto Regular,Noto Sans Regular'],
          'text-size': windArrowSize,
          'text-rotate': ['get', 'direction'],
          'text-rotation-alignment': 'map',
          'text-allow-overlap': true,
          'text-ignore-placement': true,
        },
        paint: {
          'text-color': palette.text,
          'text-halo-color': palette.halo,
          'text-halo-width': 2.0 * fontScale,
          // Paint translation keeps the rotated arrow in place while moving it
          // away from the aircraft; text-offset would rotate with the glyph.
          'text-translate': [windOffsetX, 0.0],
          'text-translate-anchor': 'viewport',
        },
      ),
    );
    await style.addLayer(
      SymbolStyleLayer(
        id: _forecastLabelLayer,
        sourceId: _forecastSource,
        filter: ['==', 'kind', 'aircraft'],
        layout: {
          'text-field': ['get', 'label'],
          'text-font': ['Roboto Regular,Noto Sans Regular'],
          'text-size': windLabelSize,
          'text-anchor': 'top',
          'text-line-height': 0.95,
          'text-allow-overlap': true,
          'text-ignore-placement': true,
        },
        paint: {
          'text-color': palette.text,
          'text-halo-color': palette.halo,
          'text-halo-width': 2.0 * fontScale,
          'text-translate': [windOffsetX, windLabelOffsetY],
          'text-translate-anchor': 'viewport',
        },
      ),
    );
    _lastFlightWeatherPalette = palette;
  }

  _ForecastPalette _forecastPalette() {
    final mode =
        refAccess.read(displayPreferencesProvider).value?.themeMode ??
        ThemeMode.system;
    final dark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            SchedulerBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    return dark ? _forecastDark : _forecastLight;
  }

  Future<void> _updateFlightWeatherPalette() async =>
      _updateFlightWeatherOnMap();

  Future<void> _replaceFlightWeatherPalette(StyleController style) async {
    for (final id in [
      _forecastHitLayer,
      'flight-weather-markers',
      'flight-weather-point-wind',
      'flight-weather-point-label',
      _forecastWindLayer,
      _forecastLabelLayer,
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
            await style.updateGeoJsonSource(id: _forecastSource, data: geoJson);
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
