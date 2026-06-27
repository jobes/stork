// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircraft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Aircraft _$AircraftFromJson(Map<String, dynamic> json) => _Aircraft(
  id: json['id'] as String,
  name: json['name'] as String,
  initialFlightHours: (json['initialFlightHours'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$AircraftToJson(_Aircraft instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'initialFlightHours': instance.initialFlightHours,
};
