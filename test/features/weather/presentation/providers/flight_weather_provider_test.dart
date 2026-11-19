import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/weather/data/models/forecast_series.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';
import 'package:stork/features/weather/domain/forecast_profile.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/features/weather/presentation/providers/route_timing_provider.dart';
import 'package:stork/features/weather/presentation/providers/route_waypoint_weather_provider.dart';

final _now = DateTime.utc(2026, 11, 16, 14);
const _location = (latitude: 48.2, longitude: 17.2);

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState();
}

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(showFlightWeather: true);
}

class _AircraftPlan extends FlightWeatherPlanNotifier {
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

class _SurfacePlan extends _AircraftPlan {
  @override
  List<ForecastRoutePoint> build() => [
    super.build().first.copyWith(altitudeFeet: null, waypointIndex: 0),
  ];
}

class _MovablePlan extends FlightWeatherPlanNotifier {
  static ForecastLocation location = _location;

  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'aircraft',
      location: location,
      eta: _now,
      duration: Duration.zero,
      distanceMeters: 0,
      altitudeFeet: 2000,
    ),
  ];
}

class _RoutePlan extends FlightWeatherPlanNotifier {
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

ProviderContainer _container(FlightWeatherPlanNotifier Function() plan) {
  final series = _series();
  return ProviderContainer(
    overrides: [
      appSettingsProvider.overrideWith(_Settings.new),
      navigationProvider.overrideWith(_Navigation.new),
      selectedAircraftProvider.overrideWith((ref) => null),
      flightWeatherPlanProvider.overrideWith(plan),
      routePointTimingProvider.overrideWith((ref) => const {}),
      routeForecastReferencesProvider.overrideWith(
        (ref) async => const <String, ForecastReference>{},
      ),
      forecastPointTerrainProvider(_location).overrideWith((ref) async => null),
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
  test('provides wind next to the aircraft without a route', () async {
    final container = _container(_AircraftPlan.new);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);

    final wind = container.read(routePointWindsProvider)['aircraft'];

    expect(wind?.wind, isNotNull);
    expect(wind?.gustMs, closeTo(20, 0.001));
  });

  test('provides wind next to the aircraft with an active route', () async {
    final container = _container(_RoutePlan.new);
    addTearDown(container.dispose);
    await container.read(flightForecastProfilesProvider.future);

    final wind = container.read(routePointWindsProvider)['origin'];

    expect(wind?.wind, isNotNull);
    expect(wind?.gustMs, closeTo(20, 0.001));
  });

  test('reuses the aircraft profile until it moves ten kilometres', () {
    _MovablePlan.location = _location;
    final container = _container(_MovablePlan.new);
    addTearDown(container.dispose);

    final first = container.read(flightWeatherOriginProvider);
    expect(first, _location);
    final firstQuery = container.read(flightWeatherQueryProvider);
    expect(firstQuery!.locations.keys, [
      forecastLocationKey(quantizeForecastLocation(_location)),
    ]);

    _MovablePlan.location = (
      latitude: _location.latitude + 0.08,
      longitude: _location.longitude,
    );
    container.invalidate(flightWeatherPlanProvider);
    expect(container.read(flightWeatherOriginProvider), first);
    expect(container.read(flightWeatherQueryProvider), firstQuery);

    _MovablePlan.location = (
      latitude: _location.latitude + 0.1,
      longitude: _location.longitude,
    );
    container.invalidate(flightWeatherPlanProvider);
    final moved = container.read(flightWeatherOriginProvider);
    expect(moved, isNot(first));
    expect(container.read(flightWeatherQueryProvider)!.locations.keys, [
      forecastLocationKey(quantizeForecastLocation(moved!)),
    ]);
  });
  test(
    'surface weather remains available without a planned altitude',
    () async {
      final container = _container(_SurfacePlan.new);
      addTearDown(container.dispose);
      await container.read(flightForecastProfilesProvider.future);
      final weather = container.read(routeWaypointWeatherProvider)[0]!;
      expect(weather.forecastEnabled, isTrue);
      expect(weather.forecastAvailable, isTrue);
      expect(weather.wind, isNull);
      expect(weather.gustMs, 20);
    },
  );

  test('extends only the current query and respects the planning horizon', () {
    withClock(Clock.fixed(_now), () {
      final container = _container(_RoutePlan.new);
      addTearDown(container.dispose);
      final query = container.read(flightWeatherQueryProvider)!;
      final notifier = container.read(flightWeatherQueryProvider.notifier);
      notifier.extendFor(query, _now.add(const Duration(hours: 5)));
      final extended = container.read(flightWeatherQueryProvider)!;
      expect(extended.end.isAfter(query.end), isTrue);
      notifier.extendFor(query, _now.add(const Duration(days: 20)));
      expect(container.read(flightWeatherQueryProvider), extended);
      notifier.extendFor(extended, _now.add(const Duration(days: 20)));
      expect(
        container.read(flightWeatherQueryProvider)!.end,
        DateTime.utc(2026, 11, 20),
      );
    });
  });
}
