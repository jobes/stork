import 'map_view_state.dart';

enum TelemetryField {
  latitude,
  longitude,
  heading,
  speed,
  indicatedAirSpeed,
  engineRPM,
  airPressure,
  altitude,
  heightAboveGround,
}

class TelemetryState {
  final double? latitude;
  final double? longitude;
  final double? heading;
  final double? speed;
  final double? indicatedAirSpeed;
  final bool isFlying;
  final double? engineRPM;
  final double? airPressure; // in Pa
  final double? altitude; // MSL
  final double? heightAboveGround; // AGL
  final MapViewState mapViewState;

  const TelemetryState({
    this.latitude,
    this.longitude,
    this.heading,
    this.speed,
    this.indicatedAirSpeed,
    this.isFlying = false,
    this.engineRPM,
    this.airPressure,
    this.altitude,
    this.heightAboveGround,
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

  TelemetryState resetField(TelemetryField field) {
    return TelemetryState(
      latitude: field == TelemetryField.latitude ? null : latitude,
      longitude: field == TelemetryField.longitude ? null : longitude,
      heading: field == TelemetryField.heading ? null : heading,
      speed: field == TelemetryField.speed ? null : speed,
      indicatedAirSpeed: field == TelemetryField.indicatedAirSpeed ? null : indicatedAirSpeed,
      isFlying: isFlying,
      engineRPM: field == TelemetryField.engineRPM ? null : engineRPM,
      airPressure: field == TelemetryField.airPressure ? null : airPressure,
      altitude: field == TelemetryField.altitude ? null : altitude,
      heightAboveGround: field == TelemetryField.heightAboveGround ? null : heightAboveGround,
      mapViewState: mapViewState,
    );
  }

  @override
  String toString() {
    return 'TelemetryState(lat: $latitude, lon: $longitude, heading: $heading, speed: $speed, ias: $indicatedAirSpeed, isFlying: $isFlying, rpm: $engineRPM, pressure: $airPressure, alt: $altitude, agl: $heightAboveGround, mapState: $mapViewState)';
  }
}

