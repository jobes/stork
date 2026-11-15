// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notam.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Notam {

 String get featureName; String get endDate; String get icaoMessage; String get id; String get type; String get issuer; DateTime get from; DateTime? get to; String? get schedule; String get msg; String? get lowerLimit2; String? get upperLimit2; String get fir; double get latitude; double get longitude; double get radius; int get flightLevelLowerLimit; int get flightLevelUpperLimit;
/// Create a copy of Notam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotamCopyWith<Notam> get copyWith => _$NotamCopyWithImpl<Notam>(this as Notam, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Notam;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Notam&&(identical(other.featureName, _this.featureName) || other.featureName == _this.featureName)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.icaoMessage, _this.icaoMessage) || other.icaoMessage == _this.icaoMessage)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.issuer, _this.issuer) || other.issuer == _this.issuer)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.schedule, _this.schedule) || other.schedule == _this.schedule)&&(identical(other.msg, _this.msg) || other.msg == _this.msg)&&(identical(other.lowerLimit2, _this.lowerLimit2) || other.lowerLimit2 == _this.lowerLimit2)&&(identical(other.upperLimit2, _this.upperLimit2) || other.upperLimit2 == _this.upperLimit2)&&(identical(other.fir, _this.fir) || other.fir == _this.fir)&&(identical(other.latitude, _this.latitude) || other.latitude == _this.latitude)&&(identical(other.longitude, _this.longitude) || other.longitude == _this.longitude)&&(identical(other.radius, _this.radius) || other.radius == _this.radius)&&(identical(other.flightLevelLowerLimit, _this.flightLevelLowerLimit) || other.flightLevelLowerLimit == _this.flightLevelLowerLimit)&&(identical(other.flightLevelUpperLimit, _this.flightLevelUpperLimit) || other.flightLevelUpperLimit == _this.flightLevelUpperLimit));
}


@override
int get hashCode {
  final _this = this as Notam;
  return Object.hash(runtimeType,_this.featureName,_this.endDate,_this.icaoMessage,_this.id,_this.type,_this.issuer,_this.from,_this.to,_this.schedule,_this.msg,_this.lowerLimit2,_this.upperLimit2,_this.fir,_this.latitude,_this.longitude,_this.radius,_this.flightLevelLowerLimit,_this.flightLevelUpperLimit);
}

@override
String toString() {
  final _this = this as Notam;
  return 'Notam(featureName: ${_this.featureName}, endDate: ${_this.endDate}, icaoMessage: ${_this.icaoMessage}, id: ${_this.id}, type: ${_this.type}, issuer: ${_this.issuer}, from: ${_this.from}, to: ${_this.to}, schedule: ${_this.schedule}, msg: ${_this.msg}, lowerLimit2: ${_this.lowerLimit2}, upperLimit2: ${_this.upperLimit2}, fir: ${_this.fir}, latitude: ${_this.latitude}, longitude: ${_this.longitude}, radius: ${_this.radius}, flightLevelLowerLimit: ${_this.flightLevelLowerLimit}, flightLevelUpperLimit: ${_this.flightLevelUpperLimit})';
}


}

