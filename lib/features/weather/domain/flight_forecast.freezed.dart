// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight_forecast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FlightForecast {

 ForecastWind? get wind; double? get temperatureC; double? get gustMs; double? get precipitationMm; double? get lowCloudPercent; double? get qnhHpa; double? get qfeHpa; DateTime? get intervalEnd; DateTime get downloadedAt; int? get weatherCode;
/// Create a copy of FlightForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightForecastCopyWith<FlightForecast> get copyWith => _$FlightForecastCopyWithImpl<FlightForecast>(this as FlightForecast, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FlightForecast;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlightForecast&&(identical(other.wind, _this.wind) || other.wind == _this.wind)&&(identical(other.temperatureC, _this.temperatureC) || other.temperatureC == _this.temperatureC)&&(identical(other.gustMs, _this.gustMs) || other.gustMs == _this.gustMs)&&(identical(other.precipitationMm, _this.precipitationMm) || other.precipitationMm == _this.precipitationMm)&&(identical(other.lowCloudPercent, _this.lowCloudPercent) || other.lowCloudPercent == _this.lowCloudPercent)&&(identical(other.qnhHpa, _this.qnhHpa) || other.qnhHpa == _this.qnhHpa)&&(identical(other.qfeHpa, _this.qfeHpa) || other.qfeHpa == _this.qfeHpa)&&(identical(other.intervalEnd, _this.intervalEnd) || other.intervalEnd == _this.intervalEnd)&&(identical(other.downloadedAt, _this.downloadedAt) || other.downloadedAt == _this.downloadedAt)&&(identical(other.weatherCode, _this.weatherCode) || other.weatherCode == _this.weatherCode));
}


@override
int get hashCode {
  final _this = this as FlightForecast;
  return Object.hash(runtimeType,_this.wind,_this.temperatureC,_this.gustMs,_this.precipitationMm,_this.lowCloudPercent,_this.qnhHpa,_this.qfeHpa,_this.intervalEnd,_this.downloadedAt,_this.weatherCode);
}

@override
String toString() {
  final _this = this as FlightForecast;
  return 'FlightForecast(wind: ${_this.wind}, temperatureC: ${_this.temperatureC}, gustMs: ${_this.gustMs}, precipitationMm: ${_this.precipitationMm}, lowCloudPercent: ${_this.lowCloudPercent}, qnhHpa: ${_this.qnhHpa}, qfeHpa: ${_this.qfeHpa}, intervalEnd: ${_this.intervalEnd}, downloadedAt: ${_this.downloadedAt}, weatherCode: ${_this.weatherCode})';
}


}

