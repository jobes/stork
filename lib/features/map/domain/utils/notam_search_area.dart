import 'dart:math' as math;

import 'package:maplibre/maplibre.dart';

import '../../../../core/utils/geo_utils.dart';
import '../models/notam_catalog.dart';

const _buffer = 20 * 1852.0;
const _radians = math.pi / 180;
const _epsilon = 0.001;
typedef _Point = ({double x, double y});

/// Tests candidates in a local azimuthal equidistant projection. The center is
/// the GPS fix for a circle, or the great-circle midpoint for a route leg.
class NotamSearchArea {
  NotamSearchArea.circle(Geographic position) : this._(position, 0, 0, true);

  factory NotamSearchArea.leg(Geographic start, Geographic end) {
    final length = GeoUtils.distanceBetween(
      start.lat,
      start.lon,
      end.lat,
      end.lon,
    );
    if (length < _epsilon) return NotamSearchArea.circle(start);
    final direction = _bearing(start, end);
    final midpoint = GeoUtils.calculateDestination(
      start,
      direction / _radians,
      length / 2,
    );
    return NotamSearchArea._(
      midpoint,
      _bearing(midpoint, end),
      length / 2,
      false,
    );
  }

  NotamSearchArea._(this._center, this._direction, double halfLeg, this._circle)
    : _halfLength = halfLeg + _buffer {
    // A spherical cap encloses the rectangle and cheaply rejects distant data.
    final radius = _circle
        ? _buffer
        : math.sqrt(_halfLength * _halfLength + _buffer * _buffer);
    final angular = (radius + _epsilon) / GeoUtils.earthRadiusMeters;
    _latitudeLimit = angular / _radians;
    _longitudeLimit = _center.lat.abs() + _latitudeLimit >= 90
        ? 180
        : math.asin(math.sin(angular) / math.cos(_center.lat * _radians)) /
              _radians;
  }

  final Geographic _center;
  final double _direction;
  final double _halfLength;
  final bool _circle;
  late final double _latitudeLimit;
  late final double _longitudeLimit;

  bool contains(Geographic position) {
    if ((position.lat - _center.lat).abs() > _latitudeLimit ||
        _longitudeDelta(position.lon).abs() > _longitudeLimit) {
      return false;
    }
    return _contains(_project(position.lat, position.lon));
  }

  bool intersects(NotamPolygon polygon) {
    if (GeoUtils.isPointInPolygons(_center.lon, _center.lat, [polygon])) {
      return true;
    }

    // A crossing may occur between vertices, including at a hole's boundary.
    for (final ring in polygon) {
      for (var i = 0; i < ring.length; i++) {
        final a = ring[i];
        final b = ring[(i + 1) % ring.length];
        final ay = a[1] - _center.lat;
        final by = b[1] - _center.lat;
        if (math.min(ay, by) > _latitudeLimit ||
            math.max(ay, by) < -_latitudeLimit) {
          continue;
        }
        // GeoJSON edges are linear in longitude/latitude. Clip around the
        // search area before projecting, including either side of the date line.
        final ax = _longitudeDelta((a[0] + b[0]) / 2) + (a[0] - b[0]) / 2;
        final bx = ax + b[0] - a[0];
        for (final shift in [0.0, -360.0, 360.0]) {
          final first = (x: ax + shift, y: ay);
          final last = (x: bx + shift, y: by);
          final span = _clip(first, last, _longitudeLimit, _latitudeLimit);
          if (span == null) continue;
          final start = _interpolate(first, last, span.start);
          final end = _interpolate(first, last, span.end);
          final distance = math.max(
            (end.y - start.y).abs(),
            (end.x - start.x).abs() * math.cos(_center.lat * _radians),
          );
          // Subdivide sparse GeoJSON edges before projecting their points.
          final steps = math.max(1, (distance / 0.05).ceil());
          var previous = _project(_center.lat + start.y, _center.lon + start.x);
          for (var step = 1; step <= steps; step++) {
            final point = _interpolate(start, end, step / steps);
            final next = _project(_center.lat + point.y, _center.lon + point.x);
            if (_crosses(previous, next)) return true;
            previous = next;
          }
        }
      }
    }
    return false;
  }

  double _longitudeDelta(double lon) => (lon - _center.lon + 540) % 360 - 180;

  _Point _project(double latitude, double longitude) {
    final distance = GeoUtils.distanceBetween(
      _center.lat,
      _center.lon,
      latitude,
      longitude,
    );
    final course = _bearing(
      _center,
      Geographic(lat: latitude, lon: (longitude + 540) % 360 - 180),
    );
    final angle = course - _direction;
    return (x: distance * math.cos(angle), y: distance * math.sin(angle));
  }

  bool _contains(_Point point) => _circle
      ? point.x * point.x + point.y * point.y <=
            (_buffer + _epsilon) * (_buffer + _epsilon)
      : point.x.abs() <= _halfLength + _epsilon &&
            point.y.abs() <= _buffer + _epsilon;

  bool _crosses(_Point a, _Point b) {
    if (!_circle) {
      return _clip(a, b, _halfLength + _epsilon, _buffer + _epsilon) != null;
    }
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared == 0
        ? 0.0
        : (-(a.x * dx + a.y * dy) / lengthSquared).clamp(0.0, 1.0);
    return _contains(_interpolate(a, b, t));
  }

  static _Point _interpolate(_Point a, _Point b, double t) =>
      (x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t);

  /// Clips a line segment against an axis-aligned rectangle.
  static ({double start, double end})? _clip(
    _Point a,
    _Point b,
    double halfWidth,
    double halfHeight,
  ) {
    var start = 0.0;
    var end = 1.0;
    for (final (origin, delta, limit) in [
      (a.x, b.x - a.x, halfWidth),
      (a.y, b.y - a.y, halfHeight),
    ]) {
      if (delta == 0) {
        if (origin.abs() > limit) return null;
        continue;
      }
      final t1 = (-limit - origin) / delta;
      final t2 = (limit - origin) / delta;
      start = math.max(start, math.min(t1, t2));
      end = math.min(end, math.max(t1, t2));
      if (start > end) return null;
    }
    return (start: start, end: end);
  }

  static double _bearing(Geographic from, Geographic to) {
    final fromLat = from.lat * _radians;
    final toLat = to.lat * _radians;
    final deltaLon = (to.lon - from.lon) * _radians;
    return math.atan2(
      math.sin(deltaLon) * math.cos(toLat),
      math.cos(fromLat) * math.sin(toLat) -
          math.sin(fromLat) * math.cos(toLat) * math.cos(deltaLon),
    );
  }
}
