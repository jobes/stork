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

  /// Minimum vertical accuracy threshold to filter out false/mock GPS positions.
  static const double minGpsVerticalAccuracyMeters = 1.0;

  /// Maximum acceptable vertical accuracy error for a reliable GPS altitude fix.
  static const double maxGpsVerticalAccuracyMeters = 20.0;

  /// Threshold difference in hPa to trigger a QNH settings update.
  static const double qnhUpdateThresholdHpa = 0.1;

  /// The exponent used in the barometric formula.
  /// Derived from physical constants: g * M / (R * L) = 5.255877
  static const double barometricExponent = 5.255877;

  /// The inverse exponent used for pressure-to-altitude calculation.
  static const double inverseBarometricExponent = 1.0 / barometricExponent;

  /// Calculates barometric altitude in meters for a given air pressure (in Pa)
  /// and reference sea-level pressure (in hPa, e.g., QNH).
  ///
  /// Uses the US Standard Atmosphere formula:
  /// h = 44330.77 * (1.0 - (p / p0)^inverseBarometricExponent)
  static double pressureToAltitudeMeters(double pressurePa, double referencePressureHpa) {
    final double refPressurePa = referencePressureHpa * 100.0;
    return 44330.77 * (1.0 - math.pow(pressurePa / refPressurePa, inverseBarometricExponent));
  }

  /// Calculates the reference pressure (QNH) in hPa for a given measured air pressure (in Pa)
  /// at a known altitude (in meters).
  static double altitudeToQnhHpa(double pressurePa, double altitudeMeters) {
    final double base = (1.0 - (altitudeMeters / 44330.77)).clamp(0.0001, 1.0);
    final double power = math.pow(base, barometricExponent).toDouble();
    return (pressurePa / 100.0) / power;
  }
}
