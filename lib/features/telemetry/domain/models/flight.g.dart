// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Flight _$FlightFromJson(Map<String, dynamic> json) => _Flight(
  uuid: json['uuid'] as String,
  name: json['name'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
  pilotId: json['pilot_id'] as String?,
  airplaneId: json['airplane_id'] as String?,
  notes: json['notes'] as String?,
  statistics: json['statistics'] == null
      ? null
      : FlightStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FlightToJson(_Flight instance) => <String, dynamic>{
  'uuid': instance.uuid,
  'name': instance.name,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime?.toIso8601String(),
  'pilot_id': instance.pilotId,
  'airplane_id': instance.airplaneId,
  'notes': instance.notes,
  'statistics': instance.statistics,
};
