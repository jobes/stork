class TrafficAircraft {
  final String id;
  final String callsign;
  final String? registration;
  final String? aircraftModel;
  final String? cn;
  final String?
  icaoHex; // ICAO 24-bit hex address for cross-source dedup (GDL90, ADS-B)
  final double latitude;
  final double longitude;
  final double altitude; // AMSL in meters
  final bool altitudeValid; // false when altitude is unavailable (GDL90 0xFFF)
  final double track; // degrees
  final double groundSpeed; // m/s
  final bool speedValid; // false when ground speed is unavailable
  final double verticalSpeed; // m/s (vario)
  final bool verticalSpeedValid; // false when vertical speed is unavailable
  final int aircraftType;
  final DateTime lastSeen;
  final bool isAnonymous;
  final double turnRate; // rad/s
  final bool isCircling;
  final bool isCollisionThreat;
  final double? tCpa; // seconds
  final double? minDistance; // meters
  final Set<String>
  sources; // e.g. {'ogn'}, {'puretrack'}, {'ogn', 'puretrack'}
  final String activeSource; // Source of the latest accepted position update

  TrafficAircraft({
    required this.id,
    required this.callsign,
    this.registration,
    this.aircraftModel,
    this.cn,
    this.icaoHex,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.track,
    required this.groundSpeed,
    required this.verticalSpeed,
    required this.aircraftType,
    required this.lastSeen,
    this.isAnonymous = false,
    this.turnRate = 0.0,
    this.isCircling = false,
    this.isCollisionThreat = false,
    this.tCpa,
    this.minDistance,
    this.altitudeValid = true,
    this.speedValid = true,
    this.verticalSpeedValid = true,
    Set<String>? sources,
    this.activeSource = 'ogn',
  }) : sources = sources ?? const {'ogn'};

  TrafficAircraft copyWith({
    String? id,
    String? callsign,
    String? registration,
    String? aircraftModel,
    String? cn,
    String? icaoHex,
    double? latitude,
    double? longitude,
    double? altitude,
    bool? altitudeValid,
    double? track,
    double? groundSpeed,
    bool? speedValid,
    double? verticalSpeed,
    bool? verticalSpeedValid,
    int? aircraftType,
    DateTime? lastSeen,
    bool? isAnonymous,
    double? turnRate,
    bool? isCircling,
    bool? isCollisionThreat,
    double? tCpa,
    double? minDistance,
    Set<String>? sources,
    String? activeSource,
  }) {
    return TrafficAircraft(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      registration: registration ?? this.registration,
      aircraftModel: aircraftModel ?? this.aircraftModel,
      cn: cn ?? this.cn,
      icaoHex: icaoHex ?? this.icaoHex,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      altitudeValid: altitudeValid ?? this.altitudeValid,
      track: track ?? this.track,
      groundSpeed: groundSpeed ?? this.groundSpeed,
      speedValid: speedValid ?? this.speedValid,
      verticalSpeed: verticalSpeed ?? this.verticalSpeed,
      verticalSpeedValid: verticalSpeedValid ?? this.verticalSpeedValid,
      aircraftType: aircraftType ?? this.aircraftType,
      lastSeen: lastSeen ?? this.lastSeen,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      turnRate: turnRate ?? this.turnRate,
      isCircling: isCircling ?? this.isCircling,
      isCollisionThreat: isCollisionThreat ?? this.isCollisionThreat,
      tCpa: tCpa ?? this.tCpa,
      minDistance: minDistance ?? this.minDistance,
      sources: sources ?? this.sources,
      activeSource: activeSource ?? this.activeSource,
    );
  }
}
