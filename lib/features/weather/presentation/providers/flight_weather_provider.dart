import '../../../../core/startup/deferred_startup_tasks.dart';
import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show debugPrint, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/terrain_elevation_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../map/domain/models/airport_elevation.dart';
import '../../../map/presentation/providers/airport_metadata_provider.dart';
import '../../../navigation/domain/models/navigation_point.dart';
import '../../../navigation/domain/models/navigation_state.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../data/repositories/flight_forecast_repository.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_profile.dart';
import '../../domain/forecast_query.dart';
import '../../domain/forecast_route.dart';

part 'flight_weather_provider.g.dart';

@Riverpod(keepAlive: true)
class FlightDepartureNotifier extends _$FlightDepartureNotifier {
  ({NavigationState route, DateTime? departure})? _clearedDeparture;

  @override
  DateTime? build() {
    ref.listen(navigationProvider.select((route) => route.value), (
      previous,
      next,
    ) {
      if (next == null || next.points.isEmpty) {
        if (previous != null && previous.points.isNotEmpty) {
          _clearedDeparture = (route: previous, departure: state);
        }
        state = null;
      } else {
        final cleared = _clearedDeparture;
        _clearedDeparture = null;
        // A failed optimistic removal restores the original route object.
        if (cleared != null && identical(next, cleared.route)) {
          state = cleared.departure;
        }
      }
    });
    return null;
  }

  void select(DateTime? time) {
    // An explicit selection supersedes any departure saved for rollback.
    _clearedDeparture = null;
    state = time?.toUtc();
  }
}

@riverpod
Stream<DateTime> flightWeatherClock(Ref ref) async* {
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 15), (_) => clock.now());
}

/// Plan state that must survive rebuilds: the route geometry, the waypoints it
/// was built from and the last emitted plan. Immutable so `build` swaps one
/// value instead of mutating separate fields.
class _PlanCache {
  const _PlanCache({
    this.route,
    this.waypoints = const [],
    this.plan,
    this.previousWaypointAltitudeFeet,
    this.wasFlying = false,
  });

  final ForecastRoute? route;
  final List<ForecastWaypoint> waypoints;
  final List<ForecastRoutePoint>? plan;
  final int? previousWaypointAltitudeFeet;
  final bool wasFlying;

  _PlanCache copyWith({List<ForecastRoutePoint>? plan}) => _PlanCache(
    route: route,
    waypoints: waypoints,
    plan: plan ?? this.plan,
    previousWaypointAltitudeFeet: previousWaypointAltitudeFeet,
    wasFlying: wasFlying,
  );
}

/// Re-plans the route geometry only when the waypoints or the ground position
/// make the previous geometry unusable. Auto-advanced removals keep the
/// existing samples so they stay in place while flying.
_PlanCache _advancePlan(
  _PlanCache previous, {
  required List<ForecastWaypoint> waypoints,
  required ForecastLocation position,
  required double cruiseSpeed,
  required bool flying,
  required bool wasAutoAdvanced,
}) {
  final route = previous.route;
  final removedCount = previous.waypoints.length - waypoints.length;
  final needsNewGeometry =
      route == null ||
      !route.matches(waypoints) ||
      (!flying &&
          (previous.wasFlying ||
              route.planningSpeed != cruiseSpeed ||
              _movedFrom(route.origin, position))) ||
      (removedCount != 0 && !wasAutoAdvanced);
  if (needsNewGeometry) {
    return _PlanCache(
      route: ForecastRoute.plan(position, waypoints, cruiseSpeed),
      waypoints: waypoints,
      plan: previous.plan,
      wasFlying: flying,
    );
  }
  return _PlanCache(
    route: route,
    waypoints: waypoints,
    plan: previous.plan,
    previousWaypointAltitudeFeet: removedCount > 0
        ? previous.waypoints[removedCount - 1].altitudeFeet
        : previous.previousWaypointAltitudeFeet,
    wasFlying: flying,
  );
}

@riverpod
class FlightWeatherPlanNotifier extends _$FlightWeatherPlanNotifier {
  _PlanCache _cache = const _PlanCache();

  @override
  List<ForecastRoutePoint> build() {
    final route = ref.watch(navigationProvider).value;
    final waypoints = _forecastWaypoints(route?.points ?? const []);
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
    final now = DateTime.fromMillisecondsSinceEpoch(
      clockNow.millisecondsSinceEpoch ~/ 60000 * 60000,
      isUtc: true,
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
    final cache = _advancePlan(
      _cache,
      waypoints: waypoints,
      position: position,
      cruiseSpeed: cruiseSpeed,
      flying: flying,
      wasAutoAdvanced: route?.wasAutoAdvanced ?? false,
    );
    final departure =
        flying || plannedDeparture == null || plannedDeparture.isBefore(now)
        ? now
        : plannedDeparture;
    final forecastPoints = cache.route!.forecastPoints(
      position: position,
      points: waypoints,
      departure: waypoints.isEmpty ? now : departure,
      groundSpeed: groundSpeed,
      flying: flying,
      defaultAltitudeFeet: defaultFeet,
      previousWaypointAltitudeFeet: cache.previousWaypointAltitudeFeet,
    );
    final previousPlan = cache.plan;
    if (previousPlan != null && listEquals(previousPlan, forecastPoints)) {
      _cache = cache;
      return previousPlan;
    }
    _cache = cache.copyWith(plan: forecastPoints);
    return forecastPoints;
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
    return _latched = _latchOrigin(_latched, points.first.location);
  }
}

/// Keeps the previous location until the aircraft has moved far enough.
ForecastLocation _latchOrigin(
  ForecastLocation? latched,
  ForecastLocation position,
) =>
    latched == null ||
        GeoUtils.distanceBetween(
              latched.latitude,
              latched.longitude,
              position.latitude,
              position.longitude,
            ) >=
            forecastOriginRefreshDistanceMeters
    ? position
    : latched;

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
      point.id: isAircraftForecastPoint(point.id)
          ? originLocation ?? quantizeForecastLocation(point.location)
          : point.profileLocation ?? point.location,
  };
}

