// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlightStatistics {

@JsonKey(name: 'max_altitude') double? get maxAltitude;@JsonKey(name: 'total_ascent') double? get totalAscent;@JsonKey(name: 'total_descent') double? get totalDescent;@JsonKey(name: 'avg_altitude') double? get avgAltitude;@JsonKey(name: 'max_ground_speed') double? get maxGroundSpeed;@JsonKey(name: 'max_indicated_air_speed') double? get maxIndicatedAirSpeed;@JsonKey(name: 'avg_ground_speed') double? get avgGroundSpeed;@JsonKey(name: 'avg_indicated_air_speed') double? get avgIndicatedAirSpeed;@JsonKey(name: 'total_distance') double? get totalDistance;@JsonKey(name: 'max_distance_from_takeoff') double? get maxDistanceFromTakeoff;@JsonKey(name: 'avg_engine_rpm') double? get avgEngineRPM;
/// Create a copy of FlightStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightStatisticsCopyWith<FlightStatistics> get copyWith => _$FlightStatisticsCopyWithImpl<FlightStatistics>(this as FlightStatistics, _$identity);

  /// Serializes this FlightStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlightStatistics&&(identical(other.maxAltitude, maxAltitude) || other.maxAltitude == maxAltitude)&&(identical(other.totalAscent, totalAscent) || other.totalAscent == totalAscent)&&(identical(other.totalDescent, totalDescent) || other.totalDescent == totalDescent)&&(identical(other.avgAltitude, avgAltitude) || other.avgAltitude == avgAltitude)&&(identical(other.maxGroundSpeed, maxGroundSpeed) || other.maxGroundSpeed == maxGroundSpeed)&&(identical(other.maxIndicatedAirSpeed, maxIndicatedAirSpeed) || other.maxIndicatedAirSpeed == maxIndicatedAirSpeed)&&(identical(other.avgGroundSpeed, avgGroundSpeed) || other.avgGroundSpeed == avgGroundSpeed)&&(identical(other.avgIndicatedAirSpeed, avgIndicatedAirSpeed) || other.avgIndicatedAirSpeed == avgIndicatedAirSpeed)&&(identical(other.totalDistance, totalDistance) || other.totalDistance == totalDistance)&&(identical(other.maxDistanceFromTakeoff, maxDistanceFromTakeoff) || other.maxDistanceFromTakeoff == maxDistanceFromTakeoff)&&(identical(other.avgEngineRPM, avgEngineRPM) || other.avgEngineRPM == avgEngineRPM));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxAltitude,totalAscent,totalDescent,avgAltitude,maxGroundSpeed,maxIndicatedAirSpeed,avgGroundSpeed,avgIndicatedAirSpeed,totalDistance,maxDistanceFromTakeoff,avgEngineRPM);

@override
String toString() {
  return 'FlightStatistics(maxAltitude: $maxAltitude, totalAscent: $totalAscent, totalDescent: $totalDescent, avgAltitude: $avgAltitude, maxGroundSpeed: $maxGroundSpeed, maxIndicatedAirSpeed: $maxIndicatedAirSpeed, avgGroundSpeed: $avgGroundSpeed, avgIndicatedAirSpeed: $avgIndicatedAirSpeed, totalDistance: $totalDistance, maxDistanceFromTakeoff: $maxDistanceFromTakeoff, avgEngineRPM: $avgEngineRPM)';
}


}

