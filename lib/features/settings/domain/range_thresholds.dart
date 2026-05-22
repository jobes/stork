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

  @Assert('minError == null || minWarning == null || minError <= minWarning', 'minWarning cannot be less than minError')
  @Assert('maxWarning == null || maxError == null || maxWarning <= maxError', 'maxWarning cannot be greater than maxError')
  @Assert('minError == null || maxError == null || minError <= maxError', 'minError cannot be greater than maxError')
  @Assert('inactiveMax == null || minError == null || inactiveMax <= minError', 'inactiveMax cannot be greater than minError')
  @Assert('inactiveMax == null || minWarning == null || inactiveMax <= minWarning', 'inactiveMax cannot be greater than minWarning')
  @Assert('inactiveMax == null || maxWarning == null || inactiveMax <= maxWarning', 'inactiveMax cannot be greater than maxWarning')
  @Assert('inactiveMax == null || maxError == null || inactiveMax <= maxError', 'inactiveMax cannot be greater than maxError')
  @Assert('minError == null || maxWarning == null || minError <= maxWarning', 'minError cannot be greater than maxWarning')
  @Assert('minWarning == null || maxWarning == null || minWarning <= maxWarning', 'minWarning cannot be greater than maxWarning')
  @Assert('minWarning == null || maxError == null || minWarning <= maxError', 'minWarning cannot be greater than maxError')
  const factory RangeThresholds({
    double? inactiveMax,
    double? minError,
    double? minWarning,
    double? maxWarning,
    double? maxError,
  }) = _RangeThresholds;

  factory RangeThresholds.fromJson(Map<String, dynamic> json) =>
      _$RangeThresholdsFromJson(json);

  ThresholdState evaluate(double value) => switch (value) {
        _ when inactiveMax != null && value <= inactiveMax! =>
          ThresholdState.inactive,
        _ when minError != null && value <= minError! =>
          ThresholdState.minError,
        _ when minWarning != null && value <= minWarning! =>
          ThresholdState.minWarning,
        _ when maxError != null && value >= maxError! =>
          ThresholdState.maxError,
        _ when maxWarning != null && value >= maxWarning! =>
          ThresholdState.maxWarning,
        _ => ThresholdState.operational,
      };
}
