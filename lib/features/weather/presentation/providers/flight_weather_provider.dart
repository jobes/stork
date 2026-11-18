import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show debugPrint, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/terrain_elevation_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../map/presentation/providers/airport_metadata_provider.dart';
import '../../../route/presentation/providers/navigation_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../data/repositories/flight_forecast_repository.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_airport_elevation.dart';
import '../../domain/forecast_profile.dart';
import '../../domain/forecast_query.dart';
import '../../domain/forecast_route.dart';

part 'flight_weather_provider.g.dart';

@Riverpod(keepAlive: true)
class FlightDepartureNotifier extends _$FlightDepartureNotifier {
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
class FlightWeatherPlanNotifier extends _$FlightWeatherPlanNotifier {
  ForecastRoute? _plannedRoute;
  List<NavigationPoint> _lastWaypoints = const [];
  List<ForecastRoutePoint>? _lastPlan;
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
    // ETA and arrival weather are minute-resolution, so bucket the clock to
    // avoid rebuilding the whole plan four times a minute.
    final clockNow = ref.watch(flightWeatherClockProvider).value ?? clock.now();
    final now = DateTime(
      clockNow.year,
      clockNow.month,
      clockNow.day,
      clockNow.hour,
      clockNow.minute,
    );
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
    final forecastPoints = _plannedRoute!.forecastPoints(
      position: position,
      points: waypoints,
      departure: waypoints.isEmpty ? now : departure,
      groundSpeed: groundSpeed,
      flying: flying,
      defaultAltitudeFeet: defaultFeet,
      previousWaypointAltitudeFeet: _previousWaypointAltitudeFeet,
    );
    final previous = _lastPlan;
    if (previous != null && listEquals(previous, forecastPoints)) {
      return previous;
    }
    return _lastPlan = forecastPoints;
  }
}

/// Latches the profile location for the moving aircraft. Small movements reuse
/// the previous profile instead of requesting a new one every grid cell.
@riverpod
class FlightWeatherOrigin extends _$FlightWeatherOrigin {
  ForecastLocation? _latched;

  @override
  ForecastLocation? build() {
    final points = ref.watch(flightWeatherPlanProvider);
    if (points.isEmpty) {
      _latched = null;
      return null;
    }
    final position = points.first.location;
    final latched = _latched;
    if (latched == null ||
        GeoUtils.distanceBetween(
              latched.latitude,
              latched.longitude,
              position.latitude,
              position.longitude,
            ) >=
            forecastOriginRefreshDistanceMeters) {
      _latched = position;
    }
    return _latched;
  }
}

/// Profile lookup location for every plan point. The aircraft uses the latched
/// location so lookups keep working while the previous profile is reused.
@riverpod
Map<String, ForecastLocation> flightWeatherProfileLocations(Ref ref) {
  final points = ref.watch(flightWeatherPlanProvider);
  final origin = ref.watch(flightWeatherOriginProvider);
  final originLocation = origin == null
      ? null
      : quantizeForecastLocation(origin);
  return {
    for (final point in points)
      point.id: point.id == 'origin' || point.id == 'aircraft'
          ? originLocation ?? quantizeForecastLocation(point.location)
          : point.location,
  };
}

ForecastRoutePoint? weatherPoint(List<ForecastRoutePoint> points, String id) =>
    points.where((point) => point.id == id).firstOrNull;

@riverpod
class FlightWeatherQuery extends _$FlightWeatherQuery {
  @override
  ForecastQuery? build() {
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
    );
    if (!enabled) return null;
    final points = ref.watch(flightWeatherPlanProvider);
    if (points.isEmpty) return null;

    final start = points.first;
    final origin = ref.watch(flightWeatherOriginProvider);
    if (origin == null) return null;
    final firstEta = start.eta.toUtc();
    final lastEta = points.fold(
      firstEta,
      (last, point) => point.eta.isAfter(last) ? point.eta.toUtc() : last,
    );
    DateTime hour(DateTime value) =>
        DateTime.utc(value.year, value.month, value.day, value.hour);
    return ForecastQuery(
      [
        quantizeForecastLocation(origin),
        for (final point in points.skip(1)) point.location,
      ],
      hour(firstEta).subtract(forecastTimeReserve),
      hour(lastEta).add(forecastTimeReserve + const Duration(hours: 1)),
    );
  }
}

@riverpod
Stream<int> flightForecastRefresh(Ref ref) async* {
  yield 0;
  yield* Stream.periodic(forecastRefreshInterval, (n) => n + 1);
}

/// Manual refresh requested from the map alert. Profiles only live in memory,
/// so the action re-requests every location of the current plan.
@riverpod
class FlightForecastSyncNotifier extends _$FlightForecastSyncNotifier {
  @override
  void build() {}

  void refresh() {
    ref.read(flightForecastRepositoryProvider).requestRefresh();
    ref.invalidate(flightForecastProfilesProvider);
  }
}

@riverpod
Future<ForecastProfiles?> flightForecastProfiles(Ref ref) async {
  final query = ref.watch(flightWeatherQueryProvider);
  if (query == null) return null;
  ref.watch(flightForecastRefreshProvider);
  final repository = ref.watch(flightForecastRepositoryProvider);
  return repository.load(query);
}

@riverpod
Future<double?> forecastPointTerrain(Ref ref, ForecastLocation location) => ref
    .watch(terrainElevationServiceProvider)
    .getElevation(location.latitude, location.longitude);

/// Terrain and airport reference for one forecast point. Resolving it per
/// point keeps the route list, map markers, navigation details and hazard
/// evaluation on the same terrain and pressure reference.
@riverpod
Future<ForecastReference> routeForecastReference(
  Ref ref,
  String pointId,
) async {
  final point = weatherPoint(ref.watch(flightWeatherPlanProvider), pointId);
  if (point == null) return (terrainMeters: null, airportMeters: null);
  final route =
      ref.watch(navigationProvider).value?.points ?? const <NavigationPoint>[];
  final index = point.waypointIndex;
  final waypoint = index != null && index < route.length ? route[index] : null;
  final terrain = await _ignoreErrors(
    ref.watch(forecastPointTerrainProvider(point.location).future),
    'Could not load terrain for $pointId',
  );
  final airportId = waypoint?.airportId;
  final country = waypoint?.airportCountry;
  final airport =
      airportId != null &&
          airportId.isNotEmpty &&
          country != null &&
          country.isNotEmpty
      ? await _ignoreErrors(
          ref.watch(airportMetadataProvider(airportId, country).future),
          'Could not load airport elevation for $airportId',
        )
      : null;
  return (
    terrainMeters: terrain,
    airportMeters: airportElevationMeters(airport),
  );
}

/// References for every plan point, resolved through
/// [routeForecastReferenceProvider].
@riverpod
Future<Map<String, ForecastReference>> routeForecastReferences(Ref ref) async {
  final points = ref.watch(flightWeatherPlanProvider);
  final references = await Future.wait([
    for (final point in points)
      ref.watch(routeForecastReferenceProvider(point.id).future),
  ]);
  return {
    for (final (index, point) in points.indexed) point.id: references[index],
  };
}

Future<T?> _ignoreErrors<T>(Future<T> future, String message) async {
  try {
    return await future;
  } catch (error) {
    debugPrint(message);
    return null;
  }
}

bool _movedFrom(ForecastLocation previous, ForecastLocation current) =>
    GeoUtils.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    ) >=
    forecastNearbyRefreshDistanceMeters;
