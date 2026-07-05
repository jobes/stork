import 'dart:math' as math;
import 'package:maplibre/maplibre.dart';

/// A collection of utility functions for geographical calculations.
class GeoUtils {
  /// Earth's mean radius in meters.
  static const double earthRadiusMeters = 6371000;

  /// Calculates the destination point from a given [start] point,
  /// traveling along a great circle path with a given initial [headingDegrees]
  /// for a specified [distanceMeters].
  ///
  /// Uses the Haversine formula for the calculation.
  ///
  /// Parameters:
  /// - [start]: The starting coordinate.
  /// - [headingDegrees]: The initial bearing in degrees from North.
  /// - [distanceMeters]: The distance to travel in meters.
  ///
  /// Returns a new [Geographic] representing the destination coordinate.
  static Geographic calculateDestination(
    Geographic start,
    double headingDegrees,
    double distanceMeters,
  ) {
    final startLatRad = _degreesToRadians(start.lat);
    final startLonRad = _degreesToRadians(start.lon);
    final headingRad = _degreesToRadians(headingDegrees);

    final angularDistance = distanceMeters / earthRadiusMeters;

    final destLatRad = math.asin(
      math.sin(startLatRad) * math.cos(angularDistance) +
          math.cos(startLatRad) *
              math.sin(angularDistance) *
              math.cos(headingRad),
    );

    final destLonRad =
        startLonRad +
        math.atan2(
          math.sin(headingRad) *
              math.sin(angularDistance) *
              math.cos(startLatRad),
          math.cos(angularDistance) -
              math.sin(startLatRad) * math.sin(destLatRad),
        );

    // Normalize longitude to be between -pi and +pi
    final normalizedLonRad =
        (destLonRad + 3 * math.pi) % (2 * math.pi) - math.pi;

    return Geographic(
      lat: _radiansToDegrees(destLatRad),
      lon: _radiansToDegrees(normalizedLonRad),
    );
  }

  /// Calculates the distance in meters between two geographical points
  /// using the Haversine formula.
  static double distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2) +
                math.cos(_degreesToRadians(lat1)) *
                    math.cos(_degreesToRadians(lat2)) *
                    math.sin(dLon / 2) *
                    math.sin(dLon / 2))
            .clamp(0.0, 1.0);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Checks if a point ([lon], [lat]) is inside any of the given [polygons].
  ///
  /// Each polygon is represented as a list of rings (`List<List<double>>`),
  /// where the first ring is the exterior boundary and subsequent rings are holes.
  /// A point is inside if it is inside the exterior boundary and NOT inside any holes.
  static bool isPointInPolygons(
    double lon,
    double lat,
    List<List<List<List<double>>>> polygons,
  ) {
    for (final List<List<List<double>>> polygon in polygons) {
      if (polygon.isEmpty) continue;
      // Check exterior ring
      if (isPointInRing(lon, lat, polygon[0])) {
        // Check interior rings (holes)
        bool insideHole = false;
        for (int i = 1; i < polygon.length; i++) {
          if (isPointInRing(lon, lat, polygon[i])) {
            insideHole = true;
            break;
          }
        }
        if (!insideHole) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if a point ([lon], [lat]) is inside a single [ring] using the ray-casting algorithm.
  ///
  /// The [ring] is a list of points where each point is `[lon, lat]`.
  static bool isPointInRing(double lon, double lat, List<List<double>> ring) {
    bool inside = false;
    final int len = ring.length;
    if (len < 3) return false;
    int j = len - 1;
    for (int i = 0; i < len; i++) {
      final List<double> pi = ring[i];
      final List<double> pj = ring[j];
      final double xi = pi[0];
      final double yi = pi[1];
      final double xj = pj[0];
      final double yj = pj[1];

      final bool intersect =
          ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  /// Calculates the minimum distance from a point (lat, lon) to a segment defined by (lat1, lon1) and (lat2, lon2).
  static double distanceToSegment(
    double lat,
    double lon,
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double dx = lon2 - lon1;
    final double dy = lat2 - lat1;
    if (dx == 0 && dy == 0) {
      return distanceBetween(lat, lon, lat1, lon1);
    }
    final double t =
        (((lon - lon1) * dx + (lat - lat1) * dy) / (dx * dx + dy * dy)).clamp(
          0.0,
          1.0,
        );
    final double closestLon = lon1 + t * dx;
    final double closestLat = lat1 + t * dy;
    return distanceBetween(lat, lon, closestLat, closestLon);
  }

  /// Calculates the minimum distance from a point (lat, lon) to a list of polygons.
  /// If the point is inside the polygons, returns 0.0.
  static double distanceToPolygons(
    double lat,
    double lon,
    List<List<List<List<double>>>> polygons,
  ) {
    if (isPointInPolygons(lon, lat, polygons)) {
      return 0.0;
    }
    double minDistance = double.infinity;
    for (final polygon in polygons) {
      if (polygon.isEmpty) continue;
      final exteriorRing = polygon[0];
      for (int i = 0; i < exteriorRing.length; i++) {
        final p1 = exteriorRing[i];
        final p2 = exteriorRing[(i + 1) % exteriorRing.length];
        final dist = distanceToSegment(lat, lon, p1[1], p1[0], p2[1], p2[0]);
        if (dist < minDistance) {
          minDistance = dist;
        }
      }
    }
    return minDistance == double.infinity ? 0.0 : minDistance;
  }
}
