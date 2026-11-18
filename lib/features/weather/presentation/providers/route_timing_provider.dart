import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../route/presentation/providers/navigation_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/domain/models/resolved_altitude.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_profile.dart';
import '../../domain/forecast_query.dart';
import '../../domain/forecast_route.dart';
import '../../domain/wind_route_timing.dart';
import 'flight_weather_provider.dart';

part 'route_timing_provider.g.dart';

typedef _GpsFix = ({ForecastLocation location, DateTime time});

@riverpod
class NavigationGroundTrackNotifier extends _$NavigationGroundTrackNotifier {
  _GpsFix? _previous;
  GroundTrack? _track;

  @override
  GroundTrack? build() {
    final telemetry = ref.watch(
      throttledTelemetryProvider.select(
        (s) => (
          latitude: s.latitude,
          longitude: s.longitude,
          isFlying: s.isFlying,
          gpsLastFixAt: s.gpsLastFixAt,
          gpsHorizontalAccuracy: s.gpsHorizontalAccuracy,
          groundSpeed: s.groundSpeed,
        ),
      ),
    );
    if (!telemetry.isFlying) {
      _previous = null;
      return _track = null;
    }
    final now = ref.watch(flightWeatherClockProvider).value ?? clock.now();
    final latitude = telemetry.latitude;
    final longitude = telemetry.longitude;
    final measuredAt = telemetry.gpsLastFixAt;
    final speed = telemetry.groundSpeed;
    if (latitude == null ||
        longitude == null ||
        measuredAt == null ||
        now.difference(measuredAt) > const Duration(seconds: 15) ||
        speed == null ||
        !speed.isFinite ||
        speed <= 0) {
      _previous = null;
      return _track = null;
    }
    final previous = _previous;
    if (previous != null && !measuredAt.isAfter(previous.time)) return _track;
    final location = (latitude: latitude, longitude: longitude);
    _previous = (location: location, time: measuredAt);
    if (previous == null ||
        measuredAt.difference(previous.time) > const Duration(seconds: 15)) {
      return _track = null;
    }

    final moved = GeoUtils.distanceBetween(
      previous.location.latitude,
      previous.location.longitude,
      latitude,
      longitude,
    );
    final accuracy = telemetry.gpsHorizontalAccuracy ?? 0;
    if (moved < (accuracy > 20 ? accuracy : 20)) return _track = null;

    final bearing = forecastBearing(previous.location, location);
    final track = _track;
    if (track == null ||
        trackDifference(bearing, track.bearing) > maxGpsTrackDifference) {
      return _track = (speedMs: speed, bearing: bearing);
    }
    final turn = (bearing - track.bearing + 180) % 360 - 180;
    return _track = (
      speedMs: track.speedMs + 0.4 * (speed - track.speedMs),
      bearing: (track.bearing + 0.4 * turn) % 360,
    );
  }
}

typedef WindTimingKey = ({
  List<NavigationPoint> route,
  DateTime? plannedDeparture,
  int? defaultAltitude,
  double profileTas,
  bool flying,
});

typedef _WindTimingInput = ({
  List<ForecastRoutePoint> points,
  double profileTas,
  double? gpsSpeed,
  GroundTrack? groundTrack,
  double? currentAltitudeMeters,
  Map<String, ({ForecastProfile series, ForecastReference? reference})>
  profiles,
});

typedef WindTimingResult = ({
  WindTimingKey key,
  Map<String, TimedRoutePoint> timing,
  Map<String, ForecastLocation> locations,
});

Map<String, TimedRoutePoint> _calculateWindTiming(_WindTimingInput input) =>
    calculateWindRouteTiming(
      points: input.points,
      profileTas: input.profileTas,
      gpsSpeed: input.gpsSpeed,
      groundTrack: input.groundTrack,
      currentAltitudeMeters: input.currentAltitudeMeters,
      windAt: (point, time, altitudeMeters) {
        final profile = input.profiles[point.id];
        if (altitudeMeters == null || profile == null) return null;
        final reference = profile.reference;
        return profile.series.windAt(
          time,
          altitudeMeters,
          terrainMeters: reference?.terrainMeters ?? reference?.airportMeters,
        );
      },
    );

