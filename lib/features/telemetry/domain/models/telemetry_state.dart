import 'map_view_state.dart';

class TelemetryState {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final double? indicatedAirSpeed;
  final bool isFlying;
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
    this.indicatedAirSpeed,
    this.isFlying = false,
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
    double? indicatedAirSpeed,
    bool? isFlying,
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
      indicatedAirSpeed: indicatedAirSpeed ?? this.indicatedAirSpeed,
      isFlying: isFlying ?? this.isFlying,
      engineRPM: engineRPM ?? this.engineRPM,
      airPressure: airPressure ?? this.airPressure,
      altitude: altitude ?? this.altitude,
      heightAboveGround: heightAboveGround ?? this.heightAboveGround,
      mapViewState: mapViewState ?? this.mapViewState,
    );
  }

  @override
  String toString() {
    return 'TelemetryState(lat: $latitude, lon: $longitude, heading: $heading, speed: $speed, ias: $indicatedAirSpeed, isFlying: $isFlying, rpm: $engineRPM, pressure: $airPressure, alt: $altitude, agl: $heightAboveGround, mapState: $mapViewState)';
  }
}
