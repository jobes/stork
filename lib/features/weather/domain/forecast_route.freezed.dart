// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forecast_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForecastRoutePoint {

 String get id; ForecastLocation get location; ForecastLocation? get profileLocation; DateTime get eta; Duration get duration; double get distanceMeters; double? get altitudeFeet; double? get bearing; int? get waypointIndex;
/// Create a copy of ForecastRoutePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastRoutePointCopyWith<ForecastRoutePoint> get copyWith => _$ForecastRoutePointCopyWithImpl<ForecastRoutePoint>(this as ForecastRoutePoint, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ForecastRoutePoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastRoutePoint&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.profileLocation, _this.profileLocation) || other.profileLocation == _this.profileLocation)&&(identical(other.eta, _this.eta) || other.eta == _this.eta)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.distanceMeters, _this.distanceMeters) || other.distanceMeters == _this.distanceMeters)&&(identical(other.altitudeFeet, _this.altitudeFeet) || other.altitudeFeet == _this.altitudeFeet)&&(identical(other.bearing, _this.bearing) || other.bearing == _this.bearing)&&(identical(other.waypointIndex, _this.waypointIndex) || other.waypointIndex == _this.waypointIndex));
}


@override
int get hashCode {
  final _this = this as ForecastRoutePoint;
  return Object.hash(runtimeType,_this.id,_this.location,_this.profileLocation,_this.eta,_this.duration,_this.distanceMeters,_this.altitudeFeet,_this.bearing,_this.waypointIndex);
}

@override
String toString() {
  final _this = this as ForecastRoutePoint;
  return 'ForecastRoutePoint(id: ${_this.id}, location: ${_this.location}, profileLocation: ${_this.profileLocation}, eta: ${_this.eta}, duration: ${_this.duration}, distanceMeters: ${_this.distanceMeters}, altitudeFeet: ${_this.altitudeFeet}, bearing: ${_this.bearing}, waypointIndex: ${_this.waypointIndex})';
}


}

