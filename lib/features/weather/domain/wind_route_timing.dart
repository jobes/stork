import 'dart:math' as math;

import 'flight_forecast.dart';
import 'forecast_route.dart';

enum RouteTimingSource { profile, gps, wind, incompleteWind, blocked }

typedef GroundTrack = ({double speedMs, double bearing});
typedef TimedRoutePoint = ({
  DateTime? eta,
  Duration? duration,
  Set<RouteTimingSource> sources,
  Duration? windEffect,
});
typedef RouteWindLookup = ForecastWind? Function(
  ForecastRoutePoint point,
  DateTime time,
  double? altitudeMeters,
);

const double maxGpsTrackDifference = 30;

double trackDifference(double a, double b) => ((a - b + 180) % 360 - 180).abs();

double tasFromGroundTrack(GroundTrack track, ForecastWind wind) {
  final angle = track.bearing * math.pi / 180;
  final east = track.speedMs * math.sin(angle) - wind.east;
  final north = track.speedMs * math.cos(angle) - wind.north;
  return math.sqrt(east * east + north * north);
}

double? groundSpeedForTrack(double tas, ForecastWind wind, double bearing) {
  final components = wind.relativeTo(bearing);
  if (components.fromRight.abs() > tas) return null;
  final speed =
      math.sqrt(tas * tas - components.fromRight * components.fromRight) -
      components.headwind;
  return speed > 1e-6 ? speed : null;
}

Map<String, TimedRoutePoint> calculateWindRouteTiming({
  required List<ForecastRoutePoint> points,
  required double profileTas,
  required double? gpsSpeed,
  required GroundTrack? groundTrack,
  required double? currentAltitudeMeters,
  required RouteWindLookup windAt,
}) {
  if (points.isEmpty) return const {};
  final origin = points.first;
  final waypoints = points.where((point) => point.waypointIndex != null);
  final firstWaypoint = waypoints.firstOrNull;
  final endOfFirstLeg = firstWaypoint?.distanceMeters ?? 0;
  final pointsByDistance = points.skip(1).toList()
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  final currentWind = groundTrack == null || currentAltitudeMeters == null
      ? null
      : windAt(origin, origin.eta, currentAltitudeMeters);
  final measuredTas = currentWind == null || groundTrack == null
      ? null
      : tasFromGroundTrack(groundTrack, currentWind);
  final validMeasuredTas =
      measuredTas != null && measuredTas.isFinite && measuredTas > 0
      ? measuredTas
      : null;

  final results = <String, TimedRoutePoint>{
    origin.id: (
      eta: origin.eta,
      duration: Duration.zero,
      sources: const {},
      windEffect: null,
    ),
  };
  var previous = origin;
  var elapsedSeconds = 0.0;
  var windEffectSeconds = 0.0;
  var hasWindEffect = false;
  var blocked = false;
  final sources = <RouteTimingSource>{};
  Duration duration(double seconds) => Duration(seconds: seconds.round());

  for (final point in pointsByDistance) {
    final distance = point.distanceMeters - previous.distanceMeters;
    if (!blocked && distance > 0) {
      final bearing = forecastBearing(previous.location, point.location);
      final onCurrentTrack =
          groundTrack != null &&
          point.distanceMeters <= endOfFirstLeg &&
          trackDifference(groundTrack.bearing, bearing) <=
              maxGpsTrackDifference;
      final anchoredTas = onCurrentTrack ? validMeasuredTas : null;
      final tas = anchoredTas ?? profileTas;
      final gpsFallback = onCurrentTrack ? groundTrack.speedMs : gpsSpeed;
      var seconds = distance / (gpsFallback ?? profileTas);
      var source = gpsFallback == null
          ? RouteTimingSource.profile
          : RouteTimingSource.gps;
      var forecastApplied = false;

      // A second midpoint sample accounts for the time shift caused by the first estimate.
      for (var pass = 0; pass < 2; pass++) {
        final at = origin.eta.add(duration(elapsedSeconds + seconds / 2));
        final a = windAt(previous, at, _plannedAltitude(previous));
        final b = windAt(point, at, _plannedAltitude(point));
        if (a == null || b == null) {
          // Keep the first estimate if its shifted midpoint is unavailable.
          forecastApplied = false;
          sources.add(RouteTimingSource.incompleteWind);
          source = gpsFallback == null
              ? RouteTimingSource.profile
              : RouteTimingSource.gps;
          break;
        }
        final wind = a.interpolate(b, 0.5);
        final speed = groundSpeedForTrack(tas, wind, bearing);
        if (speed == null) {
          blocked = true;
          source = RouteTimingSource.blocked;
          break;
        }
        seconds = distance / speed;
        source = RouteTimingSource.wind;
        forecastApplied = true;
      }

      sources.add(source);
      if (!blocked && forecastApplied) {
        if (anchoredTas != null) sources.add(RouteTimingSource.gps);
        windEffectSeconds += seconds - distance / tas;
        hasWindEffect = true;
      }
      if (!blocked) elapsedSeconds += seconds;
    }

    final elapsed = blocked ? null : duration(elapsedSeconds);
    results[point.id] = (
      eta: elapsed == null ? null : origin.eta.add(elapsed),
      duration: elapsed,
      sources: Set.unmodifiable(sources),
      windEffect: blocked || !hasWindEffect
          ? null
          : duration(windEffectSeconds),
    );
    previous = point;
  }
  return results;
}

double? _plannedAltitude(ForecastRoutePoint point) {
  final feet = point.altitudeFeet;
  return feet == null ? null : feet * feetInMeters;
}
