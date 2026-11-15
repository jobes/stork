import 'package:freezed_annotation/freezed_annotation.dart';

part 'notam.freezed.dart';

@freezed
abstract class Notam with _$Notam {
  const Notam._();

  const factory Notam({
    @Default('') String featureName,
    @Default('') String endDate,
    @Default('') String icaoMessage,
    @Default('') String id,
    @Default('') String type,
    @Default('') String issuer,
    required DateTime from,
    DateTime? to,
    String? schedule,
    @Default('') String msg,
    String? lowerLimit2,
    String? upperLimit2,
    @Default('') String fir,
    @Default(0.0) double latitude,
    @Default(0.0) double longitude,
    @Default(0.0) double radius,
    @Default(0) int flightLevelLowerLimit,
    @Default(999) int flightLevelUpperLimit,
  }) = _Notam;

  // Series and number can be reused by different issuing locations.
  String get key => '$fir:$issuer:$id';
}