ForecastRoutePoint? weatherPoint(List<ForecastRoutePoint> points, String id) =>
    points.where((point) => point.id == id).firstOrNull;

/// Plan points keyed by their waypoint index, so route lists and dialogs can
/// look a point up without scanning the plan for every row.
Map<int, ForecastRoutePoint> forecastPointsByWaypoint(
  List<ForecastRoutePoint> points,
) => {for (final point in points) ?point.waypointIndex: point};

/// Navigation waypoints projected into the weather plan's input type.
List<ForecastWaypoint> _forecastWaypoints(List<NavigationPoint> points) => [
  for (final point in points)
    (
      latitude: point.latitude,
      longitude: point.longitude,
      altitudeFeet: point.weatherAltitudeFeet,
    ),
];

@riverpod
class FlightWeatherQuery extends _$FlightWeatherQuery {
  /// Extend only the query that produced the timing result. The next plan
  /// rebuild computes its own ordinary window.
  void extendFor(ForecastQuery query, DateTime arrival) {
    if (state != query) return;
    final now = clock.now().toUtc();
    // Keep extensions within the departure picker's planning horizon.
    final horizon = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 4));
    final needed = DateTime.utc(
      arrival.year,
      arrival.month,
      arrival.day,
      arrival.hour,
    ).add(forecastTimeReserve + const Duration(hours: 1));
    final end = needed.isBefore(horizon) ? needed : horizon;
    if (end.isAfter(query.end)) {
      state = ForecastQuery(query.locations.values, query.start, end);
    }
  }

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
        for (final point in points.skip(1))
          point.profileLocation ?? point.location,
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
  await ref.read(deferredStartupTasksProvider).waitFor(StartupTask.weather);
  if (!ref.mounted) return null;
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
  await ref.read(deferredStartupTasksProvider).waitFor(StartupTask.weather);
  if (!ref.mounted) return (terrainMeters: null, airportMeters: null);
  final terrainFuture = _ignoreErrors(
    ref.watch(forecastPointTerrainProvider(point.location).future),
    'Could not load terrain for $pointId',
  );
  final airportId = waypoint?.airportId;
  final country = waypoint?.airportCountry;
  final airportFuture = airportId != null && airportId.isNotEmpty
      ? _ignoreErrors(
          ref.watch(airportMetadataProvider(airportId, country ?? '').future),
          'Could not load airport elevation for $airportId',
        )
      : null;
  final terrain = await terrainFuture;
  final airport = await airportFuture;
  return (terrainMeters: terrain, airportMeters: airport?.elevation?.metersMsl);
}

typedef _ReferenceInput = ({
  ForecastLocation location,
  String? airportId,
  String? country,
});

_ReferenceInput _referenceInput(
  ForecastRoutePoint point,
  List<NavigationPoint> route,
) {
  final index = point.waypointIndex;
  final waypoint = index != null && index < route.length ? route[index] : null;
  return (
    location: point.location,
    airportId: waypoint?.airportId,
    country: waypoint?.airportCountry,
  );
}

class _RouteForecastReferences
    extends UnmodifiableMapView<String, ForecastReference> {
  _RouteForecastReferences(super.references, this.inputs);
  final Map<String, _ReferenceInput> inputs;
}

/// A refreshing AsyncValue may retain references from a different route.
/// Reuse each reference only for the location and airport that produced it.
ForecastReference? currentForecastReference(
  AsyncValue<Map<String, ForecastReference>> references,
  ForecastRoutePoint point,
  List<NavigationPoint> route,
) {
  final values = references.value;
  if (values is _RouteForecastReferences) {
    return values.inputs[point.id] == _referenceInput(point, route)
        ? values[point.id]
        : null;
  }
  return references.isLoading ? null : values?[point.id];
}

/// References for every plan point, resolved through
/// [routeForecastReferenceProvider].
@riverpod
Future<Map<String, ForecastReference>> routeForecastReferences(Ref ref) async {
  final points = ref.watch(flightWeatherPlanProvider);
  final route =
      ref.watch(navigationProvider).value?.points ?? const <NavigationPoint>[];
  final inputs = {
    for (final point in points) point.id: _referenceInput(point, route),
  };
  final references = await Future.wait([
    for (final point in points)
      ref.watch(routeForecastReferenceProvider(point.id).future),
  ]);
  return _RouteForecastReferences({
    for (final (index, point) in points.indexed) point.id: references[index],
  }, inputs);
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
