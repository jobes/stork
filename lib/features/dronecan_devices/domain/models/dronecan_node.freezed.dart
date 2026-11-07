// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dronecan_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DroneCanNode {

 int get nodeId; DroneCanNodeHealth get health; DroneCanNodeMode get mode; int get uptimeSec; DateTime get lastSeen; int get vendorSpecificStatusCode; String? get name; String? get uniqueId; int? get swMajor; int? get swMinor; int? get swOptionalFieldFlags; int? get swVcsCommit; String? get swImageCrc; int? get hwMajor; int? get hwMinor; String? get certificateOfAuthenticity;
/// Create a copy of DroneCanNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanNodeCopyWith<DroneCanNode> get copyWith => _$DroneCanNodeCopyWithImpl<DroneCanNode>(this as DroneCanNode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DroneCanNode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanNode&&(identical(other.nodeId, _this.nodeId) || other.nodeId == _this.nodeId)&&(identical(other.health, _this.health) || other.health == _this.health)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.uptimeSec, _this.uptimeSec) || other.uptimeSec == _this.uptimeSec)&&(identical(other.lastSeen, _this.lastSeen) || other.lastSeen == _this.lastSeen)&&(identical(other.vendorSpecificStatusCode, _this.vendorSpecificStatusCode) || other.vendorSpecificStatusCode == _this.vendorSpecificStatusCode)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.uniqueId, _this.uniqueId) || other.uniqueId == _this.uniqueId)&&(identical(other.swMajor, _this.swMajor) || other.swMajor == _this.swMajor)&&(identical(other.swMinor, _this.swMinor) || other.swMinor == _this.swMinor)&&(identical(other.swOptionalFieldFlags, _this.swOptionalFieldFlags) || other.swOptionalFieldFlags == _this.swOptionalFieldFlags)&&(identical(other.swVcsCommit, _this.swVcsCommit) || other.swVcsCommit == _this.swVcsCommit)&&(identical(other.swImageCrc, _this.swImageCrc) || other.swImageCrc == _this.swImageCrc)&&(identical(other.hwMajor, _this.hwMajor) || other.hwMajor == _this.hwMajor)&&(identical(other.hwMinor, _this.hwMinor) || other.hwMinor == _this.hwMinor)&&(identical(other.certificateOfAuthenticity, _this.certificateOfAuthenticity) || other.certificateOfAuthenticity == _this.certificateOfAuthenticity));
}


@override
int get hashCode {
  final _this = this as DroneCanNode;
  return Object.hash(runtimeType,_this.nodeId,_this.health,_this.mode,_this.uptimeSec,_this.lastSeen,_this.vendorSpecificStatusCode,_this.name,_this.uniqueId,_this.swMajor,_this.swMinor,_this.swOptionalFieldFlags,_this.swVcsCommit,_this.swImageCrc,_this.hwMajor,_this.hwMinor,_this.certificateOfAuthenticity);
}

@override
String toString() {
  final _this = this as DroneCanNode;
  return 'DroneCanNode(nodeId: ${_this.nodeId}, health: ${_this.health}, mode: ${_this.mode}, uptimeSec: ${_this.uptimeSec}, lastSeen: ${_this.lastSeen}, vendorSpecificStatusCode: ${_this.vendorSpecificStatusCode}, name: ${_this.name}, uniqueId: ${_this.uniqueId}, swMajor: ${_this.swMajor}, swMinor: ${_this.swMinor}, swOptionalFieldFlags: ${_this.swOptionalFieldFlags}, swVcsCommit: ${_this.swVcsCommit}, swImageCrc: ${_this.swImageCrc}, hwMajor: ${_this.hwMajor}, hwMinor: ${_this.hwMinor}, certificateOfAuthenticity: ${_this.certificateOfAuthenticity})';
}


}

