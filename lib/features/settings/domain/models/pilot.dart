import 'package:freezed_annotation/freezed_annotation.dart';

part 'pilot.freezed.dart';
part 'pilot.g.dart';

@freezed
abstract class Pilot with _$Pilot {
  const factory Pilot({
    required String id,
    required String name,
    String? pin,
    @Default(0.0) double initialFlightHours,
  }) = _Pilot;

  factory Pilot.fromJson(Map<String, dynamic> json) => _$PilotFromJson(json);
}
