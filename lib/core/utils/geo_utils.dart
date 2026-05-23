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
          math.cos(startLatRad) * math.sin(angularDistance) * math.cos(headingRad),
    );

    final destLonRad = startLonRad +
        math.atan2(
          math.sin(headingRad) * math.sin(angularDistance) * math.cos(startLatRad),
          math.cos(angularDistance) - math.sin(startLatRad) * math.sin(destLatRad),
        );

    // Normalize longitude to be between -pi and +pi
    final normalizedLonRad = (destLonRad + 3 * math.pi) % (2 * math.pi) - math.pi;

    return Geographic(
      lat: _radiansToDegrees(destLatRad),
      lon: _radiansToDegrees(normalizedLonRad),
    );
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }
}
