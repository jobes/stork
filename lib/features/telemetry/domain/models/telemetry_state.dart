import 'map_view_state.dart';

enum TelemetryField {
  latitude,
  longitude,
  heading,
  groundSpeed,
  indicatedAirSpeed,
  engineRPM,
  airPressure,
  gpsAltitude,
  gpsSatelliteCount,
  gpsHorizontalAccuracy,
  gpsVerticalAccuracy,
}

class TelemetryState {
  final double? latitude;
  final double? longitude;
  final double? heading;
  final double? groundSpeed;
  final double? indicatedAirSpeed;
  final bool isFlying;
  final double? engineRPM;
  final double? airPressure; // in Pa
  final double? gpsAltitude; // MSL
  final int? gpsSatelliteCount;
  final double? gpsHorizontalAccuracy; // in meters
  final double? gpsVerticalAccuracy; // in meters
  final bool isGpsDroneCan;
  final MapViewState mapViewState;

  const TelemetryState({
    this.latitude,
    this.longitude,
    this.heading,
    this.groundSpeed,
    this.indicatedAirSpeed,
    this.isFlying = false,
    this.engineRPM,
    this.airPressure,
    this.gpsAltitude,
    this.gpsSatelliteCount,
    this.gpsHorizontalAccuracy,
    this.gpsVerticalAccuracy,
    this.isGpsDroneCan = false,
    this.mapViewState = MapViewState.init,
  });

  TelemetryState copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? groundSpeed,
    double? indicatedAirSpeed,
    bool? isFlying,
    double? engineRPM,
    double? airPressure,
    double? gpsAltitude,
    int? gpsSatelliteCount,
    double? gpsHorizontalAccuracy,
    double? gpsVerticalAccuracy,
    bool? isGpsDroneCan,
    MapViewState? mapViewState,
  }) {
    return TelemetryState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      groundSpeed: groundSpeed ?? this.groundSpeed,
      indicatedAirSpeed: indicatedAirSpeed ?? this.indicatedAirSpeed,
      isFlying: isFlying ?? this.isFlying,
      engineRPM: engineRPM ?? this.engineRPM,
      airPressure: airPressure ?? this.airPressure,
      gpsAltitude: gpsAltitude ?? this.gpsAltitude,
      gpsSatelliteCount: gpsSatelliteCount ?? this.gpsSatelliteCount,
      gpsHorizontalAccuracy:
          gpsHorizontalAccuracy ?? this.gpsHorizontalAccuracy,
      gpsVerticalAccuracy: gpsVerticalAccuracy ?? this.gpsVerticalAccuracy,
      isGpsDroneCan: isGpsDroneCan ?? this.isGpsDroneCan,
      mapViewState: mapViewState ?? this.mapViewState,
    );
  }

  TelemetryState resetField(TelemetryField field) {
    return TelemetryState(
      latitude: field == TelemetryField.latitude ? null : latitude,
      longitude: field == TelemetryField.longitude ? null : longitude,
      heading: field == TelemetryField.heading ? null : heading,
      groundSpeed: field == TelemetryField.groundSpeed ? null : groundSpeed,
      indicatedAirSpeed: field == TelemetryField.indicatedAirSpeed
          ? null
          : indicatedAirSpeed,
      isFlying: isFlying,
      engineRPM: field == TelemetryField.engineRPM ? null : engineRPM,
      airPressure: field == TelemetryField.airPressure ? null : airPressure,
      gpsAltitude: field == TelemetryField.gpsAltitude ? null : gpsAltitude,
      gpsSatelliteCount: field == TelemetryField.gpsSatelliteCount
          ? null
          : gpsSatelliteCount,
      gpsHorizontalAccuracy: field == TelemetryField.gpsHorizontalAccuracy
          ? null
          : gpsHorizontalAccuracy,
      gpsVerticalAccuracy: field == TelemetryField.gpsVerticalAccuracy
          ? null
          : gpsVerticalAccuracy,
      isGpsDroneCan:
          field == TelemetryField.gpsHorizontalAccuracy ||
              field == TelemetryField.gpsVerticalAccuracy
          ? false
          : isGpsDroneCan,
      mapViewState: mapViewState,
    );
  }

  @override
  String toString() {
    return 'TelemetryState(lat: $latitude, lon: $longitude, heading: $heading, groundSpeed: $groundSpeed, ias: $indicatedAirSpeed, isFlying: $isFlying, rpm: $engineRPM, pressure: $airPressure, gpsAlt: $gpsAltitude, gpsSats: $gpsSatelliteCount, gpsHAcc: $gpsHorizontalAccuracy, gpsVAcc: $gpsVerticalAccuracy, isGpsDroneCan: $isGpsDroneCan, mapState: $mapViewState)';
  }
}
