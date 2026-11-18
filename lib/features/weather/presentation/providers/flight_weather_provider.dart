import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/terrain_elevation_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../data/repositories/flight_forecast_repository.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_route.dart';

part 'flight_weather_provider.g.dart';

@Riverpod(keepAlive: true)
class FlightDeparture extends _$FlightDeparture {
  @override
  DateTime? build() {
    ref.listen(
      navigationProvider.select((route) => route.value?.points.isEmpty ?? true),
      (previous, next) {
        if (next) state = null;
      },
    );
    return null;
  }

  void select(DateTime? time) => state = time?.toUtc();
}

@riverpod
Stream<DateTime> flightWeatherClock(Ref ref) async* {
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 15), (_) => clock.now());
}

@riverpod
class FlightWeatherPlan extends _$FlightWeatherPlan {
  ForecastRoute? _plannedRoute;
  List<NavigationPoint> _lastWaypoints = const [];
  int? _previousWaypointAltitudeFeet;
  bool _wasFlying = false;

  @override
  List<ForecastRoutePoint> build() {
    final route = ref.watch(navigationProvider).value;
    final waypoints = route?.points ?? const <NavigationPoint>[];
    final telemetry = ref.watch(
      throttledTelemetryProvider.select(
        (s) => (
          latitude: s.latitude,
          longitude: s.longitude,
          isFlying: s.isFlying,
          groundSpeed: s.groundSpeed,
        ),
      ),
    );
    final cruiseSpeed = ref.watch(cruiseSpeedProvider);
    final defaultFeet = ref
        .watch(selectedAircraftProvider)
        ?.weatherAltitudeFeet;
    final now = ref.watch(flightWeatherClockProvider).value ?? clock.now();
    final plannedDeparture = ref.watch(flightDepartureProvider);

    final lat = telemetry.latitude;
    final lon = telemetry.longitude;
    if (lat == null || lon == null || (lat == 0 && lon == 0)) return const [];
    final position = (latitude: lat, longitude: lon);
    final flying = telemetry.isFlying;
    final reportedSpeed = telemetry.groundSpeed;
    final groundSpeed =
        flying &&
            reportedSpeed != null &&
            reportedSpeed.isFinite &&
            reportedSpeed > 0
        ? reportedSpeed
        : cruiseSpeed;
    final plan = _plannedRoute;

    final removedCount = _lastWaypoints.length - waypoints.length;
    if (plan == null ||
        !plan.matches(waypoints) ||
        (!flying &&
            (_wasFlying ||
                plan.planningSpeed != cruiseSpeed ||
                _movedFrom(plan.origin, position))) ||
        (removedCount != 0 && route?.wasAutoAdvanced != true)) {
      _plannedRoute = ForecastRoute.plan(position, waypoints, cruiseSpeed);
      _previousWaypointAltitudeFeet = null;
    } else if (removedCount > 0) {
      _previousWaypointAltitudeFeet =
          _lastWaypoints[removedCount - 1].weatherAltitudeFeet;
    }
    _lastWaypoints = waypoints;
    _wasFlying = flying;
    final departure =
        flying || plannedDeparture == null || plannedDeparture.isBefore(now)
        ? now
        : plannedDeparture;
    return _plannedRoute!.forecastPoints(
      position: position,
      points: waypoints,
      departure: waypoints.isEmpty ? now : departure,
      groundSpeed: groundSpeed,
      flying: flying,
      defaultAltitudeFeet: defaultFeet,
      previousWaypointAltitudeFeet: _previousWaypointAltitudeFeet,
    );
  }
}

ForecastRoutePoint? weatherPoint(List<ForecastRoutePoint> points, String id) =>
    points.where((point) => point.id == id).firstOrNull;

@riverpod
class FlightWeatherQuery extends _$FlightWeatherQuery {
  ForecastLocation? _nearbyLocation;

  @override
  ForecastQuery? build() {
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
    );
    if (!enabled) return null;
    final points = ref.watch(flightWeatherPlanProvider);
    if (points.isEmpty) return null;

    final start = points.first;
    final position = start.location;
    final nearby = _nearbyLocation;
    if (nearby == null || _movedFrom(nearby, position)) {
      _nearbyLocation = position;
    }

    final firstEta = start.eta.toUtc();
    final lastEta = points.fold(
      firstEta,
      (last, point) => point.eta.isAfter(last) ? point.eta.toUtc() : last,
    );
    DateTime hour(DateTime value) =>
        DateTime.utc(value.year, value.month, value.day, value.hour);
    return ForecastQuery(
      [_nearbyLocation!, for (final point in points.skip(1)) point.location],
      hour(firstEta).subtract(forecastTimeReserve),
      hour(lastEta).add(forecastTimeReserve + const Duration(hours: 1)),
    );
  }

  ForecastLocation locationFor(ForecastRoutePoint point) =>
      point.id == 'origin' || point.id == 'aircraft'
      ? _nearbyLocation ?? point.location
      : point.location;
}

@riverpod
Stream<int> flightForecastRefresh(Ref ref) async* {
  yield 0;
  yield* Stream.periodic(forecastRefreshInterval, (n) => n + 1);
}

@riverpod
Future<ForecastProfiles?> flightForecastProfiles(Ref ref) async {
  final query = ref.watch(flightWeatherQueryProvider);
  if (query == null) return null;
  ref.watch(flightForecastRefreshProvider);
  final repository = await ref.watch(flightForecastRepositoryProvider.future);
  return repository.load(query);
}

@riverpod
Future<double?> forecastPointTerrain(Ref ref, ForecastLocation location) => ref
    .watch(terrainElevationServiceProvider)
    .getElevation(location.latitude, location.longitude);

@riverpod
FlightForecast? nearbyFlightForecast(Ref ref) {
  // The map subscribes here so route profiles are prefetched before a detail opens.
  final profiles = ref.watch(flightForecastProfilesProvider).value;
  final points = ref.watch(flightWeatherPlanProvider);
  if (profiles == null || points.isEmpty) return null;
  final point = points.first;
  if (point.id != 'aircraft' && point.id != 'origin') return null;
  final location = ref
      .read(flightWeatherQueryProvider.notifier)
      .locationFor(point);
  final series = profiles.series[forecastLocationKey(location)];
  if (series == null) return null;
  final terrain = ref.watch(forecastPointTerrainProvider(point.location)).value;
  return series.at(
    point.eta,
    altitudeMeters: point.altitudeFeet == null
        ? null
        : point.altitudeFeet! * feetInMeters,
    terrainMeters: terrain,
  );
}

bool _movedFrom(ForecastLocation previous, ForecastLocation current) =>
    GeoUtils.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    ) >=
    forecastNearbyRefreshDistanceMeters;
