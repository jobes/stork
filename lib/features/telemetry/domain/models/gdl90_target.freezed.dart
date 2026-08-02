// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gdl90_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Gdl90Target {

 String get id; String? get callsign; double get latitude; double get longitude; double get altitudeFeet; bool get altitudeValid; double get trackDegrees; double get speedKnots; bool get speedValid; double get verticalSpeedFpm; bool get verticalSpeedValid; DateTime get lastUpdated; int get emitterCategory;
/// Create a copy of Gdl90Target
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Gdl90TargetCopyWith<Gdl90Target> get copyWith => _$Gdl90TargetCopyWithImpl<Gdl90Target>(this as Gdl90Target, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gdl90Target&&(identical(other.id, id) || other.id == id)&&(identical(other.callsign, callsign) || other.callsign == callsign)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.altitudeFeet, altitudeFeet) || other.altitudeFeet == altitudeFeet)&&(identical(other.altitudeValid, altitudeValid) || other.altitudeValid == altitudeValid)&&(identical(other.trackDegrees, trackDegrees) || other.trackDegrees == trackDegrees)&&(identical(other.speedKnots, speedKnots) || other.speedKnots == speedKnots)&&(identical(other.speedValid, speedValid) || other.speedValid == speedValid)&&(identical(other.verticalSpeedFpm, verticalSpeedFpm) || other.verticalSpeedFpm == verticalSpeedFpm)&&(identical(other.verticalSpeedValid, verticalSpeedValid) || other.verticalSpeedValid == verticalSpeedValid)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.emitterCategory, emitterCategory) || other.emitterCategory == emitterCategory));
}


@override
int get hashCode => Object.hash(runtimeType,id,callsign,latitude,longitude,altitudeFeet,altitudeValid,trackDegrees,speedKnots,speedValid,verticalSpeedFpm,verticalSpeedValid,lastUpdated,emitterCategory);

@override
String toString() {
  return 'Gdl90Target(id: $id, callsign: $callsign, latitude: $latitude, longitude: $longitude, altitudeFeet: $altitudeFeet, altitudeValid: $altitudeValid, trackDegrees: $trackDegrees, speedKnots: $speedKnots, speedValid: $speedValid, verticalSpeedFpm: $verticalSpeedFpm, verticalSpeedValid: $verticalSpeedValid, lastUpdated: $lastUpdated, emitterCategory: $emitterCategory)';
}


}

