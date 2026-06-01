import '../../../settings/domain/app_settings.dart';
import '../../../../core/utils/aviation_math.dart';
import 'telemetry_state.dart';

/// Represents the source of active altitude data.
enum AltitudeSource {
  baro,
  gpsDroneCan,
  gpsPhone,
  none,
}

/// Represents the resolved altitude and flight level values with their active source.
class ResolvedAltitude {
  /// The MSL altitude value in meters, or null if not available.
  final double? mslValue;

  /// The standard pressure-altitude (Flight Level) value, or null if not available.
  /// Typically calculated as (Pressure Altitude in Feet) / 100.
  final double? flightLevel;

  /// The active source from which the altitude is computed.
  final AltitudeSource source;

  const ResolvedAltitude({
    this.mslValue,
    this.flightLevel,
    required this.source,
  });
}

/// Extension on [TelemetryState] to resolve altitude source and values.
extension TelemetryAltitudeExtension on TelemetryState {
  /// Returns the active [AltitudeSource] based on available telemetry fields.
  AltitudeSource get altitudeSource {
    if (airPressure != null) {
      return AltitudeSource.baro;
    } else if (gpsAltitude != null) {
      return isGpsDroneCan ? AltitudeSource.gpsDroneCan : AltitudeSource.gpsPhone;
    }
    return AltitudeSource.none;
  }

  /// Resolves the MSL altitude and flight level based on telemetry state and app settings.
  ResolvedAltitude resolveAltitude(AppSettings? settings) {
    final source = altitudeSource;
    if (settings == null) {
      return ResolvedAltitude(source: source);
    }

    double? mslValue;
    double? flightLevel;

    if (airPressure != null) {
      // Flight Level is ALWAYS pressure altitude based on standard sea-level pressure (1013.25 hPa)
      final double stdAltMeters = AviationMath.pressureToAltitudeMeters(
        airPressure!,
        AviationMath.standardPressureHpa,
      );
      final double stdAltFeet = stdAltMeters * 3.28084;
      flightLevel = stdAltFeet / 100.0;

      // QNH-based altitude
      mslValue = AviationMath.pressureToAltitudeMeters(
        airPressure!,
        settings.qnh,
      );
    } else if (gpsAltitude != null) {
      final double gpsFeet = gpsAltitude! * 3.28084;
      flightLevel = gpsFeet / 100.0;
      mslValue = gpsAltitude;
    }

    return ResolvedAltitude(
      mslValue: mslValue,
      flightLevel: flightLevel,
      source: source,
    );
  }
}
