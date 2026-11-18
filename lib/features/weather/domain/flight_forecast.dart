import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_forecast.freezed.dart';

const forecastPointInterval = Duration(minutes: 10);
const forecastWaypointMargin = Duration(minutes: 2);
const forecastRefreshInterval = Duration(minutes: 30);
const forecastTimeReserve = Duration(hours: 1);
const forecastNearbyRefreshDistanceMeters = 3000.0;
const feetInMeters = 0.3048;

typedef ForecastLocation = ({double latitude, double longitude});

double _interpolate(double a, double b, double fraction) =>
    a + (b - a) * fraction;

class ForecastWind {
  final double east;
  final double north;

  const ForecastWind(this.east, this.north);

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
    _interpolate(east, other.east, fraction),
    _interpolate(north, other.north, fraction),
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
