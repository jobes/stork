import 'package:freezed_annotation/freezed_annotation.dart';

part 'aircraft.freezed.dart';
part 'aircraft.g.dart';

@freezed
abstract class Aircraft with _$Aircraft {
  const factory Aircraft({
    required String id,
    required String name,
    @Default(0.0) double initialFlightHours,
    @Default(0) int initialFlights,
    @Default(false) bool sendLivePosition,
    @Default('') String ognDeviceId,
  }) = _Aircraft;

  factory Aircraft.fromJson(Map<String, dynamic> json) =>
      _$AircraftFromJson(json);
}
