import 'package:freezed_annotation/freezed_annotation.dart';

part 'dronecan_parameter.freezed.dart';

/// Kind of a DroneCAN parameter value.
enum DroneCanParamValueType { empty, integer, real, boolean, string }

extension DroneCanParamValueTypeX on DroneCanParamValueType {
  /// Whether values of this kind carry a number.
  bool get isNumeric =>
      this == DroneCanParamValueType.integer ||
      this == DroneCanParamValueType.real;
}

/// Value of a DroneCAN node parameter (`uavcan.protocol.param.Value`).
@freezed
sealed class DroneCanParamValue with _$DroneCanParamValue {
  const DroneCanParamValue._();

  /// Undefined value; used when a parameter is read without assigning one.
  const factory DroneCanParamValue.empty() = DroneCanParamEmptyValue;

  const factory DroneCanParamValue.integer(int value) =
      DroneCanParamIntegerValue;

  const factory DroneCanParamValue.real(double value) = DroneCanParamRealValue;

  const factory DroneCanParamValue.boolean(bool value) =
      DroneCanParamBooleanValue;

  const factory DroneCanParamValue.string(String value) =
      DroneCanParamStringValue;

  DroneCanParamValueType get type => switch (this) {
    DroneCanParamEmptyValue() => DroneCanParamValueType.empty,
    DroneCanParamIntegerValue() => DroneCanParamValueType.integer,
    DroneCanParamRealValue() => DroneCanParamValueType.real,
    DroneCanParamBooleanValue() => DroneCanParamValueType.boolean,
    DroneCanParamStringValue() => DroneCanParamValueType.string,
  };

  bool get isEmpty => this is DroneCanParamEmptyValue;

  /// Whether the value carries a number.
  bool get isNumeric => type.isNumeric;

  /// Boolean payload, or `null` for other value kinds.
  bool? get booleanValue => switch (this) {
    DroneCanParamBooleanValue(:final value) => value,
    _ => null,
  };

  /// Numeric payload, or `null` for empty, boolean and string values.
  num? get numericValue => switch (this) {
    DroneCanParamIntegerValue(:final value) => value,
    DroneCanParamRealValue(:final value) => value,
    _ => null,
  };

  /// Compares two values, treating numerically equal integers and reals as the
  /// same value (`1` equals `1.0`).
  bool sameAs(DroneCanParamValue other) {
    final left = numericValue;
    final right = other.numericValue;
    if (left != null && right != null) return left == right;
    return this == other;
  }
}

/// One configurable parameter (`uavcan.protocol.param.GetSet`) of a DroneCAN
/// node.
///
/// Instances are transient: they are read on demand and never persisted.
@freezed
abstract class DroneCanParameter with _$DroneCanParameter {
  const DroneCanParameter._();

  const factory DroneCanParameter({
    required int index,
    required String name,
    required DroneCanParamValue value,
    DroneCanParamValue? defaultValue,
    num? minValue,
    num? maxValue,
  }) = _DroneCanParameter;

  /// Maximum length of a string parameter value in bytes.
  ///
  /// Mirrors the `uint8[<=128]` field of `uavcan.protocol.param.Value`, so the
  /// editor can reject values the node could not store.
  static const int maxStringLength = 128;

  DroneCanParamValueType get type => value.type;

  /// Whether [value] differs from the reported default.
  ///
  /// Nodes that do not report a default never mark a parameter as modified.
  bool get isModified {
    final fallback = defaultValue;
    if (fallback == null) return false;
    return !value.sameAs(fallback);
  }

  /// Replaces the value while keeping the rest of the metadata.
  DroneCanParameter withValue(DroneCanParamValue newValue) =>
      copyWith(value: newValue);

  /// Merges [other] into this parameter, keeping the metadata of this
  /// instance when [other] does not report it.
  ///
  /// Used to apply the response of a set request, which usually only carries
  /// the new value and the name.
  DroneCanParameter merge(DroneCanParameter other) => copyWith(
    name: other.name.isEmpty ? name : other.name,
    value: other.value,
    defaultValue: other.defaultValue ?? defaultValue,
    minValue: other.minValue ?? minValue,
    maxValue: other.maxValue ?? maxValue,
  );
}
