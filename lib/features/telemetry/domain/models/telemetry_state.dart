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
  isFlying,
  isGpsDroneCan,
  mapViewState;

  bool get isBlackBoxField {
    switch (this) {
      case TelemetryField.isFlying:
      case TelemetryField.mapViewState:
        return false;
      default:
        return true;
    }
  }

  static final List<TelemetryField> blackBoxFields = TelemetryField.values
      .where((f) => f.isBlackBoxField)
      .toList(growable: false);

  String get dbColumnName {
    return name
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match m) => '${m[1]}_${m[2]}',
        )
        .toLowerCase();
  }

  String get jsonKey => dbColumnName;

  String get dbType {
    switch (this) {
      case TelemetryField.gpsSatelliteCount:
      case TelemetryField.isGpsDroneCan:
        return 'INTEGER';
      default:
        return 'REAL';
    }
  }

  dynamic deserialize(dynamic dbValue) {
    if (dbValue == null) return null;
    switch (this) {
      case TelemetryField.isGpsDroneCan:
        return (dbValue as int) == 1;
      case TelemetryField.latitude:
      case TelemetryField.longitude:
      case TelemetryField.heading:
      case TelemetryField.groundSpeed:
      case TelemetryField.indicatedAirSpeed:
      case TelemetryField.engineRPM:
      case TelemetryField.airPressure:
      case TelemetryField.gpsAltitude:
      case TelemetryField.gpsHorizontalAccuracy:
      case TelemetryField.gpsVerticalAccuracy:
        return (dbValue as num).toDouble();
      default:
        return dbValue;
    }
  }
}

class TelemetryValue<T> {
  final T value;
  const TelemetryValue(this.value);
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

  dynamic getFieldValue(TelemetryField field) {
    switch (field) {
      case TelemetryField.latitude:
        return latitude;
      case TelemetryField.longitude:
        return longitude;
      case TelemetryField.heading:
        return heading;
      case TelemetryField.groundSpeed:
        return groundSpeed;
      case TelemetryField.indicatedAirSpeed:
        return indicatedAirSpeed;
      case TelemetryField.engineRPM:
        return engineRPM;
      case TelemetryField.airPressure:
        return airPressure;
      case TelemetryField.gpsAltitude:
        return gpsAltitude;
      case TelemetryField.gpsSatelliteCount:
        return gpsSatelliteCount;
      case TelemetryField.gpsHorizontalAccuracy:
        return gpsHorizontalAccuracy;
      case TelemetryField.gpsVerticalAccuracy:
        return gpsVerticalAccuracy;
      case TelemetryField.isFlying:
        return isFlying;
      case TelemetryField.isGpsDroneCan:
        return isGpsDroneCan;
      case TelemetryField.mapViewState:
        return mapViewState;
    }
  }

  TelemetryState copyWithField(TelemetryField field, dynamic value) {
    switch (field) {
      case TelemetryField.latitude:
        return copyWith(latitude: TelemetryValue(value as double?));
      case TelemetryField.longitude:
        return copyWith(longitude: TelemetryValue(value as double?));
      case TelemetryField.heading:
        return copyWith(heading: TelemetryValue(value as double?));
      case TelemetryField.groundSpeed:
        return copyWith(groundSpeed: TelemetryValue(value as double?));
      case TelemetryField.indicatedAirSpeed:
        return copyWith(indicatedAirSpeed: TelemetryValue(value as double?));
      case TelemetryField.engineRPM:
        return copyWith(engineRPM: TelemetryValue(value as double?));
      case TelemetryField.airPressure:
        return copyWith(airPressure: TelemetryValue(value as double?));
      case TelemetryField.gpsAltitude:
        return copyWith(gpsAltitude: TelemetryValue(value as double?));
      case TelemetryField.gpsSatelliteCount:
        return copyWith(gpsSatelliteCount: TelemetryValue(value as int?));
      case TelemetryField.gpsHorizontalAccuracy:
        return copyWith(gpsHorizontalAccuracy: TelemetryValue(value as double?));
      case TelemetryField.gpsVerticalAccuracy:
        return copyWith(gpsVerticalAccuracy: TelemetryValue(value as double?));
      case TelemetryField.isFlying:
        return copyWith(isFlying: value as bool? ?? false);
      case TelemetryField.isGpsDroneCan:
        return copyWith(isGpsDroneCan: value as bool? ?? false);
      case TelemetryField.mapViewState:
        return copyWith(
          mapViewState: value as MapViewState? ?? MapViewState.init,
        );
    }
  }

  TelemetryState copyWith({
    TelemetryValue<double?>? latitude,
    TelemetryValue<double?>? longitude,
    TelemetryValue<double?>? heading,
    TelemetryValue<double?>? groundSpeed,
    TelemetryValue<double?>? indicatedAirSpeed,
    bool? isFlying,
    TelemetryValue<double?>? engineRPM,
    TelemetryValue<double?>? airPressure,
    TelemetryValue<double?>? gpsAltitude,
    TelemetryValue<int?>? gpsSatelliteCount,
    TelemetryValue<double?>? gpsHorizontalAccuracy,
    TelemetryValue<double?>? gpsVerticalAccuracy,
    bool? isGpsDroneCan,
    MapViewState? mapViewState,
  }) {
    return TelemetryState(
      latitude: latitude != null ? latitude.value : this.latitude,
      longitude: longitude != null ? longitude.value : this.longitude,
      heading: heading != null ? heading.value : this.heading,
      groundSpeed: groundSpeed != null ? groundSpeed.value : this.groundSpeed,
      indicatedAirSpeed: indicatedAirSpeed != null ? indicatedAirSpeed.value : this.indicatedAirSpeed,
      isFlying: isFlying ?? this.isFlying,
      engineRPM: engineRPM != null ? engineRPM.value : this.engineRPM,
      airPressure: airPressure != null ? airPressure.value : this.airPressure,
      gpsAltitude: gpsAltitude != null ? gpsAltitude.value : this.gpsAltitude,
      gpsSatelliteCount: gpsSatelliteCount != null ? gpsSatelliteCount.value : this.gpsSatelliteCount,
      gpsHorizontalAccuracy: gpsHorizontalAccuracy != null ? gpsHorizontalAccuracy.value : this.gpsHorizontalAccuracy,
      gpsVerticalAccuracy: gpsVerticalAccuracy != null ? gpsVerticalAccuracy.value : this.gpsVerticalAccuracy,
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
