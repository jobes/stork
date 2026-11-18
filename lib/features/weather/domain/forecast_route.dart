import 'dart:math' as math;

import 'package:maplibre/maplibre.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/geo_utils.dart';
import '../../navigation/domain/models/navigation_point.dart';
import 'flight_forecast.dart';

part 'forecast_route.freezed.dart';

@freezed
abstract class ForecastRoutePoint with _$ForecastRoutePoint {
  const factory ForecastRoutePoint({
    required String id,
    required ForecastLocation location,
    required DateTime eta,
    required Duration duration,
    required double distanceMeters,
    required double? altitudeFeet,
    double? bearing,
    int? waypointIndex,
  }) = _ForecastRoutePoint;
}

typedef _RouteLeg = ({
  ForecastLocation start,
  ForecastLocation end,
  double distance,
  double cumulative,
  double bearing,
});
typedef _RouteSample = ({int leg, double fraction, ForecastLocation location});

double _distance(ForecastLocation a, ForecastLocation b) =>
    GeoUtils.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);

double forecastBearing(ForecastLocation a, ForecastLocation b) {
  const radians = math.pi / 180;
  final lat1 = a.latitude * radians;
  final lat2 = b.latitude * radians;
  final lonDiff = (b.longitude - a.longitude) * radians;
  return (math.atan2(
            math.sin(lonDiff) * math.cos(lat2),
            math.cos(lat1) * math.sin(lat2) -
                math.sin(lat1) * math.cos(lat2) * math.cos(lonDiff),
          ) /
          radians) %
      360;
}

ForecastLocation waypointLocation(NavigationPoint point) =>
    (latitude: point.latitude, longitude: point.longitude);

class ForecastRoute {
  final ForecastLocation origin;
  final List<_RouteLeg> _legs;
  final List<_RouteSample> _samples;
  final double planningSpeed;

  ForecastRoute._(this.origin, this._legs, this._samples, this.planningSpeed);

  factory ForecastRoute.plan(
    ForecastLocation origin,
    List<NavigationPoint> points,
    double speed,
  ) {
    final legs = <_RouteLeg>[];
    var start = origin;
    var cumulative = 0.0;
    for (final point in points) {
      final end = waypointLocation(point);
      final distance = _distance(start, end);
      cumulative += distance;
      legs.add((
        start: start,
        end: end,
        distance: distance,
        cumulative: cumulative,
        bearing: forecastBearing(start, end),
      ));
      start = end;
    }
    final samples = <_RouteSample>[];
    final step = forecastPointInterval.inSeconds * speed;
    final margin = forecastWaypointMargin.inSeconds * speed;
    var nextDistance = step;
    for (final (index, leg) in legs.indexed) {
      final legStart = leg.cumulative - leg.distance;
      while (step > 0 && nextDistance < leg.cumulative) {
        final fromStart = nextDistance - legStart;
        if (fromStart > margin && leg.cumulative - nextDistance > margin) {
          final position = GeoUtils.calculateDestination(
            Geographic(lat: leg.start.latitude, lon: leg.start.longitude),
            leg.bearing,
            fromStart,
          );
          samples.add((
            leg: index,
            fraction: fromStart / leg.distance,
            location: (latitude: position.lat, longitude: position.lon),
          ));
        }
        nextDistance += step;
      }
    }
    return ForecastRoute._(origin, legs, samples, speed);
  }

  bool matches(List<NavigationPoint> points) {
    if (points.isEmpty || points.length > _legs.length) return false;
    final offset = _legs.length - points.length;
    for (final (i, point) in points.indexed) {
      if (_legs[offset + i].end != waypointLocation(point)) return false;
    }
    return true;
  }

  int offsetFor(List<NavigationPoint> points) => _legs.length - points.length;

  List<ForecastRoutePoint> forecastPoints({
    required ForecastLocation position,
    required List<NavigationPoint> points,
    required DateTime departure,
    required double groundSpeed,
    required bool flying,
    required int? defaultAltitudeFeet,
    int? previousWaypointAltitudeFeet,
  }) {
    if (points.isEmpty) {
      return [
        ForecastRoutePoint(
          id: 'aircraft',
          location: position,
          eta: departure,
          duration: Duration.zero,
          distanceMeters: 0,
          altitudeFeet: defaultAltitudeFeet?.toDouble(),
        ),
      ];
    }
    final offset = offsetFor(points);
    final first = _legs[offset];
    final origin = position;
    final remainingFirst = _distance(origin, first.end);
    final distances = <double>[];
    final result = <ForecastRoutePoint>[];
    var distance = remainingFirst;

    ForecastRoutePoint point({
      required String id,
      required ForecastLocation location,
      required double distance,
      required double? feet,
      double? bearing,
      int? waypoint,
    }) {
      final duration = Duration(seconds: (distance / groundSpeed).round());
      return ForecastRoutePoint(
        id: id,
        location: location,
        eta: departure.add(duration),
        duration: duration,
        distanceMeters: distance,
        altitudeFeet: feet,
        bearing: bearing,
        waypointIndex: waypoint,
      );
    }

    double? altitude(int index) =>
        (points[index].weatherAltitudeFeet ?? defaultAltitudeFeet)?.toDouble();

    final firstStartHeight =
        (previousWaypointAltitudeFeet ?? defaultAltitudeFeet)?.toDouble();

    double? heightBetween(double? start, double? end, double fraction) =>
        start != null && end != null ? start + (end - start) * fraction : null;

    final originFraction = flying && first.distance > 0
        ? (1 - remainingFirst / first.distance).clamp(0.0, 1.0)
        : 0.0;
    result.add(
      point(
        id: 'origin',
        location: origin,
        distance: 0,
        feet: originFraction == 0
            ? firstStartHeight
            : heightBetween(firstStartHeight, altitude(0), originFraction),
        bearing: forecastBearing(origin, first.end),
      ),
    );
    for (final (index, waypoint) in points.indexed) {
      final leg = _legs[index + offset];
      if (index > 0) distance += leg.distance;
      distances.add(distance);
      result.add(
        point(
          id: 'waypoint-${index + offset}',
          location: waypointLocation(waypoint),
          distance: distance,
          feet: altitude(index),
          waypoint: index,
          bearing: index == 0 ? forecastBearing(origin, leg.end) : leg.bearing,
        ),
      );
    }
    for (final (index, sample) in _samples.indexed) {
      final legIndex = sample.leg - offset;
      if (legIndex < 0) continue;
      final leg = _legs[sample.leg];
      final sampleDistance =
          distances[legIndex] - (1 - sample.fraction) * leg.distance;
      if (sampleDistance <= 0) continue;
      final startHeight = legIndex == 0
          ? firstStartHeight
          : altitude(legIndex - 1);
      final height = heightBetween(
        startHeight,
        altitude(legIndex),
        sample.fraction,
      );
      result.add(
        point(
          id: 'sample-$index',
          location: sample.location,
          distance: sampleDistance,
          feet: height,
          bearing: forecastBearing(sample.location, leg.end),
        ),
      );
    }
    return result;
  }
}
