// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircraft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Aircraft _$AircraftFromJson(Map<String, dynamic> json) => _Aircraft(
  id: json['id'] as String,
  name: json['name'] as String,
  initialFlightHours: (json['initialFlightHours'] as num?)?.toDouble() ?? 0.0,
  initialFlights: (json['initialFlights'] as num?)?.toInt() ?? 0,
  sendLivePosition: json['sendLivePosition'] as bool? ?? false,
  ognDeviceId: json['ognDeviceId'] as String? ?? '',
  cruiseSpeedMs:
      (json['cruiseSpeedMs'] as num?)?.toDouble() ?? defaultCruiseSpeedMs,
  weatherAltitudeFeet: (json['weatherAltitudeFeet'] as num?)?.toInt(),
  dangerousWindMs: (json['dangerousWindMs'] as num?)?.toDouble(),
  dangerousGustMs: (json['dangerousGustMs'] as num?)?.toDouble(),
  type:
      $enumDecodeNullable(_$AircraftTypeEnumMap, json['type']) ??
      AircraftType.glider,
);

Map<String, dynamic> _$AircraftToJson(_Aircraft instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'initialFlightHours': instance.initialFlightHours,
  'initialFlights': instance.initialFlights,
  'sendLivePosition': instance.sendLivePosition,
  'ognDeviceId': instance.ognDeviceId,
  'cruiseSpeedMs': instance.cruiseSpeedMs,
  'weatherAltitudeFeet': instance.weatherAltitudeFeet,
  'dangerousWindMs': instance.dangerousWindMs,
  'dangerousGustMs': instance.dangerousGustMs,
  'type': _$AircraftTypeEnumMap[instance.type]!,
};

const _$AircraftTypeEnumMap = {
  AircraftType.glider: 'glider',
  AircraftType.towPlane: 'towPlane',
  AircraftType.helicopter: 'helicopter',
  AircraftType.skydiver: 'skydiver',
  AircraftType.dropPlane: 'dropPlane',
  AircraftType.hangGlider: 'hangGlider',
  AircraftType.paraglider: 'paraglider',
  AircraftType.poweredAircraft: 'poweredAircraft',
  AircraftType.jet: 'jet',
  AircraftType.balloon: 'balloon',
  AircraftType.airship: 'airship',
  AircraftType.uav: 'uav',
  AircraftType.other: 'other',
};
