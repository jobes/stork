// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dronecan_parameter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DroneCanParamValue {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParamValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DroneCanParamValue()';
}


}

/// @nodoc
class $DroneCanParamValueCopyWith<$Res>  {
$DroneCanParamValueCopyWith(DroneCanParamValue _, $Res Function(DroneCanParamValue) __);
}


/// Adds pattern-matching-related methods to [DroneCanParamValue].
extension DroneCanParamValuePatterns on DroneCanParamValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DroneCanParamEmptyValue value)?  empty,TResult Function( DroneCanParamIntegerValue value)?  integer,TResult Function( DroneCanParamRealValue value)?  real,TResult Function( DroneCanParamBooleanValue value)?  boolean,TResult Function( DroneCanParamStringValue value)?  string,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DroneCanParamEmptyValue() when empty != null:
return empty(_that);case DroneCanParamIntegerValue() when integer != null:
return integer(_that);case DroneCanParamRealValue() when real != null:
return real(_that);case DroneCanParamBooleanValue() when boolean != null:
return boolean(_that);case DroneCanParamStringValue() when string != null:
return string(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DroneCanParamEmptyValue value)  empty,required TResult Function( DroneCanParamIntegerValue value)  integer,required TResult Function( DroneCanParamRealValue value)  real,required TResult Function( DroneCanParamBooleanValue value)  boolean,required TResult Function( DroneCanParamStringValue value)  string,}){
final _that = this;
switch (_that) {
case DroneCanParamEmptyValue():
return empty(_that);case DroneCanParamIntegerValue():
return integer(_that);case DroneCanParamRealValue():
return real(_that);case DroneCanParamBooleanValue():
return boolean(_that);case DroneCanParamStringValue():
return string(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DroneCanParamEmptyValue value)?  empty,TResult? Function( DroneCanParamIntegerValue value)?  integer,TResult? Function( DroneCanParamRealValue value)?  real,TResult? Function( DroneCanParamBooleanValue value)?  boolean,TResult? Function( DroneCanParamStringValue value)?  string,}){
final _that = this;
switch (_that) {
case DroneCanParamEmptyValue() when empty != null:
return empty(_that);case DroneCanParamIntegerValue() when integer != null:
return integer(_that);case DroneCanParamRealValue() when real != null:
return real(_that);case DroneCanParamBooleanValue() when boolean != null:
return boolean(_that);case DroneCanParamStringValue() when string != null:
return string(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  empty,TResult Function( int value)?  integer,TResult Function( double value)?  real,TResult Function( bool value)?  boolean,TResult Function( String value)?  string,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DroneCanParamEmptyValue() when empty != null:
return empty();case DroneCanParamIntegerValue() when integer != null:
return integer(_that.value);case DroneCanParamRealValue() when real != null:
return real(_that.value);case DroneCanParamBooleanValue() when boolean != null:
return boolean(_that.value);case DroneCanParamStringValue() when string != null:
return string(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  empty,required TResult Function( int value)  integer,required TResult Function( double value)  real,required TResult Function( bool value)  boolean,required TResult Function( String value)  string,}) {final _that = this;
switch (_that) {
case DroneCanParamEmptyValue():
return empty();case DroneCanParamIntegerValue():
return integer(_that.value);case DroneCanParamRealValue():
return real(_that.value);case DroneCanParamBooleanValue():
return boolean(_that.value);case DroneCanParamStringValue():
return string(_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  empty,TResult? Function( int value)?  integer,TResult? Function( double value)?  real,TResult? Function( bool value)?  boolean,TResult? Function( String value)?  string,}) {final _that = this;
switch (_that) {
case DroneCanParamEmptyValue() when empty != null:
return empty();case DroneCanParamIntegerValue() when integer != null:
return integer(_that.value);case DroneCanParamRealValue() when real != null:
return real(_that.value);case DroneCanParamBooleanValue() when boolean != null:
return boolean(_that.value);case DroneCanParamStringValue() when string != null:
return string(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class DroneCanParamEmptyValue extends DroneCanParamValue {
  const DroneCanParamEmptyValue(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParamEmptyValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DroneCanParamValue.empty()';
}


}




/// @nodoc


class DroneCanParamIntegerValue extends DroneCanParamValue {
  const DroneCanParamIntegerValue(this.value): super._();
  

 final  int value;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanParamIntegerValueCopyWith<DroneCanParamIntegerValue> get copyWith => _$DroneCanParamIntegerValueCopyWithImpl<DroneCanParamIntegerValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParamIntegerValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'DroneCanParamValue.integer(value: $value)';
}


}

/// @nodoc
abstract mixin class $DroneCanParamIntegerValueCopyWith<$Res> implements $DroneCanParamValueCopyWith<$Res> {
  factory $DroneCanParamIntegerValueCopyWith(DroneCanParamIntegerValue value, $Res Function(DroneCanParamIntegerValue) _then) = _$DroneCanParamIntegerValueCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$DroneCanParamIntegerValueCopyWithImpl<$Res>
    implements $DroneCanParamIntegerValueCopyWith<$Res> {
  _$DroneCanParamIntegerValueCopyWithImpl(this._self, this._then);

  final DroneCanParamIntegerValue _self;
  final $Res Function(DroneCanParamIntegerValue) _then;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DroneCanParamIntegerValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DroneCanParamRealValue extends DroneCanParamValue {
  const DroneCanParamRealValue(this.value): super._();
  

 final  double value;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanParamRealValueCopyWith<DroneCanParamRealValue> get copyWith => _$DroneCanParamRealValueCopyWithImpl<DroneCanParamRealValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParamRealValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'DroneCanParamValue.real(value: $value)';
}


}

/// @nodoc
abstract mixin class $DroneCanParamRealValueCopyWith<$Res> implements $DroneCanParamValueCopyWith<$Res> {
  factory $DroneCanParamRealValueCopyWith(DroneCanParamRealValue value, $Res Function(DroneCanParamRealValue) _then) = _$DroneCanParamRealValueCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class _$DroneCanParamRealValueCopyWithImpl<$Res>
    implements $DroneCanParamRealValueCopyWith<$Res> {
  _$DroneCanParamRealValueCopyWithImpl(this._self, this._then);

  final DroneCanParamRealValue _self;
  final $Res Function(DroneCanParamRealValue) _then;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DroneCanParamRealValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class DroneCanParamBooleanValue extends DroneCanParamValue {
  const DroneCanParamBooleanValue(this.value): super._();
  

 final  bool value;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanParamBooleanValueCopyWith<DroneCanParamBooleanValue> get copyWith => _$DroneCanParamBooleanValueCopyWithImpl<DroneCanParamBooleanValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParamBooleanValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'DroneCanParamValue.boolean(value: $value)';
}


}

/// @nodoc
abstract mixin class $DroneCanParamBooleanValueCopyWith<$Res> implements $DroneCanParamValueCopyWith<$Res> {
  factory $DroneCanParamBooleanValueCopyWith(DroneCanParamBooleanValue value, $Res Function(DroneCanParamBooleanValue) _then) = _$DroneCanParamBooleanValueCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$DroneCanParamBooleanValueCopyWithImpl<$Res>
    implements $DroneCanParamBooleanValueCopyWith<$Res> {
  _$DroneCanParamBooleanValueCopyWithImpl(this._self, this._then);

  final DroneCanParamBooleanValue _self;
  final $Res Function(DroneCanParamBooleanValue) _then;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DroneCanParamBooleanValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class DroneCanParamStringValue extends DroneCanParamValue {
  const DroneCanParamStringValue(this.value): super._();
  

 final  String value;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanParamStringValueCopyWith<DroneCanParamStringValue> get copyWith => _$DroneCanParamStringValueCopyWithImpl<DroneCanParamStringValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParamStringValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'DroneCanParamValue.string(value: $value)';
}


}

/// @nodoc
abstract mixin class $DroneCanParamStringValueCopyWith<$Res> implements $DroneCanParamValueCopyWith<$Res> {
  factory $DroneCanParamStringValueCopyWith(DroneCanParamStringValue value, $Res Function(DroneCanParamStringValue) _then) = _$DroneCanParamStringValueCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$DroneCanParamStringValueCopyWithImpl<$Res>
    implements $DroneCanParamStringValueCopyWith<$Res> {
  _$DroneCanParamStringValueCopyWithImpl(this._self, this._then);

  final DroneCanParamStringValue _self;
  final $Res Function(DroneCanParamStringValue) _then;

/// Create a copy of DroneCanParamValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DroneCanParamStringValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DroneCanParameter {

 int get index; String get name; DroneCanParamValue get value; DroneCanParamValue? get defaultValue; num? get minValue; num? get maxValue;
/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroneCanParameterCopyWith<DroneCanParameter> get copyWith => _$DroneCanParameterCopyWithImpl<DroneCanParameter>(this as DroneCanParameter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DroneCanParameter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DroneCanParameter&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.defaultValue, _this.defaultValue) || other.defaultValue == _this.defaultValue)&&(identical(other.minValue, _this.minValue) || other.minValue == _this.minValue)&&(identical(other.maxValue, _this.maxValue) || other.maxValue == _this.maxValue));
}


@override
int get hashCode {
  final _this = this as DroneCanParameter;
  return Object.hash(runtimeType,_this.index,_this.name,_this.value,_this.defaultValue,_this.minValue,_this.maxValue);
}

@override
String toString() {
  final _this = this as DroneCanParameter;
  return 'DroneCanParameter(index: ${_this.index}, name: ${_this.name}, value: ${_this.value}, defaultValue: ${_this.defaultValue}, minValue: ${_this.minValue}, maxValue: ${_this.maxValue})';
}


}

/// @nodoc
abstract mixin class $DroneCanParameterCopyWith<$Res>  {
  factory $DroneCanParameterCopyWith(DroneCanParameter value, $Res Function(DroneCanParameter) _then) = _$DroneCanParameterCopyWithImpl;
@useResult
$Res call({
 int index, String name, DroneCanParamValue value, DroneCanParamValue? defaultValue, num? minValue, num? maxValue
});


$DroneCanParamValueCopyWith<$Res> get value;$DroneCanParamValueCopyWith<$Res>? get defaultValue;

}
/// @nodoc
class _$DroneCanParameterCopyWithImpl<$Res>
    implements $DroneCanParameterCopyWith<$Res> {
  _$DroneCanParameterCopyWithImpl(this._self, this._then);

  final DroneCanParameter _self;
  final $Res Function(DroneCanParameter) _then;

/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? name = null,Object? value = null,Object? defaultValue = freezed,Object? minValue = freezed,Object? maxValue = freezed,}) {
  return _then(DroneCanParameter(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DroneCanParamValue,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as DroneCanParamValue?,minValue: freezed == minValue ? _self.minValue : minValue // ignore: cast_nullable_to_non_nullable
as num?,maxValue: freezed == maxValue ? _self.maxValue : maxValue // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}
/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DroneCanParamValueCopyWith<$Res> get value {
  
  return $DroneCanParamValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DroneCanParamValueCopyWith<$Res>? get defaultValue {
    if (_self.defaultValue == null) {
    return null;
  }

  return $DroneCanParamValueCopyWith<$Res>(_self.defaultValue!, (value) {
    return _then(_self.copyWith(defaultValue: value));
  });
}
}


/// Adds pattern-matching-related methods to [DroneCanParameter].
extension DroneCanParameterPatterns on DroneCanParameter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DroneCanParameter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DroneCanParameter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DroneCanParameter value)  $default,){
final _that = this;
switch (_that) {
case _DroneCanParameter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DroneCanParameter value)?  $default,){
final _that = this;
switch (_that) {
case _DroneCanParameter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String name,  DroneCanParamValue value,  DroneCanParamValue? defaultValue,  num? minValue,  num? maxValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DroneCanParameter() when $default != null:
return $default(_that.index,_that.name,_that.value,_that.defaultValue,_that.minValue,_that.maxValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String name,  DroneCanParamValue value,  DroneCanParamValue? defaultValue,  num? minValue,  num? maxValue)  $default,) {final _that = this;
switch (_that) {
case _DroneCanParameter():
return $default(_that.index,_that.name,_that.value,_that.defaultValue,_that.minValue,_that.maxValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String name,  DroneCanParamValue value,  DroneCanParamValue? defaultValue,  num? minValue,  num? maxValue)?  $default,) {final _that = this;
switch (_that) {
case _DroneCanParameter() when $default != null:
return $default(_that.index,_that.name,_that.value,_that.defaultValue,_that.minValue,_that.maxValue);case _:
  return null;

}
}

}

/// @nodoc


class _DroneCanParameter extends DroneCanParameter {
  const _DroneCanParameter({required this.index, required this.name, required this.value, this.defaultValue, this.minValue, this.maxValue}): super._();
  

@override final  int index;
@override final  String name;
@override final  DroneCanParamValue value;
@override final  DroneCanParamValue? defaultValue;
@override final  num? minValue;
@override final  num? maxValue;

/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DroneCanParameterCopyWith<_DroneCanParameter> get copyWith => __$DroneCanParameterCopyWithImpl<_DroneCanParameter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DroneCanParameter&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.value, value) || other.value == value)&&(identical(other.defaultValue, defaultValue) || other.defaultValue == defaultValue)&&(identical(other.minValue, minValue) || other.minValue == minValue)&&(identical(other.maxValue, maxValue) || other.maxValue == maxValue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,index,name,value,defaultValue,minValue,maxValue);
}

@override
String toString() {
    return 'DroneCanParameter(index: $index, name: $name, value: $value, defaultValue: $defaultValue, minValue: $minValue, maxValue: $maxValue)';
}


}

/// @nodoc
abstract mixin class _$DroneCanParameterCopyWith<$Res> implements $DroneCanParameterCopyWith<$Res> {
  factory _$DroneCanParameterCopyWith(_DroneCanParameter value, $Res Function(_DroneCanParameter) _then) = __$DroneCanParameterCopyWithImpl;
@override @useResult
$Res call({
 int index, String name, DroneCanParamValue value, DroneCanParamValue? defaultValue, num? minValue, num? maxValue
});


@override $DroneCanParamValueCopyWith<$Res> get value;@override $DroneCanParamValueCopyWith<$Res>? get defaultValue;

}
/// @nodoc
class __$DroneCanParameterCopyWithImpl<$Res>
    implements _$DroneCanParameterCopyWith<$Res> {
  __$DroneCanParameterCopyWithImpl(this._self, this._then);

  final _DroneCanParameter _self;
  final $Res Function(_DroneCanParameter) _then;

/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? name = null,Object? value = null,Object? defaultValue = freezed,Object? minValue = freezed,Object? maxValue = freezed,}) {
  return _then(_DroneCanParameter(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DroneCanParamValue,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue // ignore: cast_nullable_to_non_nullable
as DroneCanParamValue?,minValue: freezed == minValue ? _self.minValue : minValue // ignore: cast_nullable_to_non_nullable
as num?,maxValue: freezed == maxValue ? _self.maxValue : maxValue // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DroneCanParamValueCopyWith<$Res> get value {
  
  return $DroneCanParamValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}/// Create a copy of DroneCanParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DroneCanParamValueCopyWith<$Res>? get defaultValue {
    if (_self.defaultValue == null) {
    return null;
  }

  return $DroneCanParamValueCopyWith<$Res>(_self.defaultValue!, (value) {
    return _then(_self.copyWith(defaultValue: value));
  });
}
}

// dart format on
