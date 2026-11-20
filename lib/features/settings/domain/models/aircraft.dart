import 'package:freezed_annotation/freezed_annotation.dart';

import 'aircraft_type.dart';

part 'aircraft.freezed.dart';
part 'aircraft.g.dart';

const double defaultCruiseSpeedMs = 100 / 3.6;
const double minCruiseSpeedMs = 10 / 3.6;
const double maxCruiseSpeedMs = 1000 / 3.6;

@freezed
abstract class Aircraft with _$Aircraft {
  const factory Aircraft({
    required String id,
    required String name,
    @Default(0.0) double initialFlightHours,
    @Default(0) int initialFlights,
    @Default(false) bool sendLivePosition,
    @Default('') String ognDeviceId,
    @Default(defaultCruiseSpeedMs) double cruiseSpeedMs,
    int? weatherAltitudeFeet,
    double? dangerousWindMs,
    double? dangerousGustMs,
    @Default(AircraftType.glider) AircraftType type,
  }) = _Aircraft;

  factory Aircraft.fromJson(Map<String, dynamic> json) =>
      _$AircraftFromJson(json);
}
