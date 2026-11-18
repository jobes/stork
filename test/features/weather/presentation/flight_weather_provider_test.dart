import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/weather/data/repositories/flight_forecast_repository.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';

final _now = DateTime.utc(2026, 11, 16, 14);
const _location = (latitude: 48.2, longitude: 17.2);

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(showFlightWeather: true);
}

class _AircraftPlan extends FlightWeatherPlan {
  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'aircraft',
      location: _location,
      eta: _now,
      duration: Duration.zero,
      distanceMeters: 0,
      altitudeFeet: 2000,
    ),
  ];
}

class _RoutePlan extends FlightWeatherPlan {
  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'origin',
      location: _location,
      eta: _now,
      duration: Duration.zero,
      distanceMeters: 0,
      altitudeFeet: 2000,
    ),
    ForecastRoutePoint(
      id: 'waypoint-0',
      location: (latitude: 48.3, longitude: 17.3),
      eta: _now.add(const Duration(minutes: 30)),
      duration: const Duration(minutes: 30),
      distanceMeters: 12000,
      altitudeFeet: 2000,
      waypointIndex: 0,
    ),
  ];
}

ForecastSeries _series() => ForecastSeries.fromJson({
  'elevation': 100,
  'hourly': {
    'time': [
      for (var i = 0; i < 3; i++)
        _now.add(Duration(hours: i)).millisecondsSinceEpoch ~/ 1000,
    ],
    'surface_pressure': [1000, 1000, 1000],
    'wind_speed_950hPa': [36, 36, 36],
    'wind_direction_950hPa': [0, 0, 0],
    'geopotential_height_950hPa': [500, 500, 500],
    'wind_speed_925hPa': [36, 36, 36],
    'wind_direction_925hPa': [0, 0, 0],
    'geopotential_height_925hPa': [800, 800, 800],
    'wind_gusts_10m': [72, 72, 72],
    'weather_code': [0, 0, 0],
  },
}, _now);

ProviderContainer _container(FlightWeatherPlan Function() plan) {
  final series = _series();
  return ProviderContainer(
    overrides: [
      appSettingsProvider.overrideWith(_Settings.new),
      flightWeatherPlanProvider.overrideWith(plan),
      forecastPointTerrainProvider(_location).overrideWith((ref) async => null),
      flightForecastProfilesProvider.overrideWith(
        (ref) async => (
          series: {forecastLocationKey(_location): series},
          refreshFailed: false,
        ),
      ),
    ],
  );
}

void main() {
  test('provides wind next to the aircraft without a route', () async {
    final container = _container(_AircraftPlan.new);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);

    final forecast = container.read(nearbyFlightForecastProvider);

    expect(forecast?.wind, isNotNull);
    expect(forecast?.gustMs, closeTo(20, 0.001));
  });

  test('provides wind next to the aircraft with an active route', () async {
    final container = _container(_RoutePlan.new);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);

    final forecast = container.read(nearbyFlightForecastProvider);

    expect(forecast?.wind, isNotNull);
    expect(forecast?.gustMs, closeTo(20, 0.001));
  });
}
