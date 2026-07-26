// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aircraft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Aircraft {

 String get id; String get name; double get initialFlightHours; int get initialFlights; bool get sendLivePosition; String get ognDeviceId;
/// Create a copy of Aircraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AircraftCopyWith<Aircraft> get copyWith => _$AircraftCopyWithImpl<Aircraft>(this as Aircraft, _$identity);

  /// Serializes this Aircraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Aircraft&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.initialFlightHours, initialFlightHours) || other.initialFlightHours == initialFlightHours)&&(identical(other.initialFlights, initialFlights) || other.initialFlights == initialFlights)&&(identical(other.sendLivePosition, sendLivePosition) || other.sendLivePosition == sendLivePosition)&&(identical(other.ognDeviceId, ognDeviceId) || other.ognDeviceId == ognDeviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,initialFlightHours,initialFlights,sendLivePosition,ognDeviceId);

@override
String toString() {
  return 'Aircraft(id: $id, name: $name, initialFlightHours: $initialFlightHours, initialFlights: $initialFlights, sendLivePosition: $sendLivePosition, ognDeviceId: $ognDeviceId)';
}


}

/// @nodoc
abstract mixin class $AircraftCopyWith<$Res>  {
  factory $AircraftCopyWith(Aircraft value, $Res Function(Aircraft) _then) = _$AircraftCopyWithImpl;
@useResult
$Res call({
 String id, String name, double initialFlightHours, int initialFlights, bool sendLivePosition, String ognDeviceId
});




}
/// @nodoc
class _$AircraftCopyWithImpl<$Res>
    implements $AircraftCopyWith<$Res> {
  _$AircraftCopyWithImpl(this._self, this._then);

  final Aircraft _self;
  final $Res Function(Aircraft) _then;

/// Create a copy of Aircraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? initialFlightHours = null,Object? initialFlights = null,Object? sendLivePosition = null,Object? ognDeviceId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initialFlightHours: null == initialFlightHours ? _self.initialFlightHours : initialFlightHours // ignore: cast_nullable_to_non_nullable
as double,initialFlights: null == initialFlights ? _self.initialFlights : initialFlights // ignore: cast_nullable_to_non_nullable
as int,sendLivePosition: null == sendLivePosition ? _self.sendLivePosition : sendLivePosition // ignore: cast_nullable_to_non_nullable
as bool,ognDeviceId: null == ognDeviceId ? _self.ognDeviceId : ognDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Aircraft].
extension AircraftPatterns on Aircraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Aircraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Aircraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Aircraft value)  $default,){
final _that = this;
switch (_that) {
case _Aircraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Aircraft value)?  $default,){
final _that = this;
switch (_that) {
case _Aircraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double initialFlightHours,  int initialFlights,  bool sendLivePosition,  String ognDeviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Aircraft() when $default != null:
return $default(_that.id,_that.name,_that.initialFlightHours,_that.initialFlights,_that.sendLivePosition,_that.ognDeviceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double initialFlightHours,  int initialFlights,  bool sendLivePosition,  String ognDeviceId)  $default,) {final _that = this;
switch (_that) {
case _Aircraft():
return $default(_that.id,_that.name,_that.initialFlightHours,_that.initialFlights,_that.sendLivePosition,_that.ognDeviceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double initialFlightHours,  int initialFlights,  bool sendLivePosition,  String ognDeviceId)?  $default,) {final _that = this;
switch (_that) {
case _Aircraft() when $default != null:
return $default(_that.id,_that.name,_that.initialFlightHours,_that.initialFlights,_that.sendLivePosition,_that.ognDeviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Aircraft implements Aircraft {
  const _Aircraft({required this.id, required this.name, this.initialFlightHours = 0.0, this.initialFlights = 0, this.sendLivePosition = false, this.ognDeviceId = ''});
  factory _Aircraft.fromJson(Map<String, dynamic> json) => _$AircraftFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  double initialFlightHours;
@override@JsonKey() final  int initialFlights;
@override@JsonKey() final  bool sendLivePosition;
@override@JsonKey() final  String ognDeviceId;

/// Create a copy of Aircraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AircraftCopyWith<_Aircraft> get copyWith => __$AircraftCopyWithImpl<_Aircraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AircraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Aircraft&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.initialFlightHours, initialFlightHours) || other.initialFlightHours == initialFlightHours)&&(identical(other.initialFlights, initialFlights) || other.initialFlights == initialFlights)&&(identical(other.sendLivePosition, sendLivePosition) || other.sendLivePosition == sendLivePosition)&&(identical(other.ognDeviceId, ognDeviceId) || other.ognDeviceId == ognDeviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,initialFlightHours,initialFlights,sendLivePosition,ognDeviceId);

@override
String toString() {
  return 'Aircraft(id: $id, name: $name, initialFlightHours: $initialFlightHours, initialFlights: $initialFlights, sendLivePosition: $sendLivePosition, ognDeviceId: $ognDeviceId)';
}


}

/// @nodoc
abstract mixin class _$AircraftCopyWith<$Res> implements $AircraftCopyWith<$Res> {
  factory _$AircraftCopyWith(_Aircraft value, $Res Function(_Aircraft) _then) = __$AircraftCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double initialFlightHours, int initialFlights, bool sendLivePosition, String ognDeviceId
});




}
/// @nodoc
class __$AircraftCopyWithImpl<$Res>
    implements _$AircraftCopyWith<$Res> {
  __$AircraftCopyWithImpl(this._self, this._then);

  final _Aircraft _self;
  final $Res Function(_Aircraft) _then;

/// Create a copy of Aircraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? initialFlightHours = null,Object? initialFlights = null,Object? sendLivePosition = null,Object? ognDeviceId = null,}) {
  return _then(_Aircraft(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initialFlightHours: null == initialFlightHours ? _self.initialFlightHours : initialFlightHours // ignore: cast_nullable_to_non_nullable
as double,initialFlights: null == initialFlights ? _self.initialFlights : initialFlights // ignore: cast_nullable_to_non_nullable
as int,sendLivePosition: null == sendLivePosition ? _self.sendLivePosition : sendLivePosition // ignore: cast_nullable_to_non_nullable
as bool,ognDeviceId: null == ognDeviceId ? _self.ognDeviceId : ognDeviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
