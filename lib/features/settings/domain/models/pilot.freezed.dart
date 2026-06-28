// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pilot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Pilot {

 String get id; String get name; String? get pin; double get initialFlightHours; int get initialFlights;
/// Create a copy of Pilot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PilotCopyWith<Pilot> get copyWith => _$PilotCopyWithImpl<Pilot>(this as Pilot, _$identity);

  /// Serializes this Pilot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pilot&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.initialFlightHours, initialFlightHours) || other.initialFlightHours == initialFlightHours)&&(identical(other.initialFlights, initialFlights) || other.initialFlights == initialFlights));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,pin,initialFlightHours,initialFlights);

@override
String toString() {
  return 'Pilot(id: $id, name: $name, pin: $pin, initialFlightHours: $initialFlightHours, initialFlights: $initialFlights)';
}


}

/// @nodoc
abstract mixin class $PilotCopyWith<$Res>  {
  factory $PilotCopyWith(Pilot value, $Res Function(Pilot) _then) = _$PilotCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? pin, double initialFlightHours, int initialFlights
});




}
/// @nodoc
class _$PilotCopyWithImpl<$Res>
    implements $PilotCopyWith<$Res> {
  _$PilotCopyWithImpl(this._self, this._then);

  final Pilot _self;
  final $Res Function(Pilot) _then;

/// Create a copy of Pilot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? pin = freezed,Object? initialFlightHours = null,Object? initialFlights = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,initialFlightHours: null == initialFlightHours ? _self.initialFlightHours : initialFlightHours // ignore: cast_nullable_to_non_nullable
as double,initialFlights: null == initialFlights ? _self.initialFlights : initialFlights // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Pilot].
extension PilotPatterns on Pilot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pilot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pilot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pilot value)  $default,){
final _that = this;
switch (_that) {
case _Pilot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pilot value)?  $default,){
final _that = this;
switch (_that) {
case _Pilot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? pin,  double initialFlightHours,  int initialFlights)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pilot() when $default != null:
return $default(_that.id,_that.name,_that.pin,_that.initialFlightHours,_that.initialFlights);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? pin,  double initialFlightHours,  int initialFlights)  $default,) {final _that = this;
switch (_that) {
case _Pilot():
return $default(_that.id,_that.name,_that.pin,_that.initialFlightHours,_that.initialFlights);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? pin,  double initialFlightHours,  int initialFlights)?  $default,) {final _that = this;
switch (_that) {
case _Pilot() when $default != null:
return $default(_that.id,_that.name,_that.pin,_that.initialFlightHours,_that.initialFlights);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pilot implements Pilot {
  const _Pilot({required this.id, required this.name, this.pin, this.initialFlightHours = 0.0, this.initialFlights = 0});
  factory _Pilot.fromJson(Map<String, dynamic> json) => _$PilotFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? pin;
@override@JsonKey() final  double initialFlightHours;
@override@JsonKey() final  int initialFlights;

/// Create a copy of Pilot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PilotCopyWith<_Pilot> get copyWith => __$PilotCopyWithImpl<_Pilot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PilotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pilot&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.initialFlightHours, initialFlightHours) || other.initialFlightHours == initialFlightHours)&&(identical(other.initialFlights, initialFlights) || other.initialFlights == initialFlights));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,pin,initialFlightHours,initialFlights);

@override
String toString() {
  return 'Pilot(id: $id, name: $name, pin: $pin, initialFlightHours: $initialFlightHours, initialFlights: $initialFlights)';
}


}

/// @nodoc
abstract mixin class _$PilotCopyWith<$Res> implements $PilotCopyWith<$Res> {
  factory _$PilotCopyWith(_Pilot value, $Res Function(_Pilot) _then) = __$PilotCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? pin, double initialFlightHours, int initialFlights
});




}
/// @nodoc
class __$PilotCopyWithImpl<$Res>
    implements _$PilotCopyWith<$Res> {
  __$PilotCopyWithImpl(this._self, this._then);

  final _Pilot _self;
  final $Res Function(_Pilot) _then;

/// Create a copy of Pilot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? pin = freezed,Object? initialFlightHours = null,Object? initialFlights = null,}) {
  return _then(_Pilot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String?,initialFlightHours: null == initialFlightHours ? _self.initialFlightHours : initialFlightHours // ignore: cast_nullable_to_non_nullable
as double,initialFlights: null == initialFlights ? _self.initialFlights : initialFlights // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