/// @nodoc
abstract mixin class $NotamCopyWith<$Res>  {
  factory $NotamCopyWith(Notam value, $Res Function(Notam) _then) = _$NotamCopyWithImpl;
@useResult
$Res call({
 String featureName, String endDate, String icaoMessage, String id, String type, String issuer, DateTime from, DateTime? to, String? schedule, String msg, String? lowerLimit2, String? upperLimit2, String fir, double latitude, double longitude, double radius, int flightLevelLowerLimit, int flightLevelUpperLimit
});




}
/// @nodoc
class _$NotamCopyWithImpl<$Res>
    implements $NotamCopyWith<$Res> {
  _$NotamCopyWithImpl(this._self, this._then);

  final Notam _self;
  final $Res Function(Notam) _then;

/// Create a copy of Notam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? featureName = null,Object? endDate = null,Object? icaoMessage = null,Object? id = null,Object? type = null,Object? issuer = null,Object? from = null,Object? to = freezed,Object? schedule = freezed,Object? msg = null,Object? lowerLimit2 = freezed,Object? upperLimit2 = freezed,Object? fir = null,Object? latitude = null,Object? longitude = null,Object? radius = null,Object? flightLevelLowerLimit = null,Object? flightLevelUpperLimit = null,}) {
  return _then(Notam(
featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,icaoMessage: null == icaoMessage ? _self.icaoMessage : icaoMessage // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,issuer: null == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,schedule: freezed == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String?,msg: null == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String,lowerLimit2: freezed == lowerLimit2 ? _self.lowerLimit2 : lowerLimit2 // ignore: cast_nullable_to_non_nullable
as String?,upperLimit2: freezed == upperLimit2 ? _self.upperLimit2 : upperLimit2 // ignore: cast_nullable_to_non_nullable
as String?,fir: null == fir ? _self.fir : fir // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,flightLevelLowerLimit: null == flightLevelLowerLimit ? _self.flightLevelLowerLimit : flightLevelLowerLimit // ignore: cast_nullable_to_non_nullable
as int,flightLevelUpperLimit: null == flightLevelUpperLimit ? _self.flightLevelUpperLimit : flightLevelUpperLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Notam].
extension NotamPatterns on Notam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Notam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Notam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Notam value)  $default,){
final _that = this;
switch (_that) {
case _Notam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Notam value)?  $default,){
final _that = this;
switch (_that) {
case _Notam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String featureName,  String endDate,  String icaoMessage,  String id,  String type,  String issuer,  DateTime from,  DateTime? to,  String? schedule,  String msg,  String? lowerLimit2,  String? upperLimit2,  String fir,  double latitude,  double longitude,  double radius,  int flightLevelLowerLimit,  int flightLevelUpperLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Notam() when $default != null:
return $default(_that.featureName,_that.endDate,_that.icaoMessage,_that.id,_that.type,_that.issuer,_that.from,_that.to,_that.schedule,_that.msg,_that.lowerLimit2,_that.upperLimit2,_that.fir,_that.latitude,_that.longitude,_that.radius,_that.flightLevelLowerLimit,_that.flightLevelUpperLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String featureName,  String endDate,  String icaoMessage,  String id,  String type,  String issuer,  DateTime from,  DateTime? to,  String? schedule,  String msg,  String? lowerLimit2,  String? upperLimit2,  String fir,  double latitude,  double longitude,  double radius,  int flightLevelLowerLimit,  int flightLevelUpperLimit)  $default,) {final _that = this;
switch (_that) {
case _Notam():
return $default(_that.featureName,_that.endDate,_that.icaoMessage,_that.id,_that.type,_that.issuer,_that.from,_that.to,_that.schedule,_that.msg,_that.lowerLimit2,_that.upperLimit2,_that.fir,_that.latitude,_that.longitude,_that.radius,_that.flightLevelLowerLimit,_that.flightLevelUpperLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String featureName,  String endDate,  String icaoMessage,  String id,  String type,  String issuer,  DateTime from,  DateTime? to,  String? schedule,  String msg,  String? lowerLimit2,  String? upperLimit2,  String fir,  double latitude,  double longitude,  double radius,  int flightLevelLowerLimit,  int flightLevelUpperLimit)?  $default,) {final _that = this;
switch (_that) {
case _Notam() when $default != null:
return $default(_that.featureName,_that.endDate,_that.icaoMessage,_that.id,_that.type,_that.issuer,_that.from,_that.to,_that.schedule,_that.msg,_that.lowerLimit2,_that.upperLimit2,_that.fir,_that.latitude,_that.longitude,_that.radius,_that.flightLevelLowerLimit,_that.flightLevelUpperLimit);case _:
  return null;

}
}

}

/// @nodoc


class _Notam extends Notam {
  const _Notam({this.featureName = '', this.endDate = '', this.icaoMessage = '', this.id = '', this.type = '', this.issuer = '', required this.from, this.to, this.schedule, this.msg = '', this.lowerLimit2, this.upperLimit2, this.fir = '', this.latitude = 0.0, this.longitude = 0.0, this.radius = 0.0, this.flightLevelLowerLimit = 0, this.flightLevelUpperLimit = 999}): super._();
  

@override@JsonKey() final  String featureName;
@override@JsonKey() final  String endDate;
@override@JsonKey() final  String icaoMessage;
@override@JsonKey() final  String id;
@override@JsonKey() final  String type;
@override@JsonKey() final  String issuer;
@override final  DateTime from;
@override final  DateTime? to;
@override final  String? schedule;
@override@JsonKey() final  String msg;
@override final  String? lowerLimit2;
@override final  String? upperLimit2;
@override@JsonKey() final  String fir;
@override@JsonKey() final  double latitude;
@override@JsonKey() final  double longitude;
@override@JsonKey() final  double radius;
@override@JsonKey() final  int flightLevelLowerLimit;
@override@JsonKey() final  int flightLevelUpperLimit;

/// Create a copy of Notam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotamCopyWith<_Notam> get copyWith => __$NotamCopyWithImpl<_Notam>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Notam&&(identical(other.featureName, featureName) || other.featureName == featureName)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.icaoMessage, icaoMessage) || other.icaoMessage == icaoMessage)&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.msg, msg) || other.msg == msg)&&(identical(other.lowerLimit2, lowerLimit2) || other.lowerLimit2 == lowerLimit2)&&(identical(other.upperLimit2, upperLimit2) || other.upperLimit2 == upperLimit2)&&(identical(other.fir, fir) || other.fir == fir)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.radius, radius) || other.radius == radius)&&(identical(other.flightLevelLowerLimit, flightLevelLowerLimit) || other.flightLevelLowerLimit == flightLevelLowerLimit)&&(identical(other.flightLevelUpperLimit, flightLevelUpperLimit) || other.flightLevelUpperLimit == flightLevelUpperLimit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,featureName,endDate,icaoMessage,id,type,issuer,from,to,schedule,msg,lowerLimit2,upperLimit2,fir,latitude,longitude,radius,flightLevelLowerLimit,flightLevelUpperLimit);
}

@override
String toString() {
    return 'Notam(featureName: $featureName, endDate: $endDate, icaoMessage: $icaoMessage, id: $id, type: $type, issuer: $issuer, from: $from, to: $to, schedule: $schedule, msg: $msg, lowerLimit2: $lowerLimit2, upperLimit2: $upperLimit2, fir: $fir, latitude: $latitude, longitude: $longitude, radius: $radius, flightLevelLowerLimit: $flightLevelLowerLimit, flightLevelUpperLimit: $flightLevelUpperLimit)';
}


}

