import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_forecast.freezed.dart';

const forecastPointInterval = Duration(minutes: 10);
const forecastWaypointMargin = Duration(minutes: 2);

/// ICON-EU runs every three hours. A two-hour refresh keeps the data current
/// without re-requesting the same model run.
const forecastRefreshInterval = Duration(hours: 2);

/// The moving aircraft keeps one profile until it has moved this far. The
/// previous profile is still interpolated locally in the meantime.
const forecastOriginRefreshDistanceMeters = 10000.0;

/// Route samples stay between five and twenty kilometres apart. The lower
/// bound avoids excessive samples for slow aircraft, the upper bound keeps
/// fast aircraft from skipping model grid cells.
const forecastMinSampleDistanceMeters = 5000.0;
const forecastMaxSampleDistanceMeters = 20000.0;

const forecastTimeReserve = Duration(hours: 1);

/// On the ground a moved origin rebuilds the route geometry.
const forecastNearbyRefreshDistanceMeters = 3000.0;
const feetInMeters = 0.3048;

typedef ForecastLocation = ({double latitude, double longitude});

/// Identifiers used by [ForecastRoutePoint] so every layer recognises the
/// aircraft position, the route origin, waypoints and weather samples.
const forecastAircraftPointId = 'aircraft';
const forecastOriginPointId = 'origin';
String forecastWaypointPointId(int index) => 'waypoint-$index';
String forecastSamplePointId(int index) => 'sample-$index';

/// The aircraft position is the first plan point both with and without a route.
bool isAircraftForecastPoint(String id) =>
    id == forecastOriginPointId || id == forecastAircraftPointId;

double linearInterpolate(double a, double b, double fraction) =>
    a + (b - a) * fraction;

@freezed
abstract class ForecastWind with _$ForecastWind {
  const ForecastWind._();

  const factory ForecastWind(double east, double north) = _ForecastWind;

  factory ForecastWind.fromKmh(double speed, double directionFrom) {
    final angle = directionFrom * math.pi / 180;
    return ForecastWind(
      -speed / 3.6 * math.sin(angle),
      -speed / 3.6 * math.cos(angle),
    );
  }

  double get speedMs => math.sqrt(east * east + north * north);
  double get directionFrom => (math.atan2(-east, -north) * 180 / math.pi) % 360;

  ({double headwind, double fromRight}) relativeTo(double bearing) {
    final angle = bearing * math.pi / 180;
    return (
      headwind: -east * math.sin(angle) - north * math.cos(angle),
      fromRight: north * math.sin(angle) - east * math.cos(angle),
    );
  }

  ForecastWind interpolate(ForecastWind other, double fraction) => ForecastWind(
    linearInterpolate(east, other.east, fraction),
    linearInterpolate(north, other.north, fraction),
  );
}

@freezed
abstract class FlightForecast with _$FlightForecast {
  const factory FlightForecast({
    required ForecastWind? wind,
    required double? temperatureC,
    required double? gustMs,
    required double? precipitationMm,
    required double? lowCloudPercent,
    required double? qnhHpa,
    required double? qfeHpa,
    required DateTime? intervalEnd,
    required DateTime downloadedAt,
    int? weatherCode,
  }) = _FlightForecast;
}
