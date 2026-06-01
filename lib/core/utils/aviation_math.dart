import 'dart:math' as math;

/// A collection of utility functions for aviation-related calculations.
class AviationMath {
  /// Standard sea-level pressure in Pascals (Pa).
  static const double standardPressurePa = 101325.0;

  /// Standard sea-level pressure in hectopascals (hPa).
  static const double standardPressureHpa = 1013.25;

  /// Minimum allowed QNH value for input.
  static const double minQnhHpa = 800.0;

  /// Maximum allowed QNH value for input.
  static const double maxQnhHpa = 1200.0;

  /// Calculates barometric altitude in meters for a given air pressure (in Pa)
  /// and reference sea-level pressure (in hPa, e.g., QNH).
  ///
  /// Uses the US Standard Atmosphere formula:
  /// h = 44330.77 * (1.0 - (p / p0)^0.190284)
  static double pressureToAltitudeMeters(double pressurePa, double referencePressureHpa) {
    final double refPressurePa = referencePressureHpa * 100.0;
    return 44330.77 * (1.0 - math.pow(pressurePa / refPressurePa, 0.190284));
  }
}
