// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlightStatistics _$FlightStatisticsFromJson(
  Map<String, dynamic> json,
) => _FlightStatistics(
  maxAltitude: (json['max_altitude'] as num?)?.toDouble(),
  totalAscent: (json['total_ascent'] as num?)?.toDouble(),
  totalDescent: (json['total_descent'] as num?)?.toDouble(),
  avgAltitude: (json['avg_altitude'] as num?)?.toDouble(),
  maxGroundSpeed: (json['max_ground_speed'] as num?)?.toDouble(),
  maxIndicatedAirSpeed: (json['max_indicated_air_speed'] as num?)?.toDouble(),
  avgGroundSpeed: (json['avg_ground_speed'] as num?)?.toDouble(),
  avgIndicatedAirSpeed: (json['avg_indicated_air_speed'] as num?)?.toDouble(),
  totalDistance: (json['total_distance'] as num?)?.toDouble(),
  maxDistanceFromTakeoff: (json['max_distance_from_takeoff'] as num?)
      ?.toDouble(),
  avgEngineRPM: (json['avg_engine_rpm'] as num?)?.toDouble(),
);

Map<String, dynamic> _$FlightStatisticsToJson(_FlightStatistics instance) =>
    <String, dynamic>{
      'max_altitude': instance.maxAltitude,
      'total_ascent': instance.totalAscent,
      'total_descent': instance.totalDescent,
      'avg_altitude': instance.avgAltitude,
      'max_ground_speed': instance.maxGroundSpeed,
      'max_indicated_air_speed': instance.maxIndicatedAirSpeed,
      'avg_ground_speed': instance.avgGroundSpeed,
      'avg_indicated_air_speed': instance.avgIndicatedAirSpeed,
      'total_distance': instance.totalDistance,
      'max_distance_from_takeoff': instance.maxDistanceFromTakeoff,
      'avg_engine_rpm': instance.avgEngineRPM,
    };
