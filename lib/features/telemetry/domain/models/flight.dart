import 'package:freezed_annotation/freezed_annotation.dart';
import 'flight_statistics.dart';

part 'flight.freezed.dart';
part 'flight.g.dart';

@freezed
abstract class Flight with _$Flight {
  const factory Flight({
    required String uuid,
    required String name,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') DateTime? endTime,
    @JsonKey(name: 'pilot_id') String? pilotId,
    @JsonKey(name: 'airplane_id') String? airplaneId,
    FlightStatistics? statistics,
  }) = _Flight;

  factory Flight.fromJson(Map<String, dynamic> json) => _$FlightFromJson(json);
}
