// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'firmware_update_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FirmwareUpdateProgress {

 FirmwareUpdatePhase get phase; int get bytesServed; int get totalBytes; Object? get error;
/// Create a copy of FirmwareUpdateProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FirmwareUpdateProgressCopyWith<FirmwareUpdateProgress> get copyWith => _$FirmwareUpdateProgressCopyWithImpl<FirmwareUpdateProgress>(this as FirmwareUpdateProgress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FirmwareUpdateProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FirmwareUpdateProgress&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.bytesServed, _this.bytesServed) || other.bytesServed == _this.bytesServed)&&(identical(other.totalBytes, _this.totalBytes) || other.totalBytes == _this.totalBytes)&&const DeepCollectionEquality().equals(other.error, _this.error));
}


@override
int get hashCode {
  final _this = this as FirmwareUpdateProgress;
  return Object.hash(runtimeType,_this.phase,_this.bytesServed,_this.totalBytes,const DeepCollectionEquality().hash(_this.error));
}

@override
String toString() {
  final _this = this as FirmwareUpdateProgress;
  return 'FirmwareUpdateProgress(phase: ${_this.phase}, bytesServed: ${_this.bytesServed}, totalBytes: ${_this.totalBytes}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $FirmwareUpdateProgressCopyWith<$Res>  {
  factory $FirmwareUpdateProgressCopyWith(FirmwareUpdateProgress value, $Res Function(FirmwareUpdateProgress) _then) = _$FirmwareUpdateProgressCopyWithImpl;
@useResult
$Res call({
 FirmwareUpdatePhase phase, int bytesServed, int totalBytes, Object? error
});




}
/// @nodoc
class _$FirmwareUpdateProgressCopyWithImpl<$Res>
    implements $FirmwareUpdateProgressCopyWith<$Res> {
  _$FirmwareUpdateProgressCopyWithImpl(this._self, this._then);

  final FirmwareUpdateProgress _self;
  final $Res Function(FirmwareUpdateProgress) _then;

/// Create a copy of FirmwareUpdateProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? bytesServed = null,Object? totalBytes = null,Object? error = freezed,}) {
  return _then(FirmwareUpdateProgress(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as FirmwareUpdatePhase,bytesServed: null == bytesServed ? _self.bytesServed : bytesServed // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [FirmwareUpdateProgress].
extension FirmwareUpdateProgressPatterns on FirmwareUpdateProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FirmwareUpdateProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FirmwareUpdateProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FirmwareUpdateProgress value)  $default,){
final _that = this;
switch (_that) {
case _FirmwareUpdateProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FirmwareUpdateProgress value)?  $default,){
final _that = this;
switch (_that) {
case _FirmwareUpdateProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FirmwareUpdatePhase phase,  int bytesServed,  int totalBytes,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FirmwareUpdateProgress() when $default != null:
return $default(_that.phase,_that.bytesServed,_that.totalBytes,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FirmwareUpdatePhase phase,  int bytesServed,  int totalBytes,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _FirmwareUpdateProgress():
return $default(_that.phase,_that.bytesServed,_that.totalBytes,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FirmwareUpdatePhase phase,  int bytesServed,  int totalBytes,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _FirmwareUpdateProgress() when $default != null:
return $default(_that.phase,_that.bytesServed,_that.totalBytes,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _FirmwareUpdateProgress extends FirmwareUpdateProgress {
  const _FirmwareUpdateProgress({required this.phase, this.bytesServed = 0, this.totalBytes = 0, this.error}): super._();
  

@override final  FirmwareUpdatePhase phase;
@override@JsonKey() final  int bytesServed;
@override@JsonKey() final  int totalBytes;
@override final  Object? error;

/// Create a copy of FirmwareUpdateProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FirmwareUpdateProgressCopyWith<_FirmwareUpdateProgress> get copyWith => __$FirmwareUpdateProgressCopyWithImpl<_FirmwareUpdateProgress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FirmwareUpdateProgress&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.bytesServed, bytesServed) || other.bytesServed == bytesServed)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,bytesServed,totalBytes,const DeepCollectionEquality().hash(error));
}

@override
String toString() {
    return 'FirmwareUpdateProgress(phase: $phase, bytesServed: $bytesServed, totalBytes: $totalBytes, error: $error)';
}


}

/// @nodoc
abstract mixin class _$FirmwareUpdateProgressCopyWith<$Res> implements $FirmwareUpdateProgressCopyWith<$Res> {
  factory _$FirmwareUpdateProgressCopyWith(_FirmwareUpdateProgress value, $Res Function(_FirmwareUpdateProgress) _then) = __$FirmwareUpdateProgressCopyWithImpl;
@override @useResult
$Res call({
 FirmwareUpdatePhase phase, int bytesServed, int totalBytes, Object? error
});




}
/// @nodoc
class __$FirmwareUpdateProgressCopyWithImpl<$Res>
    implements _$FirmwareUpdateProgressCopyWith<$Res> {
  __$FirmwareUpdateProgressCopyWithImpl(this._self, this._then);

  final _FirmwareUpdateProgress _self;
  final $Res Function(_FirmwareUpdateProgress) _then;

/// Create a copy of FirmwareUpdateProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? bytesServed = null,Object? totalBytes = null,Object? error = freezed,}) {
  return _then(_FirmwareUpdateProgress(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as FirmwareUpdatePhase,bytesServed: null == bytesServed ? _self.bytesServed : bytesServed // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
