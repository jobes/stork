// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'widget_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WidgetPosition {

 double get top; double get left;
/// Create a copy of WidgetPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WidgetPositionCopyWith<WidgetPosition> get copyWith => _$WidgetPositionCopyWithImpl<WidgetPosition>(this as WidgetPosition, _$identity);

  /// Serializes this WidgetPosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WidgetPosition&&(identical(other.top, top) || other.top == top)&&(identical(other.left, left) || other.left == left));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,left);

@override
String toString() {
  return 'WidgetPosition(top: $top, left: $left)';
}


}

/// @nodoc
abstract mixin class $WidgetPositionCopyWith<$Res>  {
  factory $WidgetPositionCopyWith(WidgetPosition value, $Res Function(WidgetPosition) _then) = _$WidgetPositionCopyWithImpl;
@useResult
$Res call({
 double top, double left
});




}
/// @nodoc
class _$WidgetPositionCopyWithImpl<$Res>
    implements $WidgetPositionCopyWith<$Res> {
  _$WidgetPositionCopyWithImpl(this._self, this._then);

  final WidgetPosition _self;
  final $Res Function(WidgetPosition) _then;

/// Create a copy of WidgetPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = null,Object? left = null,}) {
  return _then(_self.copyWith(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WidgetPosition].
extension WidgetPositionPatterns on WidgetPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WidgetPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WidgetPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WidgetPosition value)  $default,){
final _that = this;
switch (_that) {
case _WidgetPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WidgetPosition value)?  $default,){
final _that = this;
switch (_that) {
case _WidgetPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double top,  double left)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WidgetPosition() when $default != null:
return $default(_that.top,_that.left);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double top,  double left)  $default,) {final _that = this;
switch (_that) {
case _WidgetPosition():
return $default(_that.top,_that.left);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double top,  double left)?  $default,) {final _that = this;
switch (_that) {
case _WidgetPosition() when $default != null:
return $default(_that.top,_that.left);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WidgetPosition implements WidgetPosition {
  const _WidgetPosition({required this.top, required this.left});
  factory _WidgetPosition.fromJson(Map<String, dynamic> json) => _$WidgetPositionFromJson(json);

@override final  double top;
@override final  double left;

/// Create a copy of WidgetPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WidgetPositionCopyWith<_WidgetPosition> get copyWith => __$WidgetPositionCopyWithImpl<_WidgetPosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WidgetPositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WidgetPosition&&(identical(other.top, top) || other.top == top)&&(identical(other.left, left) || other.left == left));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,left);

@override
String toString() {
  return 'WidgetPosition(top: $top, left: $left)';
}


}

/// @nodoc
abstract mixin class _$WidgetPositionCopyWith<$Res> implements $WidgetPositionCopyWith<$Res> {
  factory _$WidgetPositionCopyWith(_WidgetPosition value, $Res Function(_WidgetPosition) _then) = __$WidgetPositionCopyWithImpl;
@override @useResult
$Res call({
 double top, double left
});




}
/// @nodoc
class __$WidgetPositionCopyWithImpl<$Res>
    implements _$WidgetPositionCopyWith<$Res> {
  __$WidgetPositionCopyWithImpl(this._self, this._then);

  final _WidgetPosition _self;
  final $Res Function(_WidgetPosition) _then;

/// Create a copy of WidgetPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = null,Object? left = null,}) {
  return _then(_WidgetPosition(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
