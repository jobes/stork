// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pilot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Pilot _$PilotFromJson(Map<String, dynamic> json) => _Pilot(
  id: json['id'] as String,
  name: json['name'] as String,
  pin: json['pin'] as String?,
  initialFlightHours: (json['initialFlightHours'] as num?)?.toDouble() ?? 0.0,
  initialFlights: (json['initialFlights'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PilotToJson(_Pilot instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'pin': instance.pin,
  'initialFlightHours': instance.initialFlightHours,
  'initialFlights': instance.initialFlights,
};
