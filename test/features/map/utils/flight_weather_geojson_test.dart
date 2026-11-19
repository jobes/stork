import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/favorites/domain/models/favorite_point.dart';
import 'package:stork/features/map/domain/models/poi_type.dart';
import 'package:stork/features/map/utils/flight_weather_geojson.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';

final _time = DateTime.utc(2026, 11, 16, 14);

ForecastRoutePoint _point(
  String id, {
  int? waypointIndex,
  double latitude = 48.0,
  double longitude = 17.0,
}) => ForecastRoutePoint(
  id: id,
  location: (latitude: latitude, longitude: longitude),
  eta: _time,
  duration: Duration.zero,
  distanceMeters: 0,
  altitudeFeet: 2000,
  waypointIndex: waypointIndex,
);

const _waypoint = NavigationPoint(
  latitude: 48.1,
  longitude: 17.1,
  name: 'LZIB',
);

List<Map<String, dynamic>> _features(String geoJson) =>
    ((jsonDecode(geoJson) as Map<String, dynamic>)['features'] as List)
        .cast<Map<String, dynamic>>();

void main() {
  test('a disabled forecast adds no map features', () {
    final geoJson = buildFlightWeatherGeoJson((
      enabled: false,
      points: [_point('origin'), _point('waypoint-0', waypointIndex: 0)],
      route: const [_waypoint],
      favorites: const [],
      winds: const {},
    ));

    expect(_features(geoJson), isEmpty);
  });

  test('an enabled forecast marks waypoints, samples and the aircraft', () {
    final geoJson = buildFlightWeatherGeoJson((
      enabled: true,
      points: [
        _point('origin'),
        _point('waypoint-0', waypointIndex: 0),
        _point('sample-0'),
      ],
      route: const [_waypoint],
      favorites: const [],
      winds: const {'origin': (arrow: '↑', direction: 90.0, label: '20 km/h')},
    ));

    final features = _features(geoJson);
    expect(features, hasLength(3));
    expect(
      {
        for (final feature in features)
          (feature['properties'] as Map)['forecastId']:
              (feature['properties'] as Map)['kind'],
      },
      {'origin': 'aircraft', 'waypoint-0': 'waypoint', 'sample-0': 'sample'},
    );
    expect((features.first['properties'] as Map)['label'], '20 km/h');
  });

  test('a waypoint with its own map icon is reported as mapped', () {
    final geoJson = buildFlightWeatherGeoJson((
      enabled: true,
      points: [
        _point('waypoint-0', waypointIndex: 0),
        _point('waypoint-1', waypointIndex: 1),
      ],
      route: const [
        NavigationPoint(
          latitude: 48.1,
          longitude: 17.1,
          name: 'LZIB',
          isAirport: true,
        ),
        NavigationPoint(
          latitude: 48.2,
          longitude: 17.2,
          name: 'Favourite',
          favoriteId: 'fav-1',
        ),
      ],
      favorites: const [
        FavoritePoint(
          id: 'fav-1',
          latitude: 48.2,
          longitude: 17.2,
          icon: PoiType.thermal,
          name: 'Favourite',
        ),
      ],
      winds: const {},
    ));

    expect(
      [
        for (final feature in _features(geoJson))
          (feature['properties'] as Map)['kind'],
      ],
      ['mapped', 'mapped'],
    );
  });
}