/// @nodoc
abstract mixin class $FlightForecastCopyWith<$Res>  {
  factory $FlightForecastCopyWith(FlightForecast value, $Res Function(FlightForecast) _then) = _$FlightForecastCopyWithImpl;
@useResult
$Res call({
 ForecastWind? wind, double? temperatureC, double? gustMs, double? precipitationMm, double? lowCloudPercent, double? qnhHpa, double? qfeHpa, DateTime? intervalEnd, DateTime downloadedAt, int? weatherCode
});




}
/// @nodoc
class _$FlightForecastCopyWithImpl<$Res>
    implements $FlightForecastCopyWith<$Res> {
  _$FlightForecastCopyWithImpl(this._self, this._then);

  final FlightForecast _self;
  final $Res Function(FlightForecast) _then;

/// Create a copy of FlightForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wind = freezed,Object? temperatureC = freezed,Object? gustMs = freezed,Object? precipitationMm = freezed,Object? lowCloudPercent = freezed,Object? qnhHpa = freezed,Object? qfeHpa = freezed,Object? intervalEnd = freezed,Object? downloadedAt = null,Object? weatherCode = freezed,}) {
  return _then(FlightForecast(
wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as ForecastWind?,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as double?,gustMs: freezed == gustMs ? _self.gustMs : gustMs // ignore: cast_nullable_to_non_nullable
as double?,precipitationMm: freezed == precipitationMm ? _self.precipitationMm : precipitationMm // ignore: cast_nullable_to_non_nullable
as double?,lowCloudPercent: freezed == lowCloudPercent ? _self.lowCloudPercent : lowCloudPercent // ignore: cast_nullable_to_non_nullable
as double?,qnhHpa: freezed == qnhHpa ? _self.qnhHpa : qnhHpa // ignore: cast_nullable_to_non_nullable
as double?,qfeHpa: freezed == qfeHpa ? _self.qfeHpa : qfeHpa // ignore: cast_nullable_to_non_nullable
as double?,intervalEnd: freezed == intervalEnd ? _self.intervalEnd : intervalEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,downloadedAt: null == downloadedAt ? _self.downloadedAt : downloadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,weatherCode: freezed == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlightForecast].
extension FlightForecastPatterns on FlightForecast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlightForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlightForecast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlightForecast value)  $default,){
final _that = this;
switch (_that) {
case _FlightForecast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlightForecast value)?  $default,){
final _that = this;
switch (_that) {
case _FlightForecast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ForecastWind? wind,  double? temperatureC,  double? gustMs,  double? precipitationMm,  double? lowCloudPercent,  double? qnhHpa,  double? qfeHpa,  DateTime? intervalEnd,  DateTime downloadedAt,  int? weatherCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlightForecast() when $default != null:
return $default(_that.wind,_that.temperatureC,_that.gustMs,_that.precipitationMm,_that.lowCloudPercent,_that.qnhHpa,_that.qfeHpa,_that.intervalEnd,_that.downloadedAt,_that.weatherCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ForecastWind? wind,  double? temperatureC,  double? gustMs,  double? precipitationMm,  double? lowCloudPercent,  double? qnhHpa,  double? qfeHpa,  DateTime? intervalEnd,  DateTime downloadedAt,  int? weatherCode)  $default,) {final _that = this;
switch (_that) {
case _FlightForecast():
return $default(_that.wind,_that.temperatureC,_that.gustMs,_that.precipitationMm,_that.lowCloudPercent,_that.qnhHpa,_that.qfeHpa,_that.intervalEnd,_that.downloadedAt,_that.weatherCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ForecastWind? wind,  double? temperatureC,  double? gustMs,  double? precipitationMm,  double? lowCloudPercent,  double? qnhHpa,  double? qfeHpa,  DateTime? intervalEnd,  DateTime downloadedAt,  int? weatherCode)?  $default,) {final _that = this;
switch (_that) {
case _FlightForecast() when $default != null:
return $default(_that.wind,_that.temperatureC,_that.gustMs,_that.precipitationMm,_that.lowCloudPercent,_that.qnhHpa,_that.qfeHpa,_that.intervalEnd,_that.downloadedAt,_that.weatherCode);case _:
  return null;

}
}

}

/// @nodoc


class _FlightForecast implements FlightForecast {
  const _FlightForecast({required this.wind, required this.temperatureC, required this.gustMs, required this.precipitationMm, required this.lowCloudPercent, required this.qnhHpa, required this.qfeHpa, required this.intervalEnd, required this.downloadedAt, this.weatherCode});
  

@override final  ForecastWind? wind;
@override final  double? temperatureC;
@override final  double? gustMs;
@override final  double? precipitationMm;
@override final  double? lowCloudPercent;
@override final  double? qnhHpa;
@override final  double? qfeHpa;
@override final  DateTime? intervalEnd;
@override final  DateTime downloadedAt;
@override final  int? weatherCode;

/// Create a copy of FlightForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightForecastCopyWith<_FlightForecast> get copyWith => __$FlightForecastCopyWithImpl<_FlightForecast>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlightForecast&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.temperatureC, temperatureC) || other.temperatureC == temperatureC)&&(identical(other.gustMs, gustMs) || other.gustMs == gustMs)&&(identical(other.precipitationMm, precipitationMm) || other.precipitationMm == precipitationMm)&&(identical(other.lowCloudPercent, lowCloudPercent) || other.lowCloudPercent == lowCloudPercent)&&(identical(other.qnhHpa, qnhHpa) || other.qnhHpa == qnhHpa)&&(identical(other.qfeHpa, qfeHpa) || other.qfeHpa == qfeHpa)&&(identical(other.intervalEnd, intervalEnd) || other.intervalEnd == intervalEnd)&&(identical(other.downloadedAt, downloadedAt) || other.downloadedAt == downloadedAt)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,wind,temperatureC,gustMs,precipitationMm,lowCloudPercent,qnhHpa,qfeHpa,intervalEnd,downloadedAt,weatherCode);
}

@override
String toString() {
    return 'FlightForecast(wind: $wind, temperatureC: $temperatureC, gustMs: $gustMs, precipitationMm: $precipitationMm, lowCloudPercent: $lowCloudPercent, qnhHpa: $qnhHpa, qfeHpa: $qfeHpa, intervalEnd: $intervalEnd, downloadedAt: $downloadedAt, weatherCode: $weatherCode)';
}


}

/// @nodoc
abstract mixin class _$FlightForecastCopyWith<$Res> implements $FlightForecastCopyWith<$Res> {
  factory _$FlightForecastCopyWith(_FlightForecast value, $Res Function(_FlightForecast) _then) = __$FlightForecastCopyWithImpl;
@override @useResult
$Res call({
 ForecastWind? wind, double? temperatureC, double? gustMs, double? precipitationMm, double? lowCloudPercent, double? qnhHpa, double? qfeHpa, DateTime? intervalEnd, DateTime downloadedAt, int? weatherCode
});




}
/// @nodoc
class __$FlightForecastCopyWithImpl<$Res>
    implements _$FlightForecastCopyWith<$Res> {
  __$FlightForecastCopyWithImpl(this._self, this._then);

  final _FlightForecast _self;
  final $Res Function(_FlightForecast) _then;

/// Create a copy of FlightForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wind = freezed,Object? temperatureC = freezed,Object? gustMs = freezed,Object? precipitationMm = freezed,Object? lowCloudPercent = freezed,Object? qnhHpa = freezed,Object? qfeHpa = freezed,Object? intervalEnd = freezed,Object? downloadedAt = null,Object? weatherCode = freezed,}) {
  return _then(_FlightForecast(
wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as ForecastWind?,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as double?,gustMs: freezed == gustMs ? _self.gustMs : gustMs // ignore: cast_nullable_to_non_nullable
as double?,precipitationMm: freezed == precipitationMm ? _self.precipitationMm : precipitationMm // ignore: cast_nullable_to_non_nullable
as double?,lowCloudPercent: freezed == lowCloudPercent ? _self.lowCloudPercent : lowCloudPercent // ignore: cast_nullable_to_non_nullable
as double?,qnhHpa: freezed == qnhHpa ? _self.qnhHpa : qnhHpa // ignore: cast_nullable_to_non_nullable
as double?,qfeHpa: freezed == qfeHpa ? _self.qfeHpa : qfeHpa // ignore: cast_nullable_to_non_nullable
as double?,intervalEnd: freezed == intervalEnd ? _self.intervalEnd : intervalEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,downloadedAt: null == downloadedAt ? _self.downloadedAt : downloadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,weatherCode: freezed == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
