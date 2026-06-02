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
  static const double maxGpsVerticalAccuracyMeters = 30.0;

  /// Threshold difference in hPa to trigger a QNH settings update.
  static const double qnhUpdateThresholdHpa = 0.1;

  /// Calculates barometric altitude in meters for a given air pressure (in Pa)
  /// and reference sea-level pressure (in hPa, e.g., QNH).
  ///
  /// Uses the US Standard Atmosphere formula:
  /// h = 44330.77 * (1.0 - (p / p0)^0.190284)
  static double pressureToAltitudeMeters(double pressurePa, double referencePressureHpa) {
    final double refPressurePa = referencePressureHpa * 100.0;
    return 44330.77 * (1.0 - math.pow(pressurePa / refPressurePa, 0.190284));
  }

  /// Calculates the reference pressure (QNH) in hPa for a given measured air pressure (in Pa)
  /// at a known altitude (in meters).
  static double altitudeToQnhHpa(double pressurePa, double altitudeMeters) {
    final double base = (1.0 - (altitudeMeters / 44330.77)).clamp(0.0001, 1.0);
    final double power = math.pow(base, 1.0 / 0.190284).toDouble();
    return (pressurePa / 100.0) / power;
  }
}
