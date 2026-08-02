import 'package:freezed_annotation/freezed_annotation.dart';

part 'gdl90_target.freezed.dart';

/// A single aircraft decoded from a GDL90 Traffic or Ownship report.
@freezed
abstract class Gdl90Target with _$Gdl90Target {
  const Gdl90Target._();

  const factory Gdl90Target({
    required String id, // ICAO 24-bit Hex address or unique string identifier
    String? callsign,
    required double latitude, // Degrees (-90.0 to 90.0)
    required double longitude, // Degrees (-180.0 to 180.0)
    required double altitudeFeet, // Altitude in feet (Pressure or GPS)
    @Default(true)
    bool altitudeValid, // False when altitude is unavailable (0xFFF in GDL90)
    required double trackDegrees, // Track / Heading in degrees true (0-360)
    required double speedKnots, // Ground speed in knots
    @Default(true)
    bool speedValid, // False when speed is unavailable (0xFFF in GDL90)
    required double verticalSpeedFpm, // Vertical speed in feet per minute
    @Default(true) bool verticalSpeedValid, // False when V/S is unavailable
    required DateTime lastUpdated,
    @Default(0) int emitterCategory, // GDL90 emitter category code
  }) = _Gdl90Target;

  bool isExpired([int timeoutSeconds = 60]) {
    return DateTime.now().difference(lastUpdated).inSeconds > timeoutSeconds;
  }
}
