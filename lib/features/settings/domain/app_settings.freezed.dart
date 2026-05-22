// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 double get mapFontSize; double get mapDefaultZoom; double get mapOverviewZoom; double get mapFollowZoom; RangeThresholds get flightSpeedThresholds; double get flightSpeedMaxRange; bool get autoSelectDevice; CannelloniDevice? get selectedDevice;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.mapFontSize, mapFontSize) || other.mapFontSize == mapFontSize)&&(identical(other.mapDefaultZoom, mapDefaultZoom) || other.mapDefaultZoom == mapDefaultZoom)&&(identical(other.mapOverviewZoom, mapOverviewZoom) || other.mapOverviewZoom == mapOverviewZoom)&&(identical(other.mapFollowZoom, mapFollowZoom) || other.mapFollowZoom == mapFollowZoom)&&(identical(other.flightSpeedThresholds, flightSpeedThresholds) || other.flightSpeedThresholds == flightSpeedThresholds)&&(identical(other.flightSpeedMaxRange, flightSpeedMaxRange) || other.flightSpeedMaxRange == flightSpeedMaxRange)&&(identical(other.autoSelectDevice, autoSelectDevice) || other.autoSelectDevice == autoSelectDevice)&&(identical(other.selectedDevice, selectedDevice) || other.selectedDevice == selectedDevice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mapFontSize,mapDefaultZoom,mapOverviewZoom,mapFollowZoom,flightSpeedThresholds,flightSpeedMaxRange,autoSelectDevice,selectedDevice);

@override
String toString() {
  return 'AppSettings(mapFontSize: $mapFontSize, mapDefaultZoom: $mapDefaultZoom, mapOverviewZoom: $mapOverviewZoom, mapFollowZoom: $mapFollowZoom, flightSpeedThresholds: $flightSpeedThresholds, flightSpeedMaxRange: $flightSpeedMaxRange, autoSelectDevice: $autoSelectDevice, selectedDevice: $selectedDevice)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 double mapFontSize, double mapDefaultZoom, double mapOverviewZoom, double mapFollowZoom, RangeThresholds flightSpeedThresholds, double flightSpeedMaxRange, bool autoSelectDevice, CannelloniDevice? selectedDevice
});


