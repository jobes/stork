// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FavoritePoint {

 String get id; double get latitude; double get longitude; PoiType get icon; String get name; String get description;
/// Create a copy of FavoritePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoritePointCopyWith<FavoritePoint> get copyWith => _$FavoritePointCopyWithImpl<FavoritePoint>(this as FavoritePoint, _$identity);

  /// Serializes this FavoritePoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoritePoint&&(identical(other.id, id) || other.id == id)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,latitude,longitude,icon,name,description);

@override
String toString() {
  return 'FavoritePoint(id: $id, latitude: $latitude, longitude: $longitude, icon: $icon, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $FavoritePointCopyWith<$Res>  {
  factory $FavoritePointCopyWith(FavoritePoint value, $Res Function(FavoritePoint) _then) = _$FavoritePointCopyWithImpl;
@useResult
$Res call({
 String id, double latitude, double longitude, PoiType icon, String name, String description
});




}
/// @nodoc
class _$FavoritePointCopyWithImpl<$Res>
    implements $FavoritePointCopyWith<$Res> {
  _$FavoritePointCopyWithImpl(this._self, this._then);

  final FavoritePoint _self;
  final $Res Function(FavoritePoint) _then;

/// Create a copy of FavoritePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? latitude = null,Object? longitude = null,Object? icon = null,Object? name = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as PoiType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoritePoint].
extension FavoritePointPatterns on FavoritePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoritePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoritePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoritePoint value)  $default,){
final _that = this;
switch (_that) {
case _FavoritePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoritePoint value)?  $default,){
final _that = this;
switch (_that) {
case _FavoritePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double latitude,  double longitude,  PoiType icon,  String name,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoritePoint() when $default != null:
return $default(_that.id,_that.latitude,_that.longitude,_that.icon,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double latitude,  double longitude,  PoiType icon,  String name,  String description)  $default,) {final _that = this;
switch (_that) {
case _FavoritePoint():
return $default(_that.id,_that.latitude,_that.longitude,_that.icon,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double latitude,  double longitude,  PoiType icon,  String name,  String description)?  $default,) {final _that = this;
switch (_that) {
case _FavoritePoint() when $default != null:
return $default(_that.id,_that.latitude,_that.longitude,_that.icon,_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoritePoint implements FavoritePoint {
  const _FavoritePoint({required this.id, required this.latitude, required this.longitude, required this.icon, required this.name, this.description = ''});
  factory _FavoritePoint.fromJson(Map<String, dynamic> json) => _$FavoritePointFromJson(json);

@override final  String id;
@override final  double latitude;
@override final  double longitude;
@override final  PoiType icon;
@override final  String name;
@override@JsonKey() final  String description;

/// Create a copy of FavoritePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoritePointCopyWith<_FavoritePoint> get copyWith => __$FavoritePointCopyWithImpl<_FavoritePoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoritePointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoritePoint&&(identical(other.id, id) || other.id == id)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,latitude,longitude,icon,name,description);

@override
String toString() {
  return 'FavoritePoint(id: $id, latitude: $latitude, longitude: $longitude, icon: $icon, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$FavoritePointCopyWith<$Res> implements $FavoritePointCopyWith<$Res> {
  factory _$FavoritePointCopyWith(_FavoritePoint value, $Res Function(_FavoritePoint) _then) = __$FavoritePointCopyWithImpl;
@override @useResult
$Res call({
 String id, double latitude, double longitude, PoiType icon, String name, String description
});




}
/// @nodoc
class __$FavoritePointCopyWithImpl<$Res>
    implements _$FavoritePointCopyWith<$Res> {
  __$FavoritePointCopyWithImpl(this._self, this._then);

  final _FavoritePoint _self;
  final $Res Function(_FavoritePoint) _then;

/// Create a copy of FavoritePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? latitude = null,Object? longitude = null,Object? icon = null,Object? name = null,Object? description = null,}) {
  return _then(_FavoritePoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as PoiType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