/// @nodoc
abstract mixin class $Gdl90TargetCopyWith<$Res>  {
  factory $Gdl90TargetCopyWith(Gdl90Target value, $Res Function(Gdl90Target) _then) = _$Gdl90TargetCopyWithImpl;
@useResult
$Res call({
 String id, String? callsign, double latitude, double longitude, double altitudeFeet, bool altitudeValid, double trackDegrees, double speedKnots, bool speedValid, double verticalSpeedFpm, bool verticalSpeedValid, DateTime lastUpdated, int emitterCategory
});




}
/// @nodoc
class _$Gdl90TargetCopyWithImpl<$Res>
    implements $Gdl90TargetCopyWith<$Res> {
  _$Gdl90TargetCopyWithImpl(this._self, this._then);

  final Gdl90Target _self;
  final $Res Function(Gdl90Target) _then;

/// Create a copy of Gdl90Target
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? callsign = freezed,Object? latitude = null,Object? longitude = null,Object? altitudeFeet = null,Object? altitudeValid = null,Object? trackDegrees = null,Object? speedKnots = null,Object? speedValid = null,Object? verticalSpeedFpm = null,Object? verticalSpeedValid = null,Object? lastUpdated = null,Object? emitterCategory = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,callsign: freezed == callsign ? _self.callsign : callsign // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,altitudeFeet: null == altitudeFeet ? _self.altitudeFeet : altitudeFeet // ignore: cast_nullable_to_non_nullable
as double,altitudeValid: null == altitudeValid ? _self.altitudeValid : altitudeValid // ignore: cast_nullable_to_non_nullable
as bool,trackDegrees: null == trackDegrees ? _self.trackDegrees : trackDegrees // ignore: cast_nullable_to_non_nullable
as double,speedKnots: null == speedKnots ? _self.speedKnots : speedKnots // ignore: cast_nullable_to_non_nullable
as double,speedValid: null == speedValid ? _self.speedValid : speedValid // ignore: cast_nullable_to_non_nullable
as bool,verticalSpeedFpm: null == verticalSpeedFpm ? _self.verticalSpeedFpm : verticalSpeedFpm // ignore: cast_nullable_to_non_nullable
as double,verticalSpeedValid: null == verticalSpeedValid ? _self.verticalSpeedValid : verticalSpeedValid // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,emitterCategory: null == emitterCategory ? _self.emitterCategory : emitterCategory // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Gdl90Target].
extension Gdl90TargetPatterns on Gdl90Target {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gdl90Target value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gdl90Target() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gdl90Target value)  $default,){
final _that = this;
switch (_that) {
case _Gdl90Target():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gdl90Target value)?  $default,){
final _that = this;
switch (_that) {
case _Gdl90Target() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? callsign,  double latitude,  double longitude,  double altitudeFeet,  bool altitudeValid,  double trackDegrees,  double speedKnots,  bool speedValid,  double verticalSpeedFpm,  bool verticalSpeedValid,  DateTime lastUpdated,  int emitterCategory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gdl90Target() when $default != null:
return $default(_that.id,_that.callsign,_that.latitude,_that.longitude,_that.altitudeFeet,_that.altitudeValid,_that.trackDegrees,_that.speedKnots,_that.speedValid,_that.verticalSpeedFpm,_that.verticalSpeedValid,_that.lastUpdated,_that.emitterCategory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? callsign,  double latitude,  double longitude,  double altitudeFeet,  bool altitudeValid,  double trackDegrees,  double speedKnots,  bool speedValid,  double verticalSpeedFpm,  bool verticalSpeedValid,  DateTime lastUpdated,  int emitterCategory)  $default,) {final _that = this;
switch (_that) {
case _Gdl90Target():
return $default(_that.id,_that.callsign,_that.latitude,_that.longitude,_that.altitudeFeet,_that.altitudeValid,_that.trackDegrees,_that.speedKnots,_that.speedValid,_that.verticalSpeedFpm,_that.verticalSpeedValid,_that.lastUpdated,_that.emitterCategory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? callsign,  double latitude,  double longitude,  double altitudeFeet,  bool altitudeValid,  double trackDegrees,  double speedKnots,  bool speedValid,  double verticalSpeedFpm,  bool verticalSpeedValid,  DateTime lastUpdated,  int emitterCategory)?  $default,) {final _that = this;
switch (_that) {
case _Gdl90Target() when $default != null:
return $default(_that.id,_that.callsign,_that.latitude,_that.longitude,_that.altitudeFeet,_that.altitudeValid,_that.trackDegrees,_that.speedKnots,_that.speedValid,_that.verticalSpeedFpm,_that.verticalSpeedValid,_that.lastUpdated,_that.emitterCategory);case _:
  return null;

}
}

}

/// @nodoc


class _Gdl90Target extends Gdl90Target {
  const _Gdl90Target({required this.id, this.callsign, required this.latitude, required this.longitude, required this.altitudeFeet, this.altitudeValid = true, required this.trackDegrees, required this.speedKnots, this.speedValid = true, required this.verticalSpeedFpm, this.verticalSpeedValid = true, required this.lastUpdated, this.emitterCategory = 0}): super._();
  

@override final  String id;
@override final  String? callsign;
@override final  double latitude;
@override final  double longitude;
@override final  double altitudeFeet;
@override@JsonKey() final  bool altitudeValid;
@override final  double trackDegrees;
@override final  double speedKnots;
@override@JsonKey() final  bool speedValid;
@override final  double verticalSpeedFpm;
@override@JsonKey() final  bool verticalSpeedValid;
@override final  DateTime lastUpdated;
@override@JsonKey() final  int emitterCategory;

/// Create a copy of Gdl90Target
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Gdl90TargetCopyWith<_Gdl90Target> get copyWith => __$Gdl90TargetCopyWithImpl<_Gdl90Target>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gdl90Target&&(identical(other.id, id) || other.id == id)&&(identical(other.callsign, callsign) || other.callsign == callsign)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.altitudeFeet, altitudeFeet) || other.altitudeFeet == altitudeFeet)&&(identical(other.altitudeValid, altitudeValid) || other.altitudeValid == altitudeValid)&&(identical(other.trackDegrees, trackDegrees) || other.trackDegrees == trackDegrees)&&(identical(other.speedKnots, speedKnots) || other.speedKnots == speedKnots)&&(identical(other.speedValid, speedValid) || other.speedValid == speedValid)&&(identical(other.verticalSpeedFpm, verticalSpeedFpm) || other.verticalSpeedFpm == verticalSpeedFpm)&&(identical(other.verticalSpeedValid, verticalSpeedValid) || other.verticalSpeedValid == verticalSpeedValid)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.emitterCategory, emitterCategory) || other.emitterCategory == emitterCategory));
}