/// @nodoc
abstract mixin class $FlightStatisticsCopyWith<$Res>  {
  factory $FlightStatisticsCopyWith(FlightStatistics value, $Res Function(FlightStatistics) _then) = _$FlightStatisticsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'max_altitude') double? maxAltitude,@JsonKey(name: 'total_ascent') double? totalAscent,@JsonKey(name: 'total_descent') double? totalDescent,@JsonKey(name: 'avg_altitude') double? avgAltitude,@JsonKey(name: 'max_ground_speed') double? maxGroundSpeed,@JsonKey(name: 'max_indicated_air_speed') double? maxIndicatedAirSpeed,@JsonKey(name: 'avg_ground_speed') double? avgGroundSpeed,@JsonKey(name: 'avg_indicated_air_speed') double? avgIndicatedAirSpeed,@JsonKey(name: 'total_distance') double? totalDistance,@JsonKey(name: 'max_distance_from_takeoff') double? maxDistanceFromTakeoff,@JsonKey(name: 'avg_engine_rpm') double? avgEngineRPM
});




}
/// @nodoc
class _$FlightStatisticsCopyWithImpl<$Res>
    implements $FlightStatisticsCopyWith<$Res> {
  _$FlightStatisticsCopyWithImpl(this._self, this._then);

  final FlightStatistics _self;
  final $Res Function(FlightStatistics) _then;

/// Create a copy of FlightStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxAltitude = freezed,Object? totalAscent = freezed,Object? totalDescent = freezed,Object? avgAltitude = freezed,Object? maxGroundSpeed = freezed,Object? maxIndicatedAirSpeed = freezed,Object? avgGroundSpeed = freezed,Object? avgIndicatedAirSpeed = freezed,Object? totalDistance = freezed,Object? maxDistanceFromTakeoff = freezed,Object? avgEngineRPM = freezed,}) {
  return _then(_self.copyWith(
maxAltitude: freezed == maxAltitude ? _self.maxAltitude : maxAltitude // ignore: cast_nullable_to_non_nullable
as double?,totalAscent: freezed == totalAscent ? _self.totalAscent : totalAscent // ignore: cast_nullable_to_non_nullable
as double?,totalDescent: freezed == totalDescent ? _self.totalDescent : totalDescent // ignore: cast_nullable_to_non_nullable
as double?,avgAltitude: freezed == avgAltitude ? _self.avgAltitude : avgAltitude // ignore: cast_nullable_to_non_nullable
as double?,maxGroundSpeed: freezed == maxGroundSpeed ? _self.maxGroundSpeed : maxGroundSpeed // ignore: cast_nullable_to_non_nullable
as double?,maxIndicatedAirSpeed: freezed == maxIndicatedAirSpeed ? _self.maxIndicatedAirSpeed : maxIndicatedAirSpeed // ignore: cast_nullable_to_non_nullable
as double?,avgGroundSpeed: freezed == avgGroundSpeed ? _self.avgGroundSpeed : avgGroundSpeed // ignore: cast_nullable_to_non_nullable
as double?,avgIndicatedAirSpeed: freezed == avgIndicatedAirSpeed ? _self.avgIndicatedAirSpeed : avgIndicatedAirSpeed // ignore: cast_nullable_to_non_nullable
as double?,totalDistance: freezed == totalDistance ? _self.totalDistance : totalDistance // ignore: cast_nullable_to_non_nullable
as double?,maxDistanceFromTakeoff: freezed == maxDistanceFromTakeoff ? _self.maxDistanceFromTakeoff : maxDistanceFromTakeoff // ignore: cast_nullable_to_non_nullable
as double?,avgEngineRPM: freezed == avgEngineRPM ? _self.avgEngineRPM : avgEngineRPM // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlightStatistics].
extension FlightStatisticsPatterns on FlightStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlightStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlightStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlightStatistics value)  $default,){
final _that = this;
switch (_that) {
case _FlightStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlightStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _FlightStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'max_altitude')  double? maxAltitude, @JsonKey(name: 'total_ascent')  double? totalAscent, @JsonKey(name: 'total_descent')  double? totalDescent, @JsonKey(name: 'avg_altitude')  double? avgAltitude, @JsonKey(name: 'max_ground_speed')  double? maxGroundSpeed, @JsonKey(name: 'max_indicated_air_speed')  double? maxIndicatedAirSpeed, @JsonKey(name: 'avg_ground_speed')  double? avgGroundSpeed, @JsonKey(name: 'avg_indicated_air_speed')  double? avgIndicatedAirSpeed, @JsonKey(name: 'total_distance')  double? totalDistance, @JsonKey(name: 'max_distance_from_takeoff')  double? maxDistanceFromTakeoff, @JsonKey(name: 'avg_engine_rpm')  double? avgEngineRPM)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlightStatistics() when $default != null:
return $default(_that.maxAltitude,_that.totalAscent,_that.totalDescent,_that.avgAltitude,_that.maxGroundSpeed,_that.maxIndicatedAirSpeed,_that.avgGroundSpeed,_that.avgIndicatedAirSpeed,_that.totalDistance,_that.maxDistanceFromTakeoff,_that.avgEngineRPM);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'max_altitude')  double? maxAltitude, @JsonKey(name: 'total_ascent')  double? totalAscent, @JsonKey(name: 'total_descent')  double? totalDescent, @JsonKey(name: 'avg_altitude')  double? avgAltitude, @JsonKey(name: 'max_ground_speed')  double? maxGroundSpeed, @JsonKey(name: 'max_indicated_air_speed')  double? maxIndicatedAirSpeed, @JsonKey(name: 'avg_ground_speed')  double? avgGroundSpeed, @JsonKey(name: 'avg_indicated_air_speed')  double? avgIndicatedAirSpeed, @JsonKey(name: 'total_distance')  double? totalDistance, @JsonKey(name: 'max_distance_from_takeoff')  double? maxDistanceFromTakeoff, @JsonKey(name: 'avg_engine_rpm')  double? avgEngineRPM)  $default,) {final _that = this;
switch (_that) {
case _FlightStatistics():
return $default(_that.maxAltitude,_that.totalAscent,_that.totalDescent,_that.avgAltitude,_that.maxGroundSpeed,_that.maxIndicatedAirSpeed,_that.avgGroundSpeed,_that.avgIndicatedAirSpeed,_that.totalDistance,_that.maxDistanceFromTakeoff,_that.avgEngineRPM);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'max_altitude')  double? maxAltitude, @JsonKey(name: 'total_ascent')  double? totalAscent, @JsonKey(name: 'total_descent')  double? totalDescent, @JsonKey(name: 'avg_altitude')  double? avgAltitude, @JsonKey(name: 'max_ground_speed')  double? maxGroundSpeed, @JsonKey(name: 'max_indicated_air_speed')  double? maxIndicatedAirSpeed, @JsonKey(name: 'avg_ground_speed')  double? avgGroundSpeed, @JsonKey(name: 'avg_indicated_air_speed')  double? avgIndicatedAirSpeed, @JsonKey(name: 'total_distance')  double? totalDistance, @JsonKey(name: 'max_distance_from_takeoff')  double? maxDistanceFromTakeoff, @JsonKey(name: 'avg_engine_rpm')  double? avgEngineRPM)?  $default,) {final _that = this;
switch (_that) {
case _FlightStatistics() when $default != null:
return $default(_that.maxAltitude,_that.totalAscent,_that.totalDescent,_that.avgAltitude,_that.maxGroundSpeed,_that.maxIndicatedAirSpeed,_that.avgGroundSpeed,_that.avgIndicatedAirSpeed,_that.totalDistance,_that.maxDistanceFromTakeoff,_that.avgEngineRPM);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FlightStatistics implements FlightStatistics {
  const _FlightStatistics({@JsonKey(name: 'max_altitude') this.maxAltitude, @JsonKey(name: 'total_ascent') this.totalAscent, @JsonKey(name: 'total_descent') this.totalDescent, @JsonKey(name: 'avg_altitude') this.avgAltitude, @JsonKey(name: 'max_ground_speed') this.maxGroundSpeed, @JsonKey(name: 'max_indicated_air_speed') this.maxIndicatedAirSpeed, @JsonKey(name: 'avg_ground_speed') this.avgGroundSpeed, @JsonKey(name: 'avg_indicated_air_speed') this.avgIndicatedAirSpeed, @JsonKey(name: 'total_distance') this.totalDistance, @JsonKey(name: 'max_distance_from_takeoff') this.maxDistanceFromTakeoff, @JsonKey(name: 'avg_engine_rpm') this.avgEngineRPM});
  factory _FlightStatistics.fromJson(Map<String, dynamic> json) => _$FlightStatisticsFromJson(json);

@override@JsonKey(name: 'max_altitude') final  double? maxAltitude;
@override@JsonKey(name: 'total_ascent') final  double? totalAscent;
@override@JsonKey(name: 'total_descent') final  double? totalDescent;
@override@JsonKey(name: 'avg_altitude') final  double? avgAltitude;
@override@JsonKey(name: 'max_ground_speed') final  double? maxGroundSpeed;
@override@JsonKey(name: 'max_indicated_air_speed') final  double? maxIndicatedAirSpeed;
@override@JsonKey(name: 'avg_ground_speed') final  double? avgGroundSpeed;
@override@JsonKey(name: 'avg_indicated_air_speed') final  double? avgIndicatedAirSpeed;
@override@JsonKey(name: 'total_distance') final  double? totalDistance;
@override@JsonKey(name: 'max_distance_from_takeoff') final  double? maxDistanceFromTakeoff;
@override@JsonKey(name: 'avg_engine_rpm') final  double? avgEngineRPM;

/// Create a copy of FlightStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightStatisticsCopyWith<_FlightStatistics> get copyWith => __$FlightStatisticsCopyWithImpl<_FlightStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlightStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlightStatistics&&(identical(other.maxAltitude, maxAltitude) || other.maxAltitude == maxAltitude)&&(identical(other.totalAscent, totalAscent) || other.totalAscent == totalAscent)&&(identical(other.totalDescent, totalDescent) || other.totalDescent == totalDescent)&&(identical(other.avgAltitude, avgAltitude) || other.avgAltitude == avgAltitude)&&(identical(other.maxGroundSpeed, maxGroundSpeed) || other.maxGroundSpeed == maxGroundSpeed)&&(identical(other.maxIndicatedAirSpeed, maxIndicatedAirSpeed) || other.maxIndicatedAirSpeed == maxIndicatedAirSpeed)&&(identical(other.avgGroundSpeed, avgGroundSpeed) || other.avgGroundSpeed == avgGroundSpeed)&&(identical(other.avgIndicatedAirSpeed, avgIndicatedAirSpeed) || other.avgIndicatedAirSpeed == avgIndicatedAirSpeed)&&(identical(other.totalDistance, totalDistance) || other.totalDistance == totalDistance)&&(identical(other.maxDistanceFromTakeoff, maxDistanceFromTakeoff) || other.maxDistanceFromTakeoff == maxDistanceFromTakeoff)&&(identical(other.avgEngineRPM, avgEngineRPM) || other.avgEngineRPM == avgEngineRPM));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxAltitude,totalAscent,totalDescent,avgAltitude,maxGroundSpeed,maxIndicatedAirSpeed,avgGroundSpeed,avgIndicatedAirSpeed,totalDistance,maxDistanceFromTakeoff,avgEngineRPM);

@override
String toString() {
  return 'FlightStatistics(maxAltitude: $maxAltitude, totalAscent: $totalAscent, totalDescent: $totalDescent, avgAltitude: $avgAltitude, maxGroundSpeed: $maxGroundSpeed, maxIndicatedAirSpeed: $maxIndicatedAirSpeed, avgGroundSpeed: $avgGroundSpeed, avgIndicatedAirSpeed: $avgIndicatedAirSpeed, totalDistance: $totalDistance, maxDistanceFromTakeoff: $maxDistanceFromTakeoff, avgEngineRPM: $avgEngineRPM)';
}


}

/// @nodoc
abstract mixin class _$FlightStatisticsCopyWith<$Res> implements $FlightStatisticsCopyWith<$Res> {
  factory _$FlightStatisticsCopyWith(_FlightStatistics value, $Res Function(_FlightStatistics) _then) = __$FlightStatisticsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'max_altitude') double? maxAltitude,@JsonKey(name: 'total_ascent') double? totalAscent,@JsonKey(name: 'total_descent') double? totalDescent,@JsonKey(name: 'avg_altitude') double? avgAltitude,@JsonKey(name: 'max_ground_speed') double? maxGroundSpeed,@JsonKey(name: 'max_indicated_air_speed') double? maxIndicatedAirSpeed,@JsonKey(name: 'avg_ground_speed') double? avgGroundSpeed,@JsonKey(name: 'avg_indicated_air_speed') double? avgIndicatedAirSpeed,@JsonKey(name: 'total_distance') double? totalDistance,@JsonKey(name: 'max_distance_from_takeoff') double? maxDistanceFromTakeoff,@JsonKey(name: 'avg_engine_rpm') double? avgEngineRPM
});




}
/// @nodoc
class __$FlightStatisticsCopyWithImpl<$Res>
    implements _$FlightStatisticsCopyWith<$Res> {
  __$FlightStatisticsCopyWithImpl(this._self, this._then);

  final _FlightStatistics _self;
  final $Res Function(_FlightStatistics) _then;

/// Create a copy of FlightStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxAltitude = freezed,Object? totalAscent = freezed,Object? totalDescent = freezed,Object? avgAltitude = freezed,Object? maxGroundSpeed = freezed,Object? maxIndicatedAirSpeed = freezed,Object? avgGroundSpeed = freezed,Object? avgIndicatedAirSpeed = freezed,Object? totalDistance = freezed,Object? maxDistanceFromTakeoff = freezed,Object? avgEngineRPM = freezed,}) {
  return _then(_FlightStatistics(
maxAltitude: freezed == maxAltitude ? _self.maxAltitude : maxAltitude // ignore: cast_nullable_to_non_nullable
as double?,totalAscent: freezed == totalAscent ? _self.totalAscent : totalAscent // ignore: cast_nullable_to_non_nullable
as double?,totalDescent: freezed == totalDescent ? _self.totalDescent : totalDescent // ignore: cast_nullable_to_non_nullable
as double?,avgAltitude: freezed == avgAltitude ? _self.avgAltitude : avgAltitude // ignore: cast_nullable_to_non_nullable
as double?,maxGroundSpeed: freezed == maxGroundSpeed ? _self.maxGroundSpeed : maxGroundSpeed // ignore: cast_nullable_to_non_nullable
as double?,maxIndicatedAirSpeed: freezed == maxIndicatedAirSpeed ? _self.maxIndicatedAirSpeed : maxIndicatedAirSpeed // ignore: cast_nullable_to_non_nullable
as double?,avgGroundSpeed: freezed == avgGroundSpeed ? _self.avgGroundSpeed : avgGroundSpeed // ignore: cast_nullable_to_non_nullable
as double?,avgIndicatedAirSpeed: freezed == avgIndicatedAirSpeed ? _self.avgIndicatedAirSpeed : avgIndicatedAirSpeed // ignore: cast_nullable_to_non_nullable
as double?,totalDistance: freezed == totalDistance ? _self.totalDistance : totalDistance // ignore: cast_nullable_to_non_nullable
as double?,maxDistanceFromTakeoff: freezed == maxDistanceFromTakeoff ? _self.maxDistanceFromTakeoff : maxDistanceFromTakeoff // ignore: cast_nullable_to_non_nullable
as double?,avgEngineRPM: freezed == avgEngineRPM ? _self.avgEngineRPM : avgEngineRPM // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
