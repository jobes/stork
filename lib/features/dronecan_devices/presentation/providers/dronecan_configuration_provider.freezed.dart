// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dronecan_configuration_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DroneCanConfigurationState implements DiagnosticableTreeMixin {

 DroneCanConfigurationStatus get status;/// Parameters read so far; grows while the node is scanned.
 List<DroneCanParameter> get parameters;/// `true` while a set, store or erase request is in flight.
 bool get busy;/// Last failure, either of the scan or of an individual request.
 Object? get error;
/// Create a copy of DroneCanConfigurationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanConfigurationStateCopyWith<DroneCanConfigurationState> get copyWith => _$DroneCanConfigurationStateCopyWithImpl<DroneCanConfigurationState>(this as DroneCanConfigurationState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as DroneCanConfigurationState;
  properties
    ..add(DiagnosticsProperty('type', 'DroneCanConfigurationState'))
    ..add(DiagnosticsProperty('status', _this.status))..add(DiagnosticsProperty('parameters', _this.parameters))..add(DiagnosticsProperty('busy', _this.busy))..add(DiagnosticsProperty('error', _this.error));
}

@override
bool operator ==(Object other) {
  final _this = this as DroneCanConfigurationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanConfigurationState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.parameters, _this.parameters)&&(identical(other.busy, _this.busy) || other.busy == _this.busy)&&const DeepCollectionEquality().equals(other.error, _this.error));
}


@override
int get hashCode {
  final _this = this as DroneCanConfigurationState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.parameters),_this.busy,const DeepCollectionEquality().hash(_this.error));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as DroneCanConfigurationState;
  return 'DroneCanConfigurationState(status: ${_this.status}, parameters: ${_this.parameters}, busy: ${_this.busy}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $DroneCanConfigurationStateCopyWith<$Res>  {
  factory $DroneCanConfigurationStateCopyWith(DroneCanConfigurationState value, $Res Function(DroneCanConfigurationState) _then) = _$DroneCanConfigurationStateCopyWithImpl;
@useResult
$Res call({
 DroneCanConfigurationStatus status, List<DroneCanParameter> parameters, bool busy, Object? error
});




}
/// @nodoc
class _$DroneCanConfigurationStateCopyWithImpl<$Res>
    implements $DroneCanConfigurationStateCopyWith<$Res> {
  _$DroneCanConfigurationStateCopyWithImpl(this._self, this._then);

  final DroneCanConfigurationState _self;
  final $Res Function(DroneCanConfigurationState) _then;

/// Create a copy of DroneCanConfigurationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? parameters = null,Object? busy = null,Object? error = freezed,}) {
  return _then(DroneCanConfigurationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DroneCanConfigurationStatus,parameters: null == parameters ? _self.parameters : parameters // ignore: cast_nullable_to_non_nullable
as List<DroneCanParameter>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [DroneCanConfigurationState].
extension DroneCanConfigurationStatePatterns on DroneCanConfigurationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DroneCanConfigurationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DroneCanConfigurationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DroneCanConfigurationState value)  $default,){
final _that = this;
switch (_that) {
case _DroneCanConfigurationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DroneCanConfigurationState value)?  $default,){
final _that = this;
switch (_that) {
case _DroneCanConfigurationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DroneCanConfigurationStatus status,  List<DroneCanParameter> parameters,  bool busy,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DroneCanConfigurationState() when $default != null:
return $default(_that.status,_that.parameters,_that.busy,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DroneCanConfigurationStatus status,  List<DroneCanParameter> parameters,  bool busy,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _DroneCanConfigurationState():
return $default(_that.status,_that.parameters,_that.busy,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DroneCanConfigurationStatus status,  List<DroneCanParameter> parameters,  bool busy,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _DroneCanConfigurationState() when $default != null:
return $default(_that.status,_that.parameters,_that.busy,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _DroneCanConfigurationState extends DroneCanConfigurationState with DiagnosticableTreeMixin {
  const _DroneCanConfigurationState({this.status = DroneCanConfigurationStatus.idle,  List<DroneCanParameter> parameters = const <DroneCanParameter>[], this.busy = false, this.error}): _parameters = parameters,super._();
  

@override@JsonKey() final  DroneCanConfigurationStatus status;
/// Parameters read so far; grows while the node is scanned.
 final  List<DroneCanParameter> _parameters;
/// Parameters read so far; grows while the node is scanned.
@override@JsonKey() List<DroneCanParameter> get parameters {
  if (_parameters is EqualUnmodifiableListView) return _parameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parameters);
}

/// `true` while a set, store or erase request is in flight.
@override@JsonKey() final  bool busy;
/// Last failure, either of the scan or of an individual request.
@override final  Object? error;

/// Create a copy of DroneCanConfigurationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DroneCanConfigurationStateCopyWith<_DroneCanConfigurationState> get copyWith => __$DroneCanConfigurationStateCopyWithImpl<_DroneCanConfigurationState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'DroneCanConfigurationState'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('parameters', parameters))..add(DiagnosticsProperty('busy', busy))..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DroneCanConfigurationState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.parameters, _parameters)&&(identical(other.busy, busy) || other.busy == busy)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_parameters),busy,const DeepCollectionEquality().hash(error));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'DroneCanConfigurationState(status: $status, parameters: $parameters, busy: $busy, error: $error)';
}


}

/// @nodoc
abstract mixin class _$DroneCanConfigurationStateCopyWith<$Res> implements $DroneCanConfigurationStateCopyWith<$Res> {
  factory _$DroneCanConfigurationStateCopyWith(_DroneCanConfigurationState value, $Res Function(_DroneCanConfigurationState) _then) = __$DroneCanConfigurationStateCopyWithImpl;
@override @useResult
$Res call({
 DroneCanConfigurationStatus status, List<DroneCanParameter> parameters, bool busy, Object? error
});




}
/// @nodoc
class __$DroneCanConfigurationStateCopyWithImpl<$Res>
    implements _$DroneCanConfigurationStateCopyWith<$Res> {
  __$DroneCanConfigurationStateCopyWithImpl(this._self, this._then);

  final _DroneCanConfigurationState _self;
  final $Res Function(_DroneCanConfigurationState) _then;

/// Create a copy of DroneCanConfigurationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? parameters = null,Object? busy = null,Object? error = freezed,}) {
  return _then(_DroneCanConfigurationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DroneCanConfigurationStatus,parameters: null == parameters ? _self._parameters : parameters // ignore: cast_nullable_to_non_nullable
as List<DroneCanParameter>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
