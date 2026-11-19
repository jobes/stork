import 'dart:convert';

import '../../favorites/domain/models/favorite_point.dart';
import '../../navigation/domain/models/navigation_point.dart';
import '../../weather/domain/flight_forecast.dart';
import '../../weather/domain/forecast_route.dart';

const emptyFlightWeatherGeoJson = '{"type":"FeatureCollection","features":[]}';

typedef ForecastWindMarker = ({String arrow, double direction, String label});

typedef FlightWeatherMapInput = ({
  bool enabled,
  List<ForecastRoutePoint> points,
  List<NavigationPoint> route,
  List<FavoritePoint> favorites,
  Map<String, ForecastWindMarker> winds,
});

/// Builds the forecast GeoJSON for the map. The layer is part of the flight
/// forecast setting, so a disabled forecast adds no features at all.
String buildFlightWeatherGeoJson(FlightWeatherMapInput input) {
  if (!input.enabled) return emptyFlightWeatherGeoJson;
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
