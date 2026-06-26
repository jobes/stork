import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_statistics.freezed.dart';
part 'flight_statistics.g.dart';

@freezed
abstract class FlightStatistics with _$FlightStatistics {
  const factory FlightStatistics({
    @JsonKey(name: 'max_altitude') double? maxAltitude,
    @JsonKey(name: 'total_ascent') double? totalAscent,
    @JsonKey(name: 'total_descent') double? totalDescent,
    @JsonKey(name: 'avg_altitude') double? avgAltitude,
    @JsonKey(name: 'max_ground_speed') double? maxGroundSpeed,
    @JsonKey(name: 'max_indicated_air_speed') double? maxIndicatedAirSpeed,
    @JsonKey(name: 'avg_ground_speed') double? avgGroundSpeed,
    @JsonKey(name: 'avg_indicated_air_speed') double? avgIndicatedAirSpeed,
    @JsonKey(name: 'total_distance') double? totalDistance,
    @JsonKey(name: 'max_distance_from_takeoff') double? maxDistanceFromTakeoff,
    @JsonKey(name: 'avg_engine_rpm') double? avgEngineRPM,
  }) = _FlightStatistics;

  factory FlightStatistics.fromJson(Map<String, dynamic> json) =>
      _$FlightStatisticsFromJson(json);
}
