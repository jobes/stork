class Gdl90Target {
  final String id; // ICAO 24-bit Hex address or unique string identifier
  final String? callsign;
  final double latitude; // Degrees (-90.0 to 90.0)
  final double longitude; // Degrees (-180.0 to 180.0)
  final double altitudeFeet; // Altitude in feet (Pressure or GPS)
  final bool
  altitudeValid; // False when altitude is unavailable (0xFFF in GDL90)
  final double trackDegrees; // Track / Heading in degrees true (0-360)
  final double speedKnots; // Ground speed in knots
  final bool speedValid; // False when speed is unavailable (0xFFF in GDL90)
  final double verticalSpeedFpm; // Vertical speed in feet per minute
  final bool verticalSpeedValid; // False when V/S is unavailable
  final DateTime lastUpdated;
  final int emitterCategory; // GDL90 emitter category code

  const Gdl90Target({
    required this.id,
    this.callsign,
    required this.latitude,
    required this.longitude,
    required this.altitudeFeet,
    this.altitudeValid = true,
    required this.trackDegrees,
    required this.speedKnots,
    this.speedValid = true,
    required this.verticalSpeedFpm,
    this.verticalSpeedValid = true,
    required this.lastUpdated,
    this.emitterCategory = 0,
  });

  bool isExpired([int timeoutSeconds = 60]) {
    return DateTime.now().difference(lastUpdated).inSeconds > timeoutSeconds;
  }

  Gdl90Target copyWith({
    String? id,
    String? callsign,
    double? latitude,
    double? longitude,
    double? altitudeFeet,
    bool? altitudeValid,
    double? trackDegrees,
    double? speedKnots,
    bool? speedValid,
    double? verticalSpeedFpm,
    bool? verticalSpeedValid,
    DateTime? lastUpdated,
    int? emitterCategory,
  }) {
    return Gdl90Target(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitudeFeet: altitudeFeet ?? this.altitudeFeet,
      altitudeValid: altitudeValid ?? this.altitudeValid,
      trackDegrees: trackDegrees ?? this.trackDegrees,
      speedKnots: speedKnots ?? this.speedKnots,
      speedValid: speedValid ?? this.speedValid,
      verticalSpeedFpm: verticalSpeedFpm ?? this.verticalSpeedFpm,
      verticalSpeedValid: verticalSpeedValid ?? this.verticalSpeedValid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      emitterCategory: emitterCategory ?? this.emitterCategory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gdl90Target &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          callsign == other.callsign &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          altitudeFeet == other.altitudeFeet &&
          altitudeValid == other.altitudeValid &&
          trackDegrees == other.trackDegrees &&
          speedKnots == other.speedKnots &&
          speedValid == other.speedValid &&
          verticalSpeedFpm == other.verticalSpeedFpm &&
          verticalSpeedValid == other.verticalSpeedValid &&
          lastUpdated == other.lastUpdated &&
          emitterCategory == other.emitterCategory;

  @override
  int get hashCode =>
      id.hashCode ^
      callsign.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      altitudeFeet.hashCode ^
      altitudeValid.hashCode ^
      trackDegrees.hashCode ^
      speedKnots.hashCode ^
      speedValid.hashCode ^
      verticalSpeedFpm.hashCode ^
      verticalSpeedValid.hashCode ^
      lastUpdated.hashCode ^
      emitterCategory.hashCode;
}