@override
int get hashCode => Object.hash(runtimeType,id,callsign,latitude,longitude,altitudeFeet,altitudeValid,trackDegrees,speedKnots,speedValid,verticalSpeedFpm,verticalSpeedValid,lastUpdated,emitterCategory);

@override
String toString() {
  return 'Gdl90Target(id: $id, callsign: $callsign, latitude: $latitude, longitude: $longitude, altitudeFeet: $altitudeFeet, altitudeValid: $altitudeValid, trackDegrees: $trackDegrees, speedKnots: $speedKnots, speedValid: $speedValid, verticalSpeedFpm: $verticalSpeedFpm, verticalSpeedValid: $verticalSpeedValid, lastUpdated: $lastUpdated, emitterCategory: $emitterCategory)';
}


}

/// @nodoc
abstract mixin class _$Gdl90TargetCopyWith<$Res> implements $Gdl90TargetCopyWith<$Res> {
  factory _$Gdl90TargetCopyWith(_Gdl90Target value, $Res Function(_Gdl90Target) _then) = __$Gdl90TargetCopyWithImpl;
@override @useResult
$Res call({
 String id, String? callsign, double latitude, double longitude, double altitudeFeet, bool altitudeValid, double trackDegrees, double speedKnots, bool speedValid, double verticalSpeedFpm, bool verticalSpeedValid, DateTime lastUpdated, int emitterCategory
});




}
/// @nodoc
class __$Gdl90TargetCopyWithImpl<$Res>
    implements _$Gdl90TargetCopyWith<$Res> {
  __$Gdl90TargetCopyWithImpl(this._self, this._then);

  final _Gdl90Target _self;
  final $Res Function(_Gdl90Target) _then;

/// Create a copy of Gdl90Target
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? callsign = freezed,Object? latitude = null,Object? longitude = null,Object? altitudeFeet = null,Object? altitudeValid = null,Object? trackDegrees = null,Object? speedKnots = null,Object? speedValid = null,Object? verticalSpeedFpm = null,Object? verticalSpeedValid = null,Object? lastUpdated = null,Object? emitterCategory = null,}) {
  return _then(_Gdl90Target(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,callsign: freezed == callsign ? _self.callsign : callsign // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,altitudeFeet: null == altitudeFeet ? _self.altitudeFeet : altitudeFeet // ignore: cast_nullable_to_non_nullable
as double,altitudeValid: null == altitudeValid ? _self.altitudeValid : altitudeValid // ignore: cast_nullable_to_non_nullable
as bool,trackDegrees: null == trackDegrees ? _self.trackDegrees : trackDegrees // ignore: cast_nullable_to_non_nullable
as double,speedKnots: null == speedKnots ? _self.speedKnots : speedKnots // ignore: cast_nullable_to_non_nullable
as double,speedValid: null == speedValid ? _self.speedValid : speedValid // ignore: cast_nullable_to_non_nullable
as bool,verticalSpeedFpm: null == verticalSpeedFpm ? _self.verticalSpeedFpm : verticalSpeedFpm // ignore: cast_nullable_to_non_nullable
as double,verticalSpeedValid: null == verticalSpeedValid ? _self.verticalSpeedValid : verticalSpeedValid // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,emitterCategory: null == emitterCategory ? _self.emitterCategory : emitterCategory // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