/// @nodoc
abstract mixin class _$NotamCopyWith<$Res> implements $NotamCopyWith<$Res> {
  factory _$NotamCopyWith(_Notam value, $Res Function(_Notam) _then) = __$NotamCopyWithImpl;
@override @useResult
$Res call({
 String featureName, String endDate, String icaoMessage, String id, String type, String issuer, DateTime from, DateTime? to, String? schedule, String msg, String? lowerLimit2, String? upperLimit2, String fir, double latitude, double longitude, double radius, int flightLevelLowerLimit, int flightLevelUpperLimit
});




}
/// @nodoc
class __$NotamCopyWithImpl<$Res>
    implements _$NotamCopyWith<$Res> {
  __$NotamCopyWithImpl(this._self, this._then);

  final _Notam _self;
  final $Res Function(_Notam) _then;

/// Create a copy of Notam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? featureName = null,Object? endDate = null,Object? icaoMessage = null,Object? id = null,Object? type = null,Object? issuer = null,Object? from = null,Object? to = freezed,Object? schedule = freezed,Object? msg = null,Object? lowerLimit2 = freezed,Object? upperLimit2 = freezed,Object? fir = null,Object? latitude = null,Object? longitude = null,Object? radius = null,Object? flightLevelLowerLimit = null,Object? flightLevelUpperLimit = null,}) {
  return _then(_Notam(
featureName: null == featureName ? _self.featureName : featureName // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,icaoMessage: null == icaoMessage ? _self.icaoMessage : icaoMessage // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,issuer: null == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,schedule: freezed == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String?,msg: null == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String,lowerLimit2: freezed == lowerLimit2 ? _self.lowerLimit2 : lowerLimit2 // ignore: cast_nullable_to_non_nullable
as String?,upperLimit2: freezed == upperLimit2 ? _self.upperLimit2 : upperLimit2 // ignore: cast_nullable_to_non_nullable
as String?,fir: null == fir ? _self.fir : fir // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,flightLevelLowerLimit: null == flightLevelLowerLimit ? _self.flightLevelLowerLimit : flightLevelLowerLimit // ignore: cast_nullable_to_non_nullable
as int,flightLevelUpperLimit: null == flightLevelUpperLimit ? _self.flightLevelUpperLimit : flightLevelUpperLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