/// @nodoc
abstract mixin class $DroneCanNodeCopyWith<$Res>  {
  factory $DroneCanNodeCopyWith(DroneCanNode value, $Res Function(DroneCanNode) _then) = _$DroneCanNodeCopyWithImpl;
@useResult
$Res call({
 int nodeId, DroneCanNodeHealth health, DroneCanNodeMode mode, int uptimeSec, DateTime lastSeen, int vendorSpecificStatusCode, String? name, String? uniqueId, int? swMajor, int? swMinor, int? swOptionalFieldFlags, int? swVcsCommit, String? swImageCrc, int? hwMajor, int? hwMinor, String? certificateOfAuthenticity
});




}
/// @nodoc
class _$DroneCanNodeCopyWithImpl<$Res>
    implements $DroneCanNodeCopyWith<$Res> {
  _$DroneCanNodeCopyWithImpl(this._self, this._then);

  final DroneCanNode _self;
  final $Res Function(DroneCanNode) _then;

/// Create a copy of DroneCanNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodeId = null,Object? health = null,Object? mode = null,Object? uptimeSec = null,Object? lastSeen = null,Object? vendorSpecificStatusCode = null,Object? name = freezed,Object? uniqueId = freezed,Object? swMajor = freezed,Object? swMinor = freezed,Object? swOptionalFieldFlags = freezed,Object? swVcsCommit = freezed,Object? swImageCrc = freezed,Object? hwMajor = freezed,Object? hwMinor = freezed,Object? certificateOfAuthenticity = freezed,}) {
  return _then(DroneCanNode(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as int,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as DroneCanNodeHealth,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as DroneCanNodeMode,uptimeSec: null == uptimeSec ? _self.uptimeSec : uptimeSec // ignore: cast_nullable_to_non_nullable
as int,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,vendorSpecificStatusCode: null == vendorSpecificStatusCode ? _self.vendorSpecificStatusCode : vendorSpecificStatusCode // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,uniqueId: freezed == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String?,swMajor: freezed == swMajor ? _self.swMajor : swMajor // ignore: cast_nullable_to_non_nullable
as int?,swMinor: freezed == swMinor ? _self.swMinor : swMinor // ignore: cast_nullable_to_non_nullable
as int?,swOptionalFieldFlags: freezed == swOptionalFieldFlags ? _self.swOptionalFieldFlags : swOptionalFieldFlags // ignore: cast_nullable_to_non_nullable
as int?,swVcsCommit: freezed == swVcsCommit ? _self.swVcsCommit : swVcsCommit // ignore: cast_nullable_to_non_nullable
as int?,swImageCrc: freezed == swImageCrc ? _self.swImageCrc : swImageCrc // ignore: cast_nullable_to_non_nullable
as String?,hwMajor: freezed == hwMajor ? _self.hwMajor : hwMajor // ignore: cast_nullable_to_non_nullable
as int?,hwMinor: freezed == hwMinor ? _self.hwMinor : hwMinor // ignore: cast_nullable_to_non_nullable
as int?,certificateOfAuthenticity: freezed == certificateOfAuthenticity ? _self.certificateOfAuthenticity : certificateOfAuthenticity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DroneCanNode].
extension DroneCanNodePatterns on DroneCanNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DroneCanNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DroneCanNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DroneCanNode value)  $default,){
final _that = this;
switch (_that) {
case _DroneCanNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DroneCanNode value)?  $default,){
final _that = this;
switch (_that) {
case _DroneCanNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int nodeId,  DroneCanNodeHealth health,  DroneCanNodeMode mode,  int uptimeSec,  DateTime lastSeen,  int vendorSpecificStatusCode,  String? name,  String? uniqueId,  int? swMajor,  int? swMinor,  int? swOptionalFieldFlags,  int? swVcsCommit,  String? swImageCrc,  int? hwMajor,  int? hwMinor,  String? certificateOfAuthenticity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DroneCanNode() when $default != null:
return $default(_that.nodeId,_that.health,_that.mode,_that.uptimeSec,_that.lastSeen,_that.vendorSpecificStatusCode,_that.name,_that.uniqueId,_that.swMajor,_that.swMinor,_that.swOptionalFieldFlags,_that.swVcsCommit,_that.swImageCrc,_that.hwMajor,_that.hwMinor,_that.certificateOfAuthenticity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int nodeId,  DroneCanNodeHealth health,  DroneCanNodeMode mode,  int uptimeSec,  DateTime lastSeen,  int vendorSpecificStatusCode,  String? name,  String? uniqueId,  int? swMajor,  int? swMinor,  int? swOptionalFieldFlags,  int? swVcsCommit,  String? swImageCrc,  int? hwMajor,  int? hwMinor,  String? certificateOfAuthenticity)  $default,) {final _that = this;
switch (_that) {
case _DroneCanNode():
return $default(_that.nodeId,_that.health,_that.mode,_that.uptimeSec,_that.lastSeen,_that.vendorSpecificStatusCode,_that.name,_that.uniqueId,_that.swMajor,_that.swMinor,_that.swOptionalFieldFlags,_that.swVcsCommit,_that.swImageCrc,_that.hwMajor,_that.hwMinor,_that.certificateOfAuthenticity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int nodeId,  DroneCanNodeHealth health,  DroneCanNodeMode mode,  int uptimeSec,  DateTime lastSeen,  int vendorSpecificStatusCode,  String? name,  String? uniqueId,  int? swMajor,  int? swMinor,  int? swOptionalFieldFlags,  int? swVcsCommit,  String? swImageCrc,  int? hwMajor,  int? hwMinor,  String? certificateOfAuthenticity)?  $default,) {final _that = this;
switch (_that) {
case _DroneCanNode() when $default != null:
return $default(_that.nodeId,_that.health,_that.mode,_that.uptimeSec,_that.lastSeen,_that.vendorSpecificStatusCode,_that.name,_that.uniqueId,_that.swMajor,_that.swMinor,_that.swOptionalFieldFlags,_that.swVcsCommit,_that.swImageCrc,_that.hwMajor,_that.hwMinor,_that.certificateOfAuthenticity);case _:
  return null;

}
}

}

/// @nodoc


class _DroneCanNode extends DroneCanNode {
  const _DroneCanNode({required this.nodeId, required this.health, required this.mode, required this.uptimeSec, required this.lastSeen, this.vendorSpecificStatusCode = 0, this.name, this.uniqueId, this.swMajor, this.swMinor, this.swOptionalFieldFlags, this.swVcsCommit, this.swImageCrc, this.hwMajor, this.hwMinor, this.certificateOfAuthenticity}): super._();
  

@override final  int nodeId;
@override final  DroneCanNodeHealth health;
@override final  DroneCanNodeMode mode;
@override final  int uptimeSec;
@override final  DateTime lastSeen;
@override@JsonKey() final  int vendorSpecificStatusCode;
@override final  String? name;
@override final  String? uniqueId;
@override final  int? swMajor;
@override final  int? swMinor;
@override final  int? swOptionalFieldFlags;
@override final  int? swVcsCommit;
@override final  String? swImageCrc;
@override final  int? hwMajor;
@override final  int? hwMinor;
@override final  String? certificateOfAuthenticity;

/// Create a copy of DroneCanNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DroneCanNodeCopyWith<_DroneCanNode> get copyWith => __$DroneCanNodeCopyWithImpl<_DroneCanNode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DroneCanNode&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.health, health) || other.health == health)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.uptimeSec, uptimeSec) || other.uptimeSec == uptimeSec)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.vendorSpecificStatusCode, vendorSpecificStatusCode) || other.vendorSpecificStatusCode == vendorSpecificStatusCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.swMajor, swMajor) || other.swMajor == swMajor)&&(identical(other.swMinor, swMinor) || other.swMinor == swMinor)&&(identical(other.swOptionalFieldFlags, swOptionalFieldFlags) || other.swOptionalFieldFlags == swOptionalFieldFlags)&&(identical(other.swVcsCommit, swVcsCommit) || other.swVcsCommit == swVcsCommit)&&(identical(other.swImageCrc, swImageCrc) || other.swImageCrc == swImageCrc)&&(identical(other.hwMajor, hwMajor) || other.hwMajor == hwMajor)&&(identical(other.hwMinor, hwMinor) || other.hwMinor == hwMinor)&&(identical(other.certificateOfAuthenticity, certificateOfAuthenticity) || other.certificateOfAuthenticity == certificateOfAuthenticity));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nodeId,health,mode,uptimeSec,lastSeen,vendorSpecificStatusCode,name,uniqueId,swMajor,swMinor,swOptionalFieldFlags,swVcsCommit,swImageCrc,hwMajor,hwMinor,certificateOfAuthenticity);
}

@override
String toString() {
    return 'DroneCanNode(nodeId: $nodeId, health: $health, mode: $mode, uptimeSec: $uptimeSec, lastSeen: $lastSeen, vendorSpecificStatusCode: $vendorSpecificStatusCode, name: $name, uniqueId: $uniqueId, swMajor: $swMajor, swMinor: $swMinor, swOptionalFieldFlags: $swOptionalFieldFlags, swVcsCommit: $swVcsCommit, swImageCrc: $swImageCrc, hwMajor: $hwMajor, hwMinor: $hwMinor, certificateOfAuthenticity: $certificateOfAuthenticity)';
}


}

