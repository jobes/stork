// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cannelloni_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CannelloniDevice {

 String get name; String get hostname; String get ip; int get port;
/// Create a copy of CannelloniDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CannelloniDeviceCopyWith<CannelloniDevice> get copyWith => _$CannelloniDeviceCopyWithImpl<CannelloniDevice>(this as CannelloniDevice, _$identity);

  /// Serializes this CannelloniDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CannelloniDevice&&(identical(other.name, name) || other.name == name)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.port, port) || other.port == port));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,hostname,ip,port);

@override
String toString() {
  return 'CannelloniDevice(name: $name, hostname: $hostname, ip: $ip, port: $port)';
}


}

/// @nodoc
abstract mixin class $CannelloniDeviceCopyWith<$Res>  {
  factory $CannelloniDeviceCopyWith(CannelloniDevice value, $Res Function(CannelloniDevice) _then) = _$CannelloniDeviceCopyWithImpl;
@useResult
$Res call({
 String name, String hostname, String ip, int port
});




}
/// @nodoc
class _$CannelloniDeviceCopyWithImpl<$Res>
    implements $CannelloniDeviceCopyWith<$Res> {
  _$CannelloniDeviceCopyWithImpl(this._self, this._then);

  final CannelloniDevice _self;
  final $Res Function(CannelloniDevice) _then;

/// Create a copy of CannelloniDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? hostname = null,Object? ip = null,Object? port = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CannelloniDevice].
extension CannelloniDevicePatterns on CannelloniDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CannelloniDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CannelloniDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CannelloniDevice value)  $default,){
final _that = this;
switch (_that) {
case _CannelloniDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CannelloniDevice value)?  $default,){
final _that = this;
switch (_that) {
case _CannelloniDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String hostname,  String ip,  int port)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CannelloniDevice() when $default != null:
return $default(_that.name,_that.hostname,_that.ip,_that.port);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String hostname,  String ip,  int port)  $default,) {final _that = this;
switch (_that) {
case _CannelloniDevice():
return $default(_that.name,_that.hostname,_that.ip,_that.port);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String hostname,  String ip,  int port)?  $default,) {final _that = this;
switch (_that) {
case _CannelloniDevice() when $default != null:
return $default(_that.name,_that.hostname,_that.ip,_that.port);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CannelloniDevice implements CannelloniDevice {
  const _CannelloniDevice({required this.name, required this.hostname, required this.ip, required this.port});
  factory _CannelloniDevice.fromJson(Map<String, dynamic> json) => _$CannelloniDeviceFromJson(json);

@override final  String name;
@override final  String hostname;
@override final  String ip;
@override final  int port;

/// Create a copy of CannelloniDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CannelloniDeviceCopyWith<_CannelloniDevice> get copyWith => __$CannelloniDeviceCopyWithImpl<_CannelloniDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CannelloniDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CannelloniDevice&&(identical(other.name, name) || other.name == name)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.ip, ip) || other.ip == ip)&&(identical(other.port, port) || other.port == port));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,hostname,ip,port);

@override
String toString() {
  return 'CannelloniDevice(name: $name, hostname: $hostname, ip: $ip, port: $port)';
}


}

/// @nodoc
abstract mixin class _$CannelloniDeviceCopyWith<$Res> implements $CannelloniDeviceCopyWith<$Res> {
  factory _$CannelloniDeviceCopyWith(_CannelloniDevice value, $Res Function(_CannelloniDevice) _then) = __$CannelloniDeviceCopyWithImpl;
@override @useResult
$Res call({
 String name, String hostname, String ip, int port
});




}
/// @nodoc
class __$CannelloniDeviceCopyWithImpl<$Res>
    implements _$CannelloniDeviceCopyWith<$Res> {
  __$CannelloniDeviceCopyWithImpl(this._self, this._then);

  final _CannelloniDevice _self;
  final $Res Function(_CannelloniDevice) _then;

/// Create a copy of CannelloniDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? hostname = null,Object? ip = null,Object? port = null,}) {
  return _then(_CannelloniDevice(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,ip: null == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
