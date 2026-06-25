// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Flight {

 String get uuid; String get name;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime? get endTime;@JsonKey(name: 'pilot_id') String? get pilotId;@JsonKey(name: 'airplane_id') String? get airplaneId; FlightStatistics? get statistics;
/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightCopyWith<Flight> get copyWith => _$FlightCopyWithImpl<Flight>(this as Flight, _$identity);

  /// Serializes this Flight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Flight&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.pilotId, pilotId) || other.pilotId == pilotId)&&(identical(other.airplaneId, airplaneId) || other.airplaneId == airplaneId)&&(identical(other.statistics, statistics) || other.statistics == statistics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uuid,name,startTime,endTime,pilotId,airplaneId,statistics);

@override
String toString() {
  return 'Flight(uuid: $uuid, name: $name, startTime: $startTime, endTime: $endTime, pilotId: $pilotId, airplaneId: $airplaneId, statistics: $statistics)';
}


}

/// @nodoc
abstract mixin class $FlightCopyWith<$Res>  {
  factory $FlightCopyWith(Flight value, $Res Function(Flight) _then) = _$FlightCopyWithImpl;
@useResult
$Res call({
 String uuid, String name,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'pilot_id') String? pilotId,@JsonKey(name: 'airplane_id') String? airplaneId, FlightStatistics? statistics
});


$FlightStatisticsCopyWith<$Res>? get statistics;

}
/// @nodoc
class _$FlightCopyWithImpl<$Res>
    implements $FlightCopyWith<$Res> {
  _$FlightCopyWithImpl(this._self, this._then);

  final Flight _self;
  final $Res Function(Flight) _then;

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? name = null,Object? startTime = null,Object? endTime = freezed,Object? pilotId = freezed,Object? airplaneId = freezed,Object? statistics = freezed,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,pilotId: freezed == pilotId ? _self.pilotId : pilotId // ignore: cast_nullable_to_non_nullable
as String?,airplaneId: freezed == airplaneId ? _self.airplaneId : airplaneId // ignore: cast_nullable_to_non_nullable
as String?,statistics: freezed == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as FlightStatistics?,
  ));
}
/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlightStatisticsCopyWith<$Res>? get statistics {
    if (_self.statistics == null) {
    return null;
  }

  return $FlightStatisticsCopyWith<$Res>(_self.statistics!, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}


/// Adds pattern-matching-related methods to [Flight].
extension FlightPatterns on Flight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Flight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Flight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Flight value)  $default,){
final _that = this;
switch (_that) {
case _Flight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Flight value)?  $default,){
final _that = this;
switch (_that) {
case _Flight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String name, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'pilot_id')  String? pilotId, @JsonKey(name: 'airplane_id')  String? airplaneId,  FlightStatistics? statistics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Flight() when $default != null:
return $default(_that.uuid,_that.name,_that.startTime,_that.endTime,_that.pilotId,_that.airplaneId,_that.statistics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String name, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'pilot_id')  String? pilotId, @JsonKey(name: 'airplane_id')  String? airplaneId,  FlightStatistics? statistics)  $default,) {final _that = this;
switch (_that) {
case _Flight():
return $default(_that.uuid,_that.name,_that.startTime,_that.endTime,_that.pilotId,_that.airplaneId,_that.statistics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String name, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'pilot_id')  String? pilotId, @JsonKey(name: 'airplane_id')  String? airplaneId,  FlightStatistics? statistics)?  $default,) {final _that = this;
switch (_that) {
case _Flight() when $default != null:
return $default(_that.uuid,_that.name,_that.startTime,_that.endTime,_that.pilotId,_that.airplaneId,_that.statistics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Flight implements Flight {
  const _Flight({required this.uuid, required this.name, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') this.endTime, @JsonKey(name: 'pilot_id') this.pilotId, @JsonKey(name: 'airplane_id') this.airplaneId, this.statistics});
  factory _Flight.fromJson(Map<String, dynamic> json) => _$FlightFromJson(json);

@override final  String uuid;
@override final  String name;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime? endTime;
@override@JsonKey(name: 'pilot_id') final  String? pilotId;
@override@JsonKey(name: 'airplane_id') final  String? airplaneId;
@override final  FlightStatistics? statistics;

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightCopyWith<_Flight> get copyWith => __$FlightCopyWithImpl<_Flight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Flight&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.name, name) || other.name == name)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.pilotId, pilotId) || other.pilotId == pilotId)&&(identical(other.airplaneId, airplaneId) || other.airplaneId == airplaneId)&&(identical(other.statistics, statistics) || other.statistics == statistics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uuid,name,startTime,endTime,pilotId,airplaneId,statistics);

@override
String toString() {
  return 'Flight(uuid: $uuid, name: $name, startTime: $startTime, endTime: $endTime, pilotId: $pilotId, airplaneId: $airplaneId, statistics: $statistics)';
}


}

/// @nodoc
abstract mixin class _$FlightCopyWith<$Res> implements $FlightCopyWith<$Res> {
  factory _$FlightCopyWith(_Flight value, $Res Function(_Flight) _then) = __$FlightCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String name,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'pilot_id') String? pilotId,@JsonKey(name: 'airplane_id') String? airplaneId, FlightStatistics? statistics
});


@override $FlightStatisticsCopyWith<$Res>? get statistics;

}
/// @nodoc
class __$FlightCopyWithImpl<$Res>
    implements _$FlightCopyWith<$Res> {
  __$FlightCopyWithImpl(this._self, this._then);

  final _Flight _self;
  final $Res Function(_Flight) _then;

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? name = null,Object? startTime = null,Object? endTime = freezed,Object? pilotId = freezed,Object? airplaneId = freezed,Object? statistics = freezed,}) {
  return _then(_Flight(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,pilotId: freezed == pilotId ? _self.pilotId : pilotId // ignore: cast_nullable_to_non_nullable
as String?,airplaneId: freezed == airplaneId ? _self.airplaneId : airplaneId // ignore: cast_nullable_to_non_nullable
as String?,statistics: freezed == statistics ? _self.statistics : statistics // ignore: cast_nullable_to_non_nullable
as FlightStatistics?,
  ));
}

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlightStatisticsCopyWith<$Res>? get statistics {
    if (_self.statistics == null) {
    return null;
  }

  return $FlightStatisticsCopyWith<$Res>(_self.statistics!, (value) {
    return _then(_self.copyWith(statistics: value));
  });
}
}

// dart format on