$RangeThresholdsCopyWith<$Res> get flightSpeedThresholds;$CannelloniDeviceCopyWith<$Res>? get selectedDevice;

}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mapFontSize = null,Object? mapDefaultZoom = null,Object? mapOverviewZoom = null,Object? mapFollowZoom = null,Object? flightSpeedThresholds = null,Object? flightSpeedMaxRange = null,Object? autoSelectDevice = null,Object? selectedDevice = freezed,}) {
  return _then(_self.copyWith(
mapFontSize: null == mapFontSize ? _self.mapFontSize : mapFontSize // ignore: cast_nullable_to_non_nullable
as double,mapDefaultZoom: null == mapDefaultZoom ? _self.mapDefaultZoom : mapDefaultZoom // ignore: cast_nullable_to_non_nullable
as double,mapOverviewZoom: null == mapOverviewZoom ? _self.mapOverviewZoom : mapOverviewZoom // ignore: cast_nullable_to_non_nullable
as double,mapFollowZoom: null == mapFollowZoom ? _self.mapFollowZoom : mapFollowZoom // ignore: cast_nullable_to_non_nullable
as double,flightSpeedThresholds: null == flightSpeedThresholds ? _self.flightSpeedThresholds : flightSpeedThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,flightSpeedMaxRange: null == flightSpeedMaxRange ? _self.flightSpeedMaxRange : flightSpeedMaxRange // ignore: cast_nullable_to_non_nullable
as double,autoSelectDevice: null == autoSelectDevice ? _self.autoSelectDevice : autoSelectDevice // ignore: cast_nullable_to_non_nullable
as bool,selectedDevice: freezed == selectedDevice ? _self.selectedDevice : selectedDevice // ignore: cast_nullable_to_non_nullable
as CannelloniDevice?,
  ));
}
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get flightSpeedThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.flightSpeedThresholds, (value) {
    return _then(_self.copyWith(flightSpeedThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CannelloniDeviceCopyWith<$Res>? get selectedDevice {
    if (_self.selectedDevice == null) {
    return null;
  }

  return $CannelloniDeviceCopyWith<$Res>(_self.selectedDevice!, (value) {
    return _then(_self.copyWith(selectedDevice: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double mapFontSize,  double mapDefaultZoom,  double mapOverviewZoom,  double mapFollowZoom,  RangeThresholds flightSpeedThresholds,  double flightSpeedMaxRange,  bool autoSelectDevice,  CannelloniDevice? selectedDevice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.mapFontSize,_that.mapDefaultZoom,_that.mapOverviewZoom,_that.mapFollowZoom,_that.flightSpeedThresholds,_that.flightSpeedMaxRange,_that.autoSelectDevice,_that.selectedDevice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double mapFontSize,  double mapDefaultZoom,  double mapOverviewZoom,  double mapFollowZoom,  RangeThresholds flightSpeedThresholds,  double flightSpeedMaxRange,  bool autoSelectDevice,  CannelloniDevice? selectedDevice)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.mapFontSize,_that.mapDefaultZoom,_that.mapOverviewZoom,_that.mapFollowZoom,_that.flightSpeedThresholds,_that.flightSpeedMaxRange,_that.autoSelectDevice,_that.selectedDevice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double mapFontSize,  double mapDefaultZoom,  double mapOverviewZoom,  double mapFollowZoom,  RangeThresholds flightSpeedThresholds,  double flightSpeedMaxRange,  bool autoSelectDevice,  CannelloniDevice? selectedDevice)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.mapFontSize,_that.mapDefaultZoom,_that.mapOverviewZoom,_that.mapFollowZoom,_that.flightSpeedThresholds,_that.flightSpeedMaxRange,_that.autoSelectDevice,_that.selectedDevice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings implements AppSettings {
  const _AppSettings({this.mapFontSize = 1.0, this.mapDefaultZoom = 6.0, this.mapOverviewZoom = 10.0, this.mapFollowZoom = 12.0, this.flightSpeedThresholds = const RangeThresholds(inactiveMax: 10.0, minError: 60.0, minWarning: 75.0, maxWarning: 110.0, maxError: 125.0), this.flightSpeedMaxRange = 140.0, this.autoSelectDevice = true, this.selectedDevice});
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  double mapFontSize;
@override@JsonKey() final  double mapDefaultZoom;
@override@JsonKey() final  double mapOverviewZoom;
@override@JsonKey() final  double mapFollowZoom;
@override@JsonKey() final  RangeThresholds flightSpeedThresholds;
@override@JsonKey() final  double flightSpeedMaxRange;
@override@JsonKey() final  bool autoSelectDevice;
@override final  CannelloniDevice? selectedDevice;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.mapFontSize, mapFontSize) || other.mapFontSize == mapFontSize)&&(identical(other.mapDefaultZoom, mapDefaultZoom) || other.mapDefaultZoom == mapDefaultZoom)&&(identical(other.mapOverviewZoom, mapOverviewZoom) || other.mapOverviewZoom == mapOverviewZoom)&&(identical(other.mapFollowZoom, mapFollowZoom) || other.mapFollowZoom == mapFollowZoom)&&(identical(other.flightSpeedThresholds, flightSpeedThresholds) || other.flightSpeedThresholds == flightSpeedThresholds)&&(identical(other.flightSpeedMaxRange, flightSpeedMaxRange) || other.flightSpeedMaxRange == flightSpeedMaxRange)&&(identical(other.autoSelectDevice, autoSelectDevice) || other.autoSelectDevice == autoSelectDevice)&&(identical(other.selectedDevice, selectedDevice) || other.selectedDevice == selectedDevice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mapFontSize,mapDefaultZoom,mapOverviewZoom,mapFollowZoom,flightSpeedThresholds,flightSpeedMaxRange,autoSelectDevice,selectedDevice);

@override
String toString() {
  return 'AppSettings(mapFontSize: $mapFontSize, mapDefaultZoom: $mapDefaultZoom, mapOverviewZoom: $mapOverviewZoom, mapFollowZoom: $mapFollowZoom, flightSpeedThresholds: $flightSpeedThresholds, flightSpeedMaxRange: $flightSpeedMaxRange, autoSelectDevice: $autoSelectDevice, selectedDevice: $selectedDevice)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 double mapFontSize, double mapDefaultZoom, double mapOverviewZoom, double mapFollowZoom, RangeThresholds flightSpeedThresholds, double flightSpeedMaxRange, bool autoSelectDevice, CannelloniDevice? selectedDevice
});


@override $RangeThresholdsCopyWith<$Res> get flightSpeedThresholds;@override $CannelloniDeviceCopyWith<$Res>? get selectedDevice;

}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mapFontSize = null,Object? mapDefaultZoom = null,Object? mapOverviewZoom = null,Object? mapFollowZoom = null,Object? flightSpeedThresholds = null,Object? flightSpeedMaxRange = null,Object? autoSelectDevice = null,Object? selectedDevice = freezed,}) {
  return _then(_AppSettings(
mapFontSize: null == mapFontSize ? _self.mapFontSize : mapFontSize // ignore: cast_nullable_to_non_nullable
as double,mapDefaultZoom: null == mapDefaultZoom ? _self.mapDefaultZoom : mapDefaultZoom // ignore: cast_nullable_to_non_nullable
as double,mapOverviewZoom: null == mapOverviewZoom ? _self.mapOverviewZoom : mapOverviewZoom // ignore: cast_nullable_to_non_nullable
as double,mapFollowZoom: null == mapFollowZoom ? _self.mapFollowZoom : mapFollowZoom // ignore: cast_nullable_to_non_nullable
as double,flightSpeedThresholds: null == flightSpeedThresholds ? _self.flightSpeedThresholds : flightSpeedThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,flightSpeedMaxRange: null == flightSpeedMaxRange ? _self.flightSpeedMaxRange : flightSpeedMaxRange // ignore: cast_nullable_to_non_nullable
as double,autoSelectDevice: null == autoSelectDevice ? _self.autoSelectDevice : autoSelectDevice // ignore: cast_nullable_to_non_nullable
as bool,selectedDevice: freezed == selectedDevice ? _self.selectedDevice : selectedDevice // ignore: cast_nullable_to_non_nullable
as CannelloniDevice?,
  ));
}

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get flightSpeedThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.flightSpeedThresholds, (value) {
    return _then(_self.copyWith(flightSpeedThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CannelloniDeviceCopyWith<$Res>? get selectedDevice {
    if (_self.selectedDevice == null) {
    return null;
  }

  return $CannelloniDeviceCopyWith<$Res>(_self.selectedDevice!, (value) {
    return _then(_self.copyWith(selectedDevice: value));
  });
}
}

// dart format on
