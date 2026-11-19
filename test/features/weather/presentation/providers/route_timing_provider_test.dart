import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/throttled_telemetry_provider.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/domain/wind_route_timing.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/features/weather/presentation/providers/route_timing_provider.dart';

final _departure = DateTime.utc(2026, 11, 16, 14);

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(showFlightWeather: true);
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(isActive: true);
}

class _Telemetry extends ThrottledTelemetry {
  @override
  TelemetryState build() => const TelemetryState();
}

class _Plan extends FlightWeatherPlanNotifier {
  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'origin',
      location: (latitude: 48.0, longitude: 17.0),
      eta: _departure,
      duration: Duration.zero,
      distanceMeters: 0,
      altitudeFeet: 2000,
    ),
    ForecastRoutePoint(
      id: 'waypoint-0',
      location: (latitude: 48.1, longitude: 17.0),
      eta: _departure.add(const Duration(seconds: 500)),
      duration: const Duration(seconds: 500),
      distanceMeters: 10000,
      altitudeFeet: 2000,
      waypointIndex: 0,
    ),
  ];

  void move() => state = [
    state.first.copyWith(location: (latitude: 48.01, longitude: 17.0)),
    state.last,
  ];
  void delay() => state = [
    for (final point in state)
      point.copyWith(eta: point.eta.add(const Duration(hours: 1))),
  ];
}

class _Timing extends RouteWindTimingNotifier {
  static Completer<void>? gate;

  @override
  Future<WindTimingResult?> build() async {
    final plan = ref.watch(flightWeatherPlanProvider);
    final key = (
      route: ref.watch(navigationProvider).value!.points,
      plannedDeparture: ref.watch(flightDepartureProvider),
      defaultAltitude: null as int?,
      profileTas: 20.0,
      flying: false,
    );
    await gate?.future;
    return (
      key: key,
      plan: plan,
      locations: {for (final point in plan) point.id: point.location},
      timing: {
        for (final point in plan)
          point.id: (
            eta: plan.first.eta.add(
              Duration(seconds: point.id == 'origin' ? 0 : 1000),
            ),
            duration: Duration(seconds: point.id == 'origin' ? 0 : 1000),
            sources: const {RouteTimingSource.wind},
            windEffect: const Duration(seconds: 500),
          ),
      },
    );
  }
}

void main() {
  for (final change in ['origin', 'departure', 'unchanged']) {
    test(
      'retained timing uses a coherent plan while $change solve is pending',
      () async {
        _Timing.gate = null;
        final container = ProviderContainer(
          overrides: [
            appSettingsProvider.overrideWith(_Settings.new),
            navigationProvider.overrideWith(_Navigation.new),
            throttledTelemetryProvider.overrideWith(_Telemetry.new),
            selectedAircraftProvider.overrideWith((ref) => null),
            cruiseSpeedProvider.overrideWith((ref) => 20),
            flightWeatherPlanProvider.overrideWith(_Plan.new),
            routeWindTimingProvider.overrideWith(_Timing.new),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          routePointTimingProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(routeWindTimingProvider.future);
        expect(
          container.read(routePointTimingProvider)['waypoint-0']!.duration,
          const Duration(seconds: 1000),
        );
        final gate = _Timing.gate = Completer<void>();
        if (change == 'origin') {
          (container.read(flightWeatherPlanProvider.notifier) as _Plan).move();
        } else if (change == 'departure') {
          (container.read(flightWeatherPlanProvider.notifier) as _Plan).delay();
        } else {
          container.invalidate(routeWindTimingProvider);
        }
        final timing = container.read(routePointTimingProvider);
        final plan = container.read(flightWeatherPlanProvider);
        expect(timing['origin']!.eta, plan.first.eta);
        expect(
          timing['waypoint-0']!.duration,
          Duration(seconds: change == 'unchanged' ? 1000 : 500),
        );
        expect(
          timing['waypoint-0']!.eta,
          change == 'unchanged'
              ? _departure.add(const Duration(seconds: 1000))
              : plan.last.eta,
        );
        gate.complete();
        await container.read(routeWindTimingProvider.future);
      },
    );
  }
}
