// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'range_thresholds.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RangeThresholds {

 double? get inactiveMax; double? get minError; double? get minWarning; double? get maxWarning; double? get maxError;
/// Create a copy of RangeThresholds
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<RangeThresholds> get copyWith => _$RangeThresholdsCopyWithImpl<RangeThresholds>(this as RangeThresholds, _$identity);

  /// Serializes this RangeThresholds to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RangeThresholds&&(identical(other.inactiveMax, inactiveMax) || other.inactiveMax == inactiveMax)&&(identical(other.minError, minError) || other.minError == minError)&&(identical(other.minWarning, minWarning) || other.minWarning == minWarning)&&(identical(other.maxWarning, maxWarning) || other.maxWarning == maxWarning)&&(identical(other.maxError, maxError) || other.maxError == maxError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inactiveMax,minError,minWarning,maxWarning,maxError);

@override
String toString() {
  return 'RangeThresholds(inactiveMax: $inactiveMax, minError: $minError, minWarning: $minWarning, maxWarning: $maxWarning, maxError: $maxError)';
}


}

/// @nodoc
abstract mixin class $RangeThresholdsCopyWith<$Res>  {
  factory $RangeThresholdsCopyWith(RangeThresholds value, $Res Function(RangeThresholds) _then) = _$RangeThresholdsCopyWithImpl;
@useResult
$Res call({
 double? inactiveMax, double? minError, double? minWarning, double? maxWarning, double? maxError
});




}
/// @nodoc
class _$RangeThresholdsCopyWithImpl<$Res>
    implements $RangeThresholdsCopyWith<$Res> {
  _$RangeThresholdsCopyWithImpl(this._self, this._then);

  final RangeThresholds _self;
  final $Res Function(RangeThresholds) _then;

/// Create a copy of RangeThresholds
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inactiveMax = freezed,Object? minError = freezed,Object? minWarning = freezed,Object? maxWarning = freezed,Object? maxError = freezed,}) {
  return _then(_self.copyWith(
inactiveMax: freezed == inactiveMax ? _self.inactiveMax : inactiveMax // ignore: cast_nullable_to_non_nullable
as double?,minError: freezed == minError ? _self.minError : minError // ignore: cast_nullable_to_non_nullable
as double?,minWarning: freezed == minWarning ? _self.minWarning : minWarning // ignore: cast_nullable_to_non_nullable
as double?,maxWarning: freezed == maxWarning ? _self.maxWarning : maxWarning // ignore: cast_nullable_to_non_nullable
as double?,maxError: freezed == maxError ? _self.maxError : maxError // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RangeThresholds].
extension RangeThresholdsPatterns on RangeThresholds {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RangeThresholds value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RangeThresholds() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RangeThresholds value)  $default,){
final _that = this;
switch (_that) {
case _RangeThresholds():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RangeThresholds value)?  $default,){
final _that = this;
switch (_that) {
case _RangeThresholds() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? inactiveMax,  double? minError,  double? minWarning,  double? maxWarning,  double? maxError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RangeThresholds() when $default != null:
return $default(_that.inactiveMax,_that.minError,_that.minWarning,_that.maxWarning,_that.maxError);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? inactiveMax,  double? minError,  double? minWarning,  double? maxWarning,  double? maxError)  $default,) {final _that = this;
switch (_that) {
case _RangeThresholds():
return $default(_that.inactiveMax,_that.minError,_that.minWarning,_that.maxWarning,_that.maxError);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? inactiveMax,  double? minError,  double? minWarning,  double? maxWarning,  double? maxError)?  $default,) {final _that = this;
switch (_that) {
case _RangeThresholds() when $default != null:
return $default(_that.inactiveMax,_that.minError,_that.minWarning,_that.maxWarning,_that.maxError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RangeThresholds extends RangeThresholds {
  const _RangeThresholds({this.inactiveMax, this.minError, this.minWarning, this.maxWarning, this.maxError}): assert(minError == null || minWarning == null || minError <= minWarning, 'minWarning cannot be less than minError'),assert(maxWarning == null || maxError == null || maxWarning <= maxError, 'maxWarning cannot be greater than maxError'),assert(minError == null || maxError == null || minError <= maxError, 'minError cannot be greater than maxError'),assert(inactiveMax == null || minError == null || inactiveMax <= minError, 'inactiveMax cannot be greater than minError'),assert(inactiveMax == null || minWarning == null || inactiveMax <= minWarning, 'inactiveMax cannot be greater than minWarning'),assert(inactiveMax == null || maxWarning == null || inactiveMax <= maxWarning, 'inactiveMax cannot be greater than maxWarning'),assert(inactiveMax == null || maxError == null || inactiveMax <= maxError, 'inactiveMax cannot be greater than maxError'),assert(minError == null || maxWarning == null || minError <= maxWarning, 'minError cannot be greater than maxWarning'),assert(minWarning == null || maxWarning == null || minWarning <= maxWarning, 'minWarning cannot be greater than maxWarning'),assert(minWarning == null || maxError == null || minWarning <= maxError, 'minWarning cannot be greater than maxError'),super._();
  factory _RangeThresholds.fromJson(Map<String, dynamic> json) => _$RangeThresholdsFromJson(json);

@override final  double? inactiveMax;
@override final  double? minError;
@override final  double? minWarning;
@override final  double? maxWarning;
@override final  double? maxError;

/// Create a copy of RangeThresholds
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RangeThresholdsCopyWith<_RangeThresholds> get copyWith => __$RangeThresholdsCopyWithImpl<_RangeThresholds>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RangeThresholdsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RangeThresholds&&(identical(other.inactiveMax, inactiveMax) || other.inactiveMax == inactiveMax)&&(identical(other.minError, minError) || other.minError == minError)&&(identical(other.minWarning, minWarning) || other.minWarning == minWarning)&&(identical(other.maxWarning, maxWarning) || other.maxWarning == maxWarning)&&(identical(other.maxError, maxError) || other.maxError == maxError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inactiveMax,minError,minWarning,maxWarning,maxError);

@override
String toString() {
  return 'RangeThresholds(inactiveMax: $inactiveMax, minError: $minError, minWarning: $minWarning, maxWarning: $maxWarning, maxError: $maxError)';
}


}

/// @nodoc
abstract mixin class _$RangeThresholdsCopyWith<$Res> implements $RangeThresholdsCopyWith<$Res> {
  factory _$RangeThresholdsCopyWith(_RangeThresholds value, $Res Function(_RangeThresholds) _then) = __$RangeThresholdsCopyWithImpl;
@override @useResult
$Res call({
 double? inactiveMax, double? minError, double? minWarning, double? maxWarning, double? maxError
});




}
/// @nodoc
class __$RangeThresholdsCopyWithImpl<$Res>
    implements _$RangeThresholdsCopyWith<$Res> {
  __$RangeThresholdsCopyWithImpl(this._self, this._then);

  final _RangeThresholds _self;
  final $Res Function(_RangeThresholds) _then;

/// Create a copy of RangeThresholds
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inactiveMax = freezed,Object? minError = freezed,Object? minWarning = freezed,Object? maxWarning = freezed,Object? maxError = freezed,}) {
  return _then(_RangeThresholds(
inactiveMax: freezed == inactiveMax ? _self.inactiveMax : inactiveMax // ignore: cast_nullable_to_non_nullable
as double?,minError: freezed == minError ? _self.minError : minError // ignore: cast_nullable_to_non_nullable
as double?,minWarning: freezed == minWarning ? _self.minWarning : minWarning // ignore: cast_nullable_to_non_nullable
as double?,maxWarning: freezed == maxWarning ? _self.maxWarning : maxWarning // ignore: cast_nullable_to_non_nullable
as double?,maxError: freezed == maxError ? _self.maxError : maxError // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
