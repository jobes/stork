import 'map_view_state.dart';

class TelemetryState {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final double engineRPM;
  final double airPressure;
  final double altitude; // MSL
  final double heightAboveGround; // AGL
  final MapViewState mapViewState;

  const TelemetryState({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.heading = 0.0,
    this.speed = 0.0,
    this.engineRPM = 0.0,
    this.airPressure = 1013.25,
    this.altitude = 0.0,
    this.heightAboveGround = 0.0,
    this.mapViewState = MapViewState.init,
  });

  TelemetryState copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    double? engineRPM,
    double? airPressure,
    double? altitude,
    double? heightAboveGround,
    MapViewState? mapViewState,
  }) {
    return TelemetryState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      engineRPM: engineRPM ?? this.engineRPM,
      airPressure: airPressure ?? this.airPressure,
      altitude: altitude ?? this.altitude,
      heightAboveGround: heightAboveGround ?? this.heightAboveGround,
      mapViewState: mapViewState ?? this.mapViewState,
    );
  }

  @override
  String toString() {
    return 'TelemetryState(lat: $latitude, lon: $longitude, heading: $heading, speed: $speed, rpm: $engineRPM, pressure: $airPressure, alt: $altitude, agl: $heightAboveGround, mapState: $mapViewState)';
  }
}
