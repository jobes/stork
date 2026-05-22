import 'package:freezed_annotation/freezed_annotation.dart';

part 'range_thresholds.freezed.dart';
part 'range_thresholds.g.dart';

enum ThresholdState {
  inactive,
  minError,
  minWarning,
  operational,
  maxWarning,
  maxError,
}

@freezed
abstract class RangeThresholds with _$RangeThresholds {
  const RangeThresholds._();

  const factory RangeThresholds({
    double? inactiveMax,
    double? minError,
    double? minWarning,
    double? maxWarning,
    double? maxError,
  }) = _RangeThresholds;

  factory RangeThresholds.fromJson(Map<String, dynamic> json) =>
      _$RangeThresholdsFromJson(json);

  ThresholdState evaluate(double value) {
    if (inactiveMax != null && value <= inactiveMax!) return ThresholdState.inactive;
    if (minError != null && value <= minError!) return ThresholdState.minError;
    if (minWarning != null && value <= minWarning!) return ThresholdState.minWarning;
    if (maxError != null && value >= maxError!) return ThresholdState.maxError;
    if (maxWarning != null && value >= maxWarning!) return ThresholdState.maxWarning;
    return ThresholdState.operational;
  }
}
