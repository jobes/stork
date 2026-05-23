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

  const factory RangeThresholds.raw({
    double? inactiveMax,
    double? minError,
    double? minWarning,
    double? maxWarning,
    double? maxError,
  }) = _RangeThresholds;

  factory RangeThresholds({
    double? inactiveMax,
    double? minError,
    double? minWarning,
    double? maxWarning,
    double? maxError,
  }) {
    if (minError != null && minWarning != null && minError > minWarning) {
      throw ArgumentError('minWarning cannot be less than minError');
    }
    if (maxWarning != null && maxError != null && maxWarning > maxError) {
      throw ArgumentError('maxWarning cannot be greater than maxError');
    }
    if (minError != null && maxError != null && minError > maxError) {
      throw ArgumentError('minError cannot be greater than maxError');
    }
    if (inactiveMax != null && minError != null && inactiveMax > minError) {
      throw ArgumentError('inactiveMax cannot be greater than minError');
    }
    if (inactiveMax != null && minWarning != null && inactiveMax > minWarning) {
      throw ArgumentError('inactiveMax cannot be greater than minWarning');
    }
    if (inactiveMax != null && maxWarning != null && inactiveMax > maxWarning) {
      throw ArgumentError('inactiveMax cannot be greater than maxWarning');
    }
    if (inactiveMax != null && maxError != null && inactiveMax > maxError) {
      throw ArgumentError('inactiveMax cannot be greater than maxError');
    }
    if (minError != null && maxWarning != null && minError > maxWarning) {
      throw ArgumentError('minError cannot be greater than maxWarning');
    }
    if (minWarning != null && maxWarning != null && minWarning > maxWarning) {
      throw ArgumentError('minWarning cannot be greater than maxWarning');
    }
    if (minWarning != null && maxError != null && minWarning > maxError) {
      throw ArgumentError('minWarning cannot be greater than maxError');
    }

    return RangeThresholds.raw(
      inactiveMax: inactiveMax,
      minError: minError,
      minWarning: minWarning,
      maxWarning: maxWarning,
      maxError: maxError,
    );
  }

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