/// @nodoc
abstract mixin class $ForecastRoutePointCopyWith<$Res>  {
  factory $ForecastRoutePointCopyWith(ForecastRoutePoint value, $Res Function(ForecastRoutePoint) _then) = _$ForecastRoutePointCopyWithImpl;
@useResult
$Res call({
 String id, ForecastLocation location, ForecastLocation? profileLocation, DateTime eta, Duration duration, double distanceMeters, double? altitudeFeet, double? bearing, int? waypointIndex
});




}
/// @nodoc
class _$ForecastRoutePointCopyWithImpl<$Res>
    implements $ForecastRoutePointCopyWith<$Res> {
  _$ForecastRoutePointCopyWithImpl(this._self, this._then);

  final ForecastRoutePoint _self;
  final $Res Function(ForecastRoutePoint) _then;

/// Create a copy of ForecastRoutePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? location = null,Object? profileLocation = freezed,Object? eta = null,Object? duration = null,Object? distanceMeters = null,Object? altitudeFeet = freezed,Object? bearing = freezed,Object? waypointIndex = freezed,}) {
  return _then(ForecastRoutePoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as ForecastLocation,profileLocation: freezed == profileLocation ? _self.profileLocation : profileLocation // ignore: cast_nullable_to_non_nullable
as ForecastLocation?,eta: null == eta ? _self.eta : eta // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,altitudeFeet: freezed == altitudeFeet ? _self.altitudeFeet : altitudeFeet // ignore: cast_nullable_to_non_nullable
as double?,bearing: freezed == bearing ? _self.bearing : bearing // ignore: cast_nullable_to_non_nullable
as double?,waypointIndex: freezed == waypointIndex ? _self.waypointIndex : waypointIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ForecastRoutePoint].
extension ForecastRoutePointPatterns on ForecastRoutePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForecastRoutePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForecastRoutePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForecastRoutePoint value)  $default,){
final _that = this;
switch (_that) {
case _ForecastRoutePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForecastRoutePoint value)?  $default,){
final _that = this;
switch (_that) {
case _ForecastRoutePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ForecastLocation location,  ForecastLocation? profileLocation,  DateTime eta,  Duration duration,  double distanceMeters,  double? altitudeFeet,  double? bearing,  int? waypointIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForecastRoutePoint() when $default != null:
return $default(_that.id,_that.location,_that.profileLocation,_that.eta,_that.duration,_that.distanceMeters,_that.altitudeFeet,_that.bearing,_that.waypointIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ForecastLocation location,  ForecastLocation? profileLocation,  DateTime eta,  Duration duration,  double distanceMeters,  double? altitudeFeet,  double? bearing,  int? waypointIndex)  $default,) {final _that = this;
switch (_that) {
case _ForecastRoutePoint():
return $default(_that.id,_that.location,_that.profileLocation,_that.eta,_that.duration,_that.distanceMeters,_that.altitudeFeet,_that.bearing,_that.waypointIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ForecastLocation location,  ForecastLocation? profileLocation,  DateTime eta,  Duration duration,  double distanceMeters,  double? altitudeFeet,  double? bearing,  int? waypointIndex)?  $default,) {final _that = this;
switch (_that) {
case _ForecastRoutePoint() when $default != null:
return $default(_that.id,_that.location,_that.profileLocation,_that.eta,_that.duration,_that.distanceMeters,_that.altitudeFeet,_that.bearing,_that.waypointIndex);case _:
  return null;

}
}

}

/// @nodoc


class _ForecastRoutePoint implements ForecastRoutePoint {
  const _ForecastRoutePoint({required this.id, required this.location, this.profileLocation, required this.eta, required this.duration, required this.distanceMeters, required this.altitudeFeet, this.bearing, this.waypointIndex});
  

@override final  String id;
@override final  ForecastLocation location;
@override final  ForecastLocation? profileLocation;
@override final  DateTime eta;
@override final  Duration duration;
@override final  double distanceMeters;
@override final  double? altitudeFeet;
@override final  double? bearing;
@override final  int? waypointIndex;

/// Create a copy of ForecastRoutePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForecastRoutePointCopyWith<_ForecastRoutePoint> get copyWith => __$ForecastRoutePointCopyWithImpl<_ForecastRoutePoint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForecastRoutePoint&&(identical(other.id, id) || other.id == id)&&(identical(other.location, location) || other.location == location)&&(identical(other.profileLocation, profileLocation) || other.profileLocation == profileLocation)&&(identical(other.eta, eta) || other.eta == eta)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.altitudeFeet, altitudeFeet) || other.altitudeFeet == altitudeFeet)&&(identical(other.bearing, bearing) || other.bearing == bearing)&&(identical(other.waypointIndex, waypointIndex) || other.waypointIndex == waypointIndex));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,location,profileLocation,eta,duration,distanceMeters,altitudeFeet,bearing,waypointIndex);
}

@override
String toString() {
    return 'ForecastRoutePoint(id: $id, location: $location, profileLocation: $profileLocation, eta: $eta, duration: $duration, distanceMeters: $distanceMeters, altitudeFeet: $altitudeFeet, bearing: $bearing, waypointIndex: $waypointIndex)';
}


}

/// @nodoc
abstract mixin class _$ForecastRoutePointCopyWith<$Res> implements $ForecastRoutePointCopyWith<$Res> {
  factory _$ForecastRoutePointCopyWith(_ForecastRoutePoint value, $Res Function(_ForecastRoutePoint) _then) = __$ForecastRoutePointCopyWithImpl;
@override @useResult
$Res call({
 String id, ForecastLocation location, ForecastLocation? profileLocation, DateTime eta, Duration duration, double distanceMeters, double? altitudeFeet, double? bearing, int? waypointIndex
});




}
/// @nodoc
class __$ForecastRoutePointCopyWithImpl<$Res>
    implements _$ForecastRoutePointCopyWith<$Res> {
  __$ForecastRoutePointCopyWithImpl(this._self, this._then);

  final _ForecastRoutePoint _self;
  final $Res Function(_ForecastRoutePoint) _then;

/// Create a copy of ForecastRoutePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? location = null,Object? profileLocation = freezed,Object? eta = null,Object? duration = null,Object? distanceMeters = null,Object? altitudeFeet = freezed,Object? bearing = freezed,Object? waypointIndex = freezed,}) {
  return _then(_ForecastRoutePoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as ForecastLocation,profileLocation: freezed == profileLocation ? _self.profileLocation : profileLocation // ignore: cast_nullable_to_non_nullable
as ForecastLocation?,eta: null == eta ? _self.eta : eta // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,altitudeFeet: freezed == altitudeFeet ? _self.altitudeFeet : altitudeFeet // ignore: cast_nullable_to_non_nullable
as double?,bearing: freezed == bearing ? _self.bearing : bearing // ignore: cast_nullable_to_non_nullable
as double?,waypointIndex: freezed == waypointIndex ? _self.waypointIndex : waypointIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
