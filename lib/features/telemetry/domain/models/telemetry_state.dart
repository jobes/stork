import 'dart:convert';
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
  coolantTemperature,
  oilPressure,
  oilTemperature,
  cylinderHeadTemperature,
  exhaustGasTemperature,
  isFlying,
  isGpsDroneCan,
  mapViewState,
  fuelLevelPercent,
  fuelVolumeLiters,
  isFuelSupported,
  radioActiveFrequency,
  radioStandbyFrequency,
  radioActiveStationName,
  radioStandbyStationName,
  radioFlags,
  radioInstance,
  radioNodeId,
  radioVolume,
  radioSquelch,
  radioVox,
  radioIntercom,
  radioMicGain,
  isRadioSupported;

  bool get isBlackBoxField {
    switch (this) {
      case TelemetryField.isFlying:
      case TelemetryField.mapViewState:
      case TelemetryField.isFuelSupported:
      case TelemetryField.radioActiveFrequency:
      case TelemetryField.radioStandbyFrequency:
      case TelemetryField.radioActiveStationName:
      case TelemetryField.radioStandbyStationName:
      case TelemetryField.radioFlags:
      case TelemetryField.radioInstance:
      case TelemetryField.radioNodeId:
      case TelemetryField.radioVolume:
      case TelemetryField.radioSquelch:
      case TelemetryField.radioVox:
      case TelemetryField.radioIntercom:
      case TelemetryField.radioMicGain:
      case TelemetryField.isRadioSupported:
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
      case TelemetryField.engineRPM:
      case TelemetryField.gpsSatelliteCount:
      case TelemetryField.isGpsDroneCan:
      case TelemetryField.isFuelSupported:
        return 'INTEGER';
      case TelemetryField.cylinderHeadTemperature:
      case TelemetryField.exhaustGasTemperature:
        return 'TEXT'; // JSON-encoded List<double>
      default:
        return 'REAL';
    }
  }

  dynamic deserialize(dynamic dbValue) {
    if (dbValue == null) return null;
    switch (this) {
      case TelemetryField.isGpsDroneCan:
      case TelemetryField.isFuelSupported:
        return (dbValue as int) == 1;
      case TelemetryField.cylinderHeadTemperature:
      case TelemetryField.exhaustGasTemperature:
        // Stored as JSON array of numbers, e.g. "[450.5,451.0]"
        final raw = dbValue as String;
        if (raw.isEmpty) return <double>[];
        final list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => e == null ? null : (e as num).toDouble())
            .toList();
      case TelemetryField.engineRPM:
        return (dbValue as num).toInt();
      case TelemetryField.latitude:
      case TelemetryField.longitude:
      case TelemetryField.heading:
      case TelemetryField.groundSpeed:
      case TelemetryField.indicatedAirSpeed:
      case TelemetryField.airPressure:
      case TelemetryField.gpsAltitude:
      case TelemetryField.gpsHorizontalAccuracy:
      case TelemetryField.gpsVerticalAccuracy:
      case TelemetryField.coolantTemperature:
      case TelemetryField.oilPressure:
      case TelemetryField.oilTemperature:
      case TelemetryField.fuelLevelPercent:
      case TelemetryField.fuelVolumeLiters:
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
  final int? engineRPM;
  final double? airPressure; // in Pa
  final double? gpsAltitude; // MSL
  final DateTime? gpsTimestamp;
  final int? gpsSatelliteCount;
  final double? gpsHorizontalAccuracy; // in meters
  final double? gpsVerticalAccuracy; // in meters
  final double? coolantTemperature; // in Kelvin
  final double? oilPressure; // in kPa
  final double? oilTemperature; // in Kelvin
  final bool isOilTempSupported;
  final bool isOilPressureSupported;
  final bool isEngineRpmSupported;
  final bool isChtSupported;
  final bool isEgtSupported;

  /// CHT per cylinder, in Kelvin (null = no sensor for that cylinder, empty list = no data).
  final List<double?> cylinderHeadTemperatures;

  /// EGT per cylinder, in Kelvin (null = no sensor for that cylinder, empty list = no data).
  final List<double?> exhaustGasTemperatures;
  final bool isGpsDroneCan;
  final MapViewState mapViewState;
  final double? fuelLevelPercent;
  final double? fuelVolumeLiters;
  final bool isFuelSupported;

  // Radio fields
  final int? radioActiveFrequency;
  final int? radioStandbyFrequency;
  final String? radioActiveStationName;
  final String? radioStandbyStationName;
  final int? radioFlags;
  final int? radioInstance;
  final int? radioNodeId;
  final int? radioVolume;
  final int? radioSquelch;
  final int? radioVox;
  final int? radioIntercom;
  final List<int> radioMicGain;
  final bool isRadioSupported;

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
    this.gpsTimestamp,
    this.gpsSatelliteCount,
    this.gpsHorizontalAccuracy,
    this.gpsVerticalAccuracy,
    this.coolantTemperature,
    this.oilPressure,
    this.oilTemperature,
    this.isOilTempSupported = false,
    this.isOilPressureSupported = false,
    this.isEngineRpmSupported = false,
    this.isChtSupported = false,
    this.isEgtSupported = false,
    this.cylinderHeadTemperatures = const [],
    this.exhaustGasTemperatures = const [],
    this.isGpsDroneCan = false,
    this.mapViewState = MapViewState.init,
    this.fuelLevelPercent,
    this.fuelVolumeLiters,
    this.isFuelSupported = false,
    this.radioActiveFrequency,
    this.radioStandbyFrequency,
    this.radioActiveStationName,
    this.radioStandbyStationName,
    this.radioFlags,
    this.radioInstance,
    this.radioNodeId,
    this.radioVolume,
    this.radioSquelch,
    this.radioVox,
    this.radioIntercom,
    this.radioMicGain = const [],
    this.isRadioSupported = false,
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
      case TelemetryField.coolantTemperature:
        return coolantTemperature;
      case TelemetryField.oilPressure:
        return oilPressure;
      case TelemetryField.oilTemperature:
        return oilTemperature;
      case TelemetryField.cylinderHeadTemperature:
        return cylinderHeadTemperatures.isNotEmpty
            ? jsonEncode(cylinderHeadTemperatures)
            : null;
      case TelemetryField.exhaustGasTemperature:
        return exhaustGasTemperatures.isNotEmpty
            ? jsonEncode(exhaustGasTemperatures)
            : null;
      case TelemetryField.isFlying:
        return isFlying;
      case TelemetryField.isGpsDroneCan:
        return isGpsDroneCan;
      case TelemetryField.mapViewState:
        return mapViewState;
      case TelemetryField.fuelLevelPercent:
        return fuelLevelPercent;
      case TelemetryField.fuelVolumeLiters:
        return fuelVolumeLiters;
      case TelemetryField.isFuelSupported:
        return isFuelSupported;
      case TelemetryField.radioActiveFrequency:
        return radioActiveFrequency;
      case TelemetryField.radioStandbyFrequency:
        return radioStandbyFrequency;
      case TelemetryField.radioActiveStationName:
        return radioActiveStationName;
      case TelemetryField.radioStandbyStationName:
        return radioStandbyStationName;
      case TelemetryField.radioFlags:
        return radioFlags;
      case TelemetryField.radioInstance:
        return radioInstance;
      case TelemetryField.radioNodeId:
        return radioNodeId;
      case TelemetryField.radioVolume:
        return radioVolume;
      case TelemetryField.radioSquelch:
        return radioSquelch;
      case TelemetryField.radioVox:
        return radioVox;
      case TelemetryField.radioIntercom:
        return radioIntercom;
      case TelemetryField.radioMicGain:
        return radioMicGain.isNotEmpty ? jsonEncode(radioMicGain) : null;
      case TelemetryField.isRadioSupported:
        return isRadioSupported;
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
        return copyWith(engineRPM: TelemetryValue(value as int?));
      case TelemetryField.airPressure:
        return copyWith(airPressure: TelemetryValue(value as double?));
      case TelemetryField.gpsAltitude:
        return copyWith(gpsAltitude: TelemetryValue(value as double?));
      case TelemetryField.gpsSatelliteCount:
        return copyWith(gpsSatelliteCount: TelemetryValue(value as int?));
      case TelemetryField.gpsHorizontalAccuracy:
        return copyWith(
          gpsHorizontalAccuracy: TelemetryValue(value as double?),
        );
      case TelemetryField.gpsVerticalAccuracy:
        return copyWith(gpsVerticalAccuracy: TelemetryValue(value as double?));
      case TelemetryField.coolantTemperature:
        return copyWith(coolantTemperature: TelemetryValue(value as double?));
      case TelemetryField.oilPressure:
        return copyWith(oilPressure: TelemetryValue(value as double?));
      case TelemetryField.oilTemperature:
        return copyWith(oilTemperature: TelemetryValue(value as double?));
      case TelemetryField.cylinderHeadTemperature:
        final List<dynamic>? parsedChtList = (value is String)
            ? (value.isEmpty ? [] : jsonDecode(value) as List<dynamic>?)
            : (value as List<dynamic>?);
        return copyWith(
          cylinderHeadTemperatures: TelemetryValue(
            parsedChtList?.cast<double?>() ?? [],
          ),
        );
      case TelemetryField.exhaustGasTemperature:
        final List<dynamic>? parsedEgtList = (value is String)
            ? (value.isEmpty ? [] : jsonDecode(value) as List<dynamic>?)
            : (value as List<dynamic>?);
        return copyWith(
          exhaustGasTemperatures: TelemetryValue(
            parsedEgtList?.cast<double?>() ?? [],
          ),
        );
      case TelemetryField.isFlying:
        return copyWith(isFlying: value as bool? ?? false);
      case TelemetryField.isGpsDroneCan:
        return copyWith(isGpsDroneCan: value as bool? ?? false);
      case TelemetryField.mapViewState:
        return copyWith(
          mapViewState: value as MapViewState? ?? MapViewState.init,
        );
      case TelemetryField.fuelLevelPercent:
        return copyWith(fuelLevelPercent: TelemetryValue(value as double?));
      case TelemetryField.fuelVolumeLiters:
        return copyWith(fuelVolumeLiters: TelemetryValue(value as double?));
      case TelemetryField.isFuelSupported:
        return copyWith(isFuelSupported: value as bool? ?? false);
      case TelemetryField.radioActiveFrequency:
        return copyWith(radioActiveFrequency: TelemetryValue(value as int?));
      case TelemetryField.radioStandbyFrequency:
        return copyWith(radioStandbyFrequency: TelemetryValue(value as int?));
      case TelemetryField.radioActiveStationName:
        return copyWith(
          radioActiveStationName: TelemetryValue(value as String?),
        );
      case TelemetryField.radioStandbyStationName:
        return copyWith(
          radioStandbyStationName: TelemetryValue(value as String?),
        );
      case TelemetryField.radioFlags:
        return copyWith(radioFlags: TelemetryValue(value as int?));
      case TelemetryField.radioInstance:
        return copyWith(radioInstance: TelemetryValue(value as int?));
      case TelemetryField.radioNodeId:
        return copyWith(radioNodeId: TelemetryValue(value as int?));
      case TelemetryField.radioVolume:
        return copyWith(radioVolume: TelemetryValue(value as int?));
      case TelemetryField.radioSquelch:
        return copyWith(radioSquelch: TelemetryValue(value as int?));
      case TelemetryField.radioVox:
        return copyWith(radioVox: TelemetryValue(value as int?));
      case TelemetryField.radioIntercom:
        return copyWith(radioIntercom: TelemetryValue(value as int?));
      case TelemetryField.radioMicGain:
        final List<dynamic>? parsedMicList = (value is String)
            ? (value.isEmpty ? [] : jsonDecode(value) as List<dynamic>?)
            : (value as List<dynamic>?);
        return copyWith(
          radioMicGain: TelemetryValue(parsedMicList?.cast<int>() ?? []),
        );
      case TelemetryField.isRadioSupported:
        return copyWith(isRadioSupported: value as bool? ?? false);
    }
  }

  TelemetryState copyWith({
    TelemetryValue<double?>? latitude,
    TelemetryValue<double?>? longitude,
    TelemetryValue<double?>? heading,
    TelemetryValue<double?>? groundSpeed,
    TelemetryValue<double?>? indicatedAirSpeed,
    bool? isFlying,
    TelemetryValue<int?>? engineRPM,
    TelemetryValue<double?>? airPressure,
    TelemetryValue<double?>? gpsAltitude,
    TelemetryValue<DateTime?>? gpsTimestamp,
    TelemetryValue<int?>? gpsSatelliteCount,
    TelemetryValue<double?>? gpsHorizontalAccuracy,
    TelemetryValue<double?>? gpsVerticalAccuracy,
    TelemetryValue<double?>? coolantTemperature,
    TelemetryValue<double?>? oilPressure,
    TelemetryValue<double?>? oilTemperature,
    bool? isOilTempSupported,
    bool? isOilPressureSupported,
    bool? isEngineRpmSupported,
    bool? isChtSupported,
    bool? isEgtSupported,
    TelemetryValue<List<double?>>? cylinderHeadTemperatures,
    TelemetryValue<List<double?>>? exhaustGasTemperatures,
    bool? isGpsDroneCan,
    MapViewState? mapViewState,
    TelemetryValue<double?>? fuelLevelPercent,
    TelemetryValue<double?>? fuelVolumeLiters,
    bool? isFuelSupported,
    TelemetryValue<int?>? radioActiveFrequency,
    TelemetryValue<int?>? radioStandbyFrequency,
    TelemetryValue<String?>? radioActiveStationName,
    TelemetryValue<String?>? radioStandbyStationName,
    TelemetryValue<int?>? radioFlags,
    TelemetryValue<int?>? radioInstance,
    TelemetryValue<int?>? radioNodeId,
    TelemetryValue<int?>? radioVolume,
    TelemetryValue<int?>? radioSquelch,
    TelemetryValue<int?>? radioVox,
    TelemetryValue<int?>? radioIntercom,
    TelemetryValue<List<int>>? radioMicGain,
    bool? isRadioSupported,
  }) {
    return TelemetryState(
      latitude: latitude != null ? latitude.value : this.latitude,
      longitude: longitude != null ? longitude.value : this.longitude,
      heading: heading != null ? heading.value : this.heading,
      groundSpeed: groundSpeed != null ? groundSpeed.value : this.groundSpeed,
      indicatedAirSpeed: indicatedAirSpeed != null
          ? indicatedAirSpeed.value
          : this.indicatedAirSpeed,
      isFlying: isFlying ?? this.isFlying,
      engineRPM: engineRPM != null ? engineRPM.value : this.engineRPM,
      airPressure: airPressure != null ? airPressure.value : this.airPressure,
      gpsAltitude: gpsAltitude != null ? gpsAltitude.value : this.gpsAltitude,
      gpsTimestamp: gpsTimestamp != null
          ? gpsTimestamp.value
          : this.gpsTimestamp,
      gpsSatelliteCount: gpsSatelliteCount != null
          ? gpsSatelliteCount.value
          : this.gpsSatelliteCount,
      gpsHorizontalAccuracy: gpsHorizontalAccuracy != null
          ? gpsHorizontalAccuracy.value
          : this.gpsHorizontalAccuracy,
      gpsVerticalAccuracy: gpsVerticalAccuracy != null
          ? gpsVerticalAccuracy.value
          : this.gpsVerticalAccuracy,
      coolantTemperature: coolantTemperature != null
          ? coolantTemperature.value
          : this.coolantTemperature,
      oilPressure: oilPressure != null ? oilPressure.value : this.oilPressure,
      oilTemperature: oilTemperature != null
          ? oilTemperature.value
          : this.oilTemperature,
      isOilTempSupported: isOilTempSupported ?? this.isOilTempSupported,
      isOilPressureSupported:
          isOilPressureSupported ?? this.isOilPressureSupported,
      isEngineRpmSupported: isEngineRpmSupported ?? this.isEngineRpmSupported,
      isChtSupported: isChtSupported ?? this.isChtSupported,
      isEgtSupported: isEgtSupported ?? this.isEgtSupported,
      cylinderHeadTemperatures: cylinderHeadTemperatures != null
          ? cylinderHeadTemperatures.value
          : this.cylinderHeadTemperatures,
      exhaustGasTemperatures: exhaustGasTemperatures != null
          ? exhaustGasTemperatures.value
          : this.exhaustGasTemperatures,
      isGpsDroneCan: isGpsDroneCan ?? this.isGpsDroneCan,
      mapViewState: mapViewState ?? this.mapViewState,
      fuelLevelPercent: fuelLevelPercent != null
          ? fuelLevelPercent.value
          : this.fuelLevelPercent,
      fuelVolumeLiters: fuelVolumeLiters != null
          ? fuelVolumeLiters.value
          : this.fuelVolumeLiters,
      isFuelSupported: isFuelSupported ?? this.isFuelSupported,
      radioActiveFrequency: radioActiveFrequency != null
          ? radioActiveFrequency.value
          : this.radioActiveFrequency,
      radioStandbyFrequency: radioStandbyFrequency != null
          ? radioStandbyFrequency.value
          : this.radioStandbyFrequency,
      radioActiveStationName: radioActiveStationName != null
          ? radioActiveStationName.value
          : this.radioActiveStationName,
      radioStandbyStationName: radioStandbyStationName != null
          ? radioStandbyStationName.value
          : this.radioStandbyStationName,
      radioFlags: radioFlags != null ? radioFlags.value : this.radioFlags,
      radioInstance: radioInstance != null
          ? radioInstance.value
          : this.radioInstance,
      radioNodeId: radioNodeId != null ? radioNodeId.value : this.radioNodeId,
      radioVolume: radioVolume != null ? radioVolume.value : this.radioVolume,
      radioSquelch: radioSquelch != null
          ? radioSquelch.value
          : this.radioSquelch,
      radioVox: radioVox != null ? radioVox.value : this.radioVox,
      radioIntercom: radioIntercom != null
          ? radioIntercom.value
          : this.radioIntercom,
      radioMicGain: radioMicGain != null
          ? radioMicGain.value
          : this.radioMicGain,
      isRadioSupported: isRadioSupported ?? this.isRadioSupported,
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
      coolantTemperature: field == TelemetryField.coolantTemperature
          ? null
          : coolantTemperature,
      oilPressure: field == TelemetryField.oilPressure ? null : oilPressure,
      oilTemperature: field == TelemetryField.oilTemperature
          ? null
          : oilTemperature,
      isOilTempSupported: isOilTempSupported,
      isOilPressureSupported: isOilPressureSupported,
      isEngineRpmSupported: isEngineRpmSupported,
      isChtSupported: isChtSupported,
      isEgtSupported: isEgtSupported,
      cylinderHeadTemperatures: field == TelemetryField.cylinderHeadTemperature
          ? List<double?>.filled(cylinderHeadTemperatures.length, null)
          : cylinderHeadTemperatures,
      exhaustGasTemperatures: field == TelemetryField.exhaustGasTemperature
          ? List<double?>.filled(exhaustGasTemperatures.length, null)
          : exhaustGasTemperatures,
      isGpsDroneCan:
          field == TelemetryField.gpsHorizontalAccuracy ||
              field == TelemetryField.gpsVerticalAccuracy
          ? false
          : isGpsDroneCan,
      mapViewState: mapViewState,
      fuelLevelPercent: field == TelemetryField.fuelLevelPercent
          ? null
          : fuelLevelPercent,
      fuelVolumeLiters: field == TelemetryField.fuelVolumeLiters
          ? null
          : fuelVolumeLiters,
      isFuelSupported: isFuelSupported,
      radioActiveFrequency: field == TelemetryField.radioActiveFrequency
          ? null
          : radioActiveFrequency,
      radioStandbyFrequency: field == TelemetryField.radioStandbyFrequency
          ? null
          : radioStandbyFrequency,
      radioActiveStationName: field == TelemetryField.radioActiveStationName
          ? null
          : radioActiveStationName,
      radioStandbyStationName: field == TelemetryField.radioStandbyStationName
          ? null
          : radioStandbyStationName,
      radioFlags: field == TelemetryField.radioFlags ? null : radioFlags,
      radioInstance: field == TelemetryField.radioInstance
          ? null
          : radioInstance,
      radioNodeId: field == TelemetryField.radioNodeId ? null : radioNodeId,
      radioVolume: field == TelemetryField.radioVolume ? null : radioVolume,
      radioSquelch: field == TelemetryField.radioSquelch ? null : radioSquelch,
      radioVox: field == TelemetryField.radioVox ? null : radioVox,
      radioIntercom: field == TelemetryField.radioIntercom
          ? null
          : radioIntercom,
      radioMicGain: field == TelemetryField.radioMicGain ? [] : radioMicGain,
      isRadioSupported: isRadioSupported,
    );
  }

  @override
  String toString() {
    return 'TelemetryState(lat: $latitude, lon: $longitude, heading: $heading, groundSpeed: $groundSpeed, ias: $indicatedAirSpeed, isFlying: $isFlying, rpm: $engineRPM, pressure: $airPressure, gpsAlt: $gpsAltitude, gpsSats: $gpsSatelliteCount, gpsHAcc: $gpsHorizontalAccuracy, gpsVAcc: $gpsVerticalAccuracy, coolant: $coolantTemperature, oilP: $oilPressure, oilT: $oilTemperature, isOilTempSupported: $isOilTempSupported, isOilPressureSupported: $isOilPressureSupported, chts: $cylinderHeadTemperatures, egts: $exhaustGasTemperatures, isGpsDroneCan: $isGpsDroneCan, mapState: $mapViewState, radioActiveFreq: $radioActiveFrequency, radioStandbyFreq: $radioStandbyFrequency, radioActiveName: $radioActiveStationName, radioStandbyName: $radioStandbyStationName, radioFlags: $radioFlags, radioInstance: $radioInstance, radioNodeId: $radioNodeId, radioVolume: $radioVolume, radioSquelch: $radioSquelch, radioVox: $radioVox, radioIntercom: $radioIntercom, radioMicGain: $radioMicGain, isRadioSupported: $isRadioSupported)';
  }
}
