part of 'map_camera_provider.dart';

const _forecastSource = 'flight-weather-source';
const _forecastHitLayer = 'flight-weather-hit';
const _forecastWindLayer = 'flight-weather-wind';
const _forecastLabelLayer = 'flight-weather-label';
const _emptyForecastGeoJson = '{"type":"FeatureCollection","features":[]}';
// MapLibre paint values use the map style palette, like the other camera
// layers; the white halo keeps the labels readable on light and dark styles.
const _forecastTextColor = '#152E43';
const _forecastHaloColor = '#FFFFFF';
const _forecastMarkerColor = '#FFFFFF';
const _forecastWaypointColor = '#D66900';
const _forecastSampleColor = '#34576C';

typedef _WindMarker = ({String arrow, double direction, String label});

typedef _ForecastMapInput = ({
  bool enabled,
  List<ForecastRoutePoint> points,
  List<NavigationPoint> route,
  List<FavoritePoint> favorites,
  Map<String, _WindMarker> winds,
});

String _buildFlightWeatherGeoJson(_ForecastMapInput input) {
  final favoriteIds = input.favorites.map((point) => point.id).toSet();
  final favoriteLocations = input.favorites
      .map((point) => (point.latitude, point.longitude))
      .toSet();
  final features = <Map<String, Object?>>[];
  for (final point in input.points) {
    final index = point.waypointIndex;
    final waypoint = index != null && index < input.route.length
        ? input.route[index]
        : null;
    final String kind;
    if (waypoint != null) {
      final mapped =
          waypoint.isAirport ||
          favoriteIds.contains(waypoint.favoriteId) ||
          favoriteLocations.contains((waypoint.latitude, waypoint.longitude));
      kind = mapped ? 'mapped' : 'waypoint';
    } else {
      if (!input.enabled) continue;
      kind = isAircraftForecastPoint(point.id) ? 'aircraft' : 'sample';
    }
    final wind = input.winds[point.id];
    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [point.location.longitude, point.location.latitude],
      },
      'properties': {
        'forecastId': point.id,
        'kind': kind,
        if (wind != null) ...{
          'arrow': wind.arrow,
          'direction': wind.direction,
          'label': wind.label,
        },
      },
    });
  }
  return jsonEncode({'type': 'FeatureCollection', 'features': features});
}

extension on MapCamera {
  Future<void> _addFlightWeatherLayers(StyleController style) async {
    final fontScale =
        refAccess.read(appSettingsProvider).value?.mapFontSize ?? 1;
    final windArrowSize = 36.0 * fontScale;
    final windLabelSize = 15.0 * fontScale;
    final windOffsetX = 66.0 * fontScale;
    final windLabelOffsetY = 20.0 * fontScale;
    final pointArrowOffsetX = 22.0 * fontScale;
    final pointLabelOffsetX = 38.0 * fontScale;
    await style.addSource(
      const GeoJsonSource(id: _forecastSource, data: _emptyForecastGeoJson),
    );
    await style.addLayer(
      const CircleStyleLayer(
        id: _forecastHitLayer,
        sourceId: _forecastSource,
        filter: ['!=', 'kind', 'aircraft'],
        paint: {'circle-radius': 14.0, 'circle-opacity': 0.0},
      ),
    );
    await style.addLayer(
      const CircleStyleLayer(
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
          'circle-color': _forecastMarkerColor,
          'circle-stroke-color': [
            'match',
            ['get', 'kind'],
            'waypoint',
            _forecastWaypointColor,
            _forecastSampleColor,
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
          'text-color': _forecastTextColor,
          'text-halo-color': _forecastHaloColor,
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
          'text-color': _forecastTextColor,
          'text-halo-color': _forecastHaloColor,
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
          'text-color': _forecastTextColor,
          'text-halo-color': _forecastHaloColor,
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
          'text-color': _forecastTextColor,
          'text-halo-color': _forecastHaloColor,
          'text-halo-width': 2.0 * fontScale,
          'text-translate': [windOffsetX, windLabelOffsetY],
          'text-translate-anchor': 'viewport',
        },
      ),
    );
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
          final input = _flightWeatherInput();
          final geoJson =
              input.points.isEmpty || (!input.enabled && input.route.isEmpty)
              ? _emptyForecastGeoJson
              : await compute(
                  _buildFlightWeatherGeoJson,
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

  _ForecastMapInput _flightWeatherInput() {
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
    final winds = <String, _WindMarker>{};
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
