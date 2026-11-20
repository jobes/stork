import 'package:stork/features/weather/domain/wind_route_timing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/weather/presentation/providers/route_timing_provider.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/domain/weather_hazard.dart';
import 'package:stork/features/weather/data/models/forecast_series.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/features/weather/presentation/providers/weather_hazard_provider.dart';

final _now = DateTime.utc(2026, 11, 16, 14);
const _location = (latitude: 48.2, longitude: 17.2);

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(showFlightWeather: true);

  void disableWeather() =>
      state = const AsyncData(AppSettings(showFlightWeather: false));
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(isActive: true);

  void changeRoute() =>
      state = const AsyncData(NavigationState(isActive: false));

  void restoreRoute() =>
      state = const AsyncData(NavigationState(isActive: true));
}

class _Plan extends FlightWeatherPlanNotifier {
  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'aircraft',
      location: _location,
      eta: _now.add(const Duration(minutes: 30)),
      duration: Duration.zero,
      distanceMeters: 0,
      altitudeFeet: 2000,
    ),
  ];
}

void main() {
  test(
    'uses forecast at passage time and aircraft limits, clears when disabled',
    () async {
      final series = ForecastSeries.fromJson({
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
          'wind_gusts_10m': [0, 72, 0],
          'weather_code': [0, 45, 0],
        },
      }, _now);
      var timing = <String, TimedRoutePoint>{};
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith(_Settings.new),
          navigationProvider.overrideWith(_Navigation.new),
          flightWeatherPlanProvider.overrideWith(_Plan.new),
          routePointTimingProvider.overrideWith((ref) => timing),
          forecastPointTerrainProvider(_location)
              .overrideWith((ref) async => null),
          selectedAircraftProvider.overrideWith(
            (ref) => const Aircraft(
              id: 'one',
              name: 'Demo',
              dangerousWindMs: 9,
              dangerousGustMs: 15,
            ),
          ),
          flightForecastProfilesProvider.overrideWith(
            (ref) async => (
              series: {
                forecastLocationKey(_location): series,
                forecastLocationKey(quantizeForecastLocation(_location)):
                    series,
              },
              refreshFailed: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        activeWeatherHazardsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(flightForecastProfilesProvider.future);
      final details = await container.read(weatherHazardDetailsProvider.future);
      final hazards = container.read(activeWeatherHazardsProvider);
      expect(details, hasLength(1));
      expect(details.single.location, _location);
      expect(details.single.time, _now.add(const Duration(minutes: 30)));
      expect(details.single.windLimitMs, 9);
      expect(details.single.gustMs, 20);
      expect(hazards, {
        WeatherHazard.wind,
        WeatherHazard.gust,
        WeatherHazard.fog,
      });
      container.invalidate(weatherHazardDetailsProvider);
      expect(container.read(activeWeatherHazardsProvider), hazards);
      await container.read(weatherHazardDetailsProvider.future);

      timing = {
        'aircraft': (
          eta: null,
          duration: null,
          sources: const {RouteTimingSource.blocked},
          windEffect: null,
        ),
      };
      container.invalidate(routePointTimingProvider);
      expect(
        await container.read(weatherHazardDetailsProvider.future),
        isEmpty,
      );

      timing = {};
      container.invalidate(routePointTimingProvider);
      await container.read(weatherHazardDetailsProvider.future);
      expect(container.read(activeWeatherHazardsProvider), hazards);
      (container.read(navigationProvider.notifier) as _Navigation)
          .changeRoute();
      expect(container.read(activeWeatherHazardsProvider), isEmpty);

      (container.read(navigationProvider.notifier) as _Navigation)
          .restoreRoute();
      await container.read(weatherHazardDetailsProvider.future);
      expect(container.read(activeWeatherHazardsProvider), hazards);

      (container.read(appSettingsProvider.notifier) as _Settings)
          .disableWeather();
      expect(container.read(activeWeatherHazardsProvider), isEmpty);
    },
  );
}