/// @nodoc
abstract mixin class _$DroneCanNodeCopyWith<$Res> implements $DroneCanNodeCopyWith<$Res> {
  factory _$DroneCanNodeCopyWith(_DroneCanNode value, $Res Function(_DroneCanNode) _then) = __$DroneCanNodeCopyWithImpl;
@override @useResult
$Res call({
 int nodeId, DroneCanNodeHealth health, DroneCanNodeMode mode, int uptimeSec, DateTime lastSeen, int vendorSpecificStatusCode, String? name, String? uniqueId, int? swMajor, int? swMinor, int? swOptionalFieldFlags, int? swVcsCommit, String? swImageCrc, int? hwMajor, int? hwMinor, String? certificateOfAuthenticity
});




}
/// @nodoc
class __$DroneCanNodeCopyWithImpl<$Res>
    implements _$DroneCanNodeCopyWith<$Res> {
  __$DroneCanNodeCopyWithImpl(this._self, this._then);

  final _DroneCanNode _self;
  final $Res Function(_DroneCanNode) _then;

/// Create a copy of DroneCanNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodeId = null,Object? health = null,Object? mode = null,Object? uptimeSec = null,Object? lastSeen = null,Object? vendorSpecificStatusCode = null,Object? name = freezed,Object? uniqueId = freezed,Object? swMajor = freezed,Object? swMinor = freezed,Object? swOptionalFieldFlags = freezed,Object? swVcsCommit = freezed,Object? swImageCrc = freezed,Object? hwMajor = freezed,Object? hwMinor = freezed,Object? certificateOfAuthenticity = freezed,}) {
  return _then(_DroneCanNode(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as int,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as DroneCanNodeHealth,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as DroneCanNodeMode,uptimeSec: null == uptimeSec ? _self.uptimeSec : uptimeSec // ignore: cast_nullable_to_non_nullable
as int,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,vendorSpecificStatusCode: null == vendorSpecificStatusCode ? _self.vendorSpecificStatusCode : vendorSpecificStatusCode // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,uniqueId: freezed == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String?,swMajor: freezed == swMajor ? _self.swMajor : swMajor // ignore: cast_nullable_to_non_nullable
as int?,swMinor: freezed == swMinor ? _self.swMinor : swMinor // ignore: cast_nullable_to_non_nullable
as int?,swOptionalFieldFlags: freezed == swOptionalFieldFlags ? _self.swOptionalFieldFlags : swOptionalFieldFlags // ignore: cast_nullable_to_non_nullable
as int?,swVcsCommit: freezed == swVcsCommit ? _self.swVcsCommit : swVcsCommit // ignore: cast_nullable_to_non_nullable
as int?,swImageCrc: freezed == swImageCrc ? _self.swImageCrc : swImageCrc // ignore: cast_nullable_to_non_nullable
as String?,hwMajor: freezed == hwMajor ? _self.hwMajor : hwMajor // ignore: cast_nullable_to_non_nullable
as int?,hwMinor: freezed == hwMinor ? _self.hwMinor : hwMinor // ignore: cast_nullable_to_non_nullable
as int?,certificateOfAuthenticity: freezed == certificateOfAuthenticity ? _self.certificateOfAuthenticity : certificateOfAuthenticity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
