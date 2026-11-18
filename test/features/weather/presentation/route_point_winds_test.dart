import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/weather/presentation/providers/navigation_eta_provider.dart';
import 'package:stork/features/route/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/weather/data/models/forecast_series.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/domain/wind_route_timing.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/features/weather/presentation/providers/route_waypoint_weather_provider.dart';

final _now = DateTime.utc(2026, 11, 16, 14);
const _location = (latitude: 48.2, longitude: 17.2);

class _Settings extends AppSettingsNotifier {
  _Settings({this.enabled = true});

  final bool enabled;

  @override
  AppSettings build() => AppSettings(showFlightWeather: enabled);
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(isActive: true);
}

class _Plan extends FlightWeatherPlanNotifier {
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
      location: _location,
      eta: _now.add(const Duration(hours: 1)),
      duration: const Duration(hours: 1),
      distanceMeters: 12000,
      altitudeFeet: 2000,
      waypointIndex: 0,
    ),
    ForecastRoutePoint(
      id: 'sample-0',
      location: _location,
      eta: _now.add(const Duration(hours: 2)),
      duration: const Duration(hours: 2),
      distanceMeters: 6000,
      altitudeFeet: 2000,
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
    'wind_speed_950hPa': [36, 72, 36],
    'wind_direction_950hPa': [0, 0, 0],
    'geopotential_height_950hPa': [500, 500, 500],
    'wind_speed_925hPa': [36, 72, 36],
    'wind_direction_925hPa': [0, 0, 0],
    'geopotential_height_925hPa': [800, 800, 800],
    'wind_gusts_10m': [72, 72, 72],
    'weather_code': [0, 0, 0],
  },
}, _now);

const _sources = <RouteTimingSource>{};

Map<String, TimedRoutePoint> _timing() => {
  'origin': (
    eta: _now,
    duration: Duration.zero,
    sources: _sources,
    windEffect: null,
  ),
  'waypoint-0': (
    eta: _now.add(const Duration(hours: 1)),
    duration: const Duration(hours: 1),
    sources: _sources,
    windEffect: null,
  ),
  'sample-0': (
    eta: _now.add(const Duration(hours: 2)),
    duration: const Duration(hours: 2),
    sources: _sources,
    windEffect: null,
  ),
};

ProviderContainer _container({
  bool enabled = true,
  Map<String, TimedRoutePoint>? timing,
  double? terrain,
}) {
  final series = _series();
  return ProviderContainer(
    overrides: [
      appSettingsProvider.overrideWith(() => _Settings(enabled: enabled)),
      navigationProvider.overrideWith(_Navigation.new),
      flightWeatherPlanProvider.overrideWith(_Plan.new),
      routePointTimingProvider.overrideWith((ref) => timing ?? _timing()),
      forecastPointTerrainProvider(
        _location,
      ).overrideWith((ref) async => terrain),
      flightForecastProfilesProvider.overrideWith(
        (ref) async => (
          series: {
            forecastLocationKey(_location): series,
            forecastLocationKey(quantizeForecastLocation(_location)): series,
          },
          refreshFailed: false,
        ),
      ),
    ],
  );
}

void main() {
  test('reads wind at each point at its estimated arrival time', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);
    await container.read(routeForecastReferencesProvider.future);

    final winds = container.read(routePointWindsProvider);

    expect(winds.keys, unorderedEquals(['origin', 'waypoint-0', 'sample-0']));
    expect(winds['origin']!.wind!.speedMs, closeTo(10, 0.1));
    expect(winds['waypoint-0']!.wind!.speedMs, closeTo(20, 0.1));
    expect(winds['sample-0']!.wind!.speedMs, closeTo(10, 0.1));
    expect(winds['waypoint-0']!.gustMs, closeTo(20, 0.001));
  });

  test('returns no winds when flight weather is disabled', () async {
    final container = _container(enabled: false);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);
    await container.read(routeForecastReferencesProvider.future);

    expect(container.read(routePointWindsProvider), isEmpty);
  });

  test('uses the terrain reference above the planned altitude', () async {
    final container = _container(terrain: 1000);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);
    await container.read(routeForecastReferencesProvider.future);

    final winds = container.read(routePointWindsProvider);

    expect(winds['origin']!.wind, isNull);
    expect(winds['origin']!.gustMs, closeTo(20, 0.001));
  });

  test('omits a point whose wind-adjusted ETA is unavailable', () async {
    final timing = _timing();
    timing['waypoint-0'] = (
      eta: null,
      duration: const Duration(hours: 1),
      sources: const {RouteTimingSource.blocked},
      windEffect: null,
    );
    final container = _container(timing: timing);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);
    await container.read(routeForecastReferencesProvider.future);

    final winds = container.read(routePointWindsProvider);

    expect(winds.keys, unorderedEquals(['origin', 'sample-0']));
  });
}