@riverpod
WindTimingKey _windTimingKey(Ref ref) => (
  route:
      ref.watch(navigationProvider).value?.points ?? const <NavigationPoint>[],
  plannedDeparture: ref.watch(flightDepartureProvider),
  defaultAltitude: ref.watch(selectedAircraftProvider)?.weatherAltitudeFeet,
  profileTas: ref.watch(cruiseSpeedProvider),
  flying: ref.watch(throttledTelemetryProvider.select((s) => s.isFlying)),
);

@riverpod
class RouteWindTimingNotifier extends _$RouteWindTimingNotifier {
  Future<Map<String, TimedRoutePoint>>? _running;
  int _revision = 0;

  @override
  Future<WindTimingResult?> build() async {
    final revision = ++_revision;
    final points = ref.watch(flightWeatherPlanProvider);
    if (points.isEmpty || points.first.id != 'origin') return null;
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
    );
    if (!enabled) return null;
    final profiles = ref.watch(flightForecastProfilesProvider).value;
    if (profiles == null || profiles.series.isEmpty) return null;

    final key = ref.watch(_windTimingKeyProvider);
    final telemetry = ref.watch(
      throttledTelemetryProvider.select(
        (s) => (
          isFlying: s.isFlying,
          groundSpeed: s.groundSpeed,
          airPressure: s.airPressure,
          gpsAltitude: s.gpsAltitude,
          isGpsDroneCan: s.isGpsDroneCan,
        ),
      ),
    );
    final reportedSpeed = telemetry.groundSpeed;
    final gpsSpeed =
        telemetry.isFlying &&
            reportedSpeed != null &&
            reportedSpeed.isFinite &&
            reportedSpeed > 0
        ? reportedSpeed
        : null;
    final track = ref.watch(navigationGroundTrackProvider);
    final qnh = track == null
        ? null
        : ref.watch(appSettingsProvider.select((s) => s.value?.qnh));
    final altitude = track == null
        ? null
        : AltitudeResolver.resolve(
            airPressure: telemetry.airPressure,
            gpsAltitude: telemetry.gpsAltitude,
            isGpsDroneCan: telemetry.isGpsDroneCan,
            qnh: qnh,
          ).mslValue;
    final locations = ref.watch(flightWeatherProfileLocationsProvider);
    final references = await ref.watch(routeForecastReferencesProvider.future);

    // While an isolate is running, intermediate requests can be superseded.
    final running = _running;
    if (running != null) {
      try {
        await running;
      } catch (_) {
        // The request that started the isolate handles its failure.
      }
      if (!ref.mounted || revision != _revision) return null;
    }

    final input = (
      points: points,
      profileTas: key.profileTas,
      gpsSpeed: gpsSpeed,
      groundTrack: track,
      currentAltitudeMeters: altitude,
      profiles: {
        for (final point in points)
          if (profiles.series[forecastLocationKey(
                locations[point.id] ?? point.location,
              )]
              case final series?)
            point.id: (series: series, reference: references[point.id]),
      },
    );
    final job = compute(
      _calculateWindTiming,
      input,
      debugLabel: 'Calculate wind-adjusted route ETA',
    );
    _running = job;
    try {
      final timing = await job;
      if (!ref.mounted || revision != _revision) return null;
      return (
        key: key,
        timing: timing,
        locations: {for (final point in points) point.id: point.location},
      );
    } catch (error) {
      debugPrint('Could not calculate wind-adjusted ETA: ${error.runtimeType}');
      return null;
    } finally {
      if (identical(_running, job)) _running = null;
    }
  }
}

@riverpod
Map<String, TimedRoutePoint> routePointTiming(Ref ref) {
  final points = ref.watch(flightWeatherPlanProvider);
  if (points.isEmpty || points.first.id != 'origin') return const {};
  final key = ref.watch(_windTimingKeyProvider);
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  final result = enabled ? ref.watch(routeWindTimingProvider).value : null;
  final usable = result?.key == key ? result : null;
  final gps = ref.watch(
    throttledTelemetryProvider.select((s) => s.groundSpeed),
  );
  final source = key.flying && gps != null && gps.isFinite && gps > 0
      ? RouteTimingSource.gps
      : RouteTimingSource.profile;

  return {
    for (final point in points)
      point.id: usable?.locations[point.id] == point.location
          ? usable!.timing[point.id]!
          : (
              eta: point.eta,
              duration: point.duration,
              sources: point.id == 'origin'
                  ? const <RouteTimingSource>{}
                  : {source},
              windEffect: null,
            ),
  };
}
