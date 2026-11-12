// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 double get mapFontSize; bool get showUtcClock; int get sunsetWarningMinutes; double get mapDefaultZoom; double get mapOverviewZoom; double get mapFollowZoom; double get mapFollowPitch; RangeThresholds get flightSpeedThresholds; double get flightSpeedMaxRange; int get courseLineSegmentsCount; int get courseLineSegmentDuration; bool get autoSelectDevice; CannelloniDevice? get selectedDevice; bool get areWidgetsDraggable; Map<String, WidgetPosition> get widgetPositions; SpeedUnit get speedUnit; double get qnh; double get qfe; bool get autoQnh; AltitudeUnit get altitudeUnit; AltitudeUnit get heightUnit; double get averageSpeed; String? get pilotId; String? get airplaneId; TemperatureUnit get temperatureUnit; RangeThresholds get oilTempThresholds; double get oilTempMaxRange; PressureUnit get pressureUnit; RangeThresholds get oilPressureThresholds; double get oilPressureMaxRange; RangeThresholds get fuelThresholds; RangeThresholds get egtThresholds; double get egtMaxRange; RangeThresholds get chtThresholds; double get chtMaxRange; RangeThresholds get rpmThresholds; double get rpmMaxRange; bool get trafficFilterMaxHorizontalDistanceEnabled; double get trafficMaxHorizontalDistance; bool get trafficFilterMaxVerticalDistanceEnabled; double get trafficMaxVerticalDistance; bool get casEnabled; double get casLookaheadTime; double get casHorizontalThreshold; double get casVerticalThreshold; bool get gdl90Enabled; String get gdl90BindIp; int get gdl90UdpPort; int get gdl90TargetExpirySeconds; bool get ognEnabled; bool get pureTrackEnabled; Set<String> get hiddenAircraftIds;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.mapFontSize, _this.mapFontSize) || other.mapFontSize == _this.mapFontSize)&&(identical(other.showUtcClock, _this.showUtcClock) || other.showUtcClock == _this.showUtcClock)&&(identical(other.sunsetWarningMinutes, _this.sunsetWarningMinutes) || other.sunsetWarningMinutes == _this.sunsetWarningMinutes)&&(identical(other.mapDefaultZoom, _this.mapDefaultZoom) || other.mapDefaultZoom == _this.mapDefaultZoom)&&(identical(other.mapOverviewZoom, _this.mapOverviewZoom) || other.mapOverviewZoom == _this.mapOverviewZoom)&&(identical(other.mapFollowZoom, _this.mapFollowZoom) || other.mapFollowZoom == _this.mapFollowZoom)&&(identical(other.mapFollowPitch, _this.mapFollowPitch) || other.mapFollowPitch == _this.mapFollowPitch)&&(identical(other.flightSpeedThresholds, _this.flightSpeedThresholds) || other.flightSpeedThresholds == _this.flightSpeedThresholds)&&(identical(other.flightSpeedMaxRange, _this.flightSpeedMaxRange) || other.flightSpeedMaxRange == _this.flightSpeedMaxRange)&&(identical(other.courseLineSegmentsCount, _this.courseLineSegmentsCount) || other.courseLineSegmentsCount == _this.courseLineSegmentsCount)&&(identical(other.courseLineSegmentDuration, _this.courseLineSegmentDuration) || other.courseLineSegmentDuration == _this.courseLineSegmentDuration)&&(identical(other.autoSelectDevice, _this.autoSelectDevice) || other.autoSelectDevice == _this.autoSelectDevice)&&(identical(other.selectedDevice, _this.selectedDevice) || other.selectedDevice == _this.selectedDevice)&&(identical(other.areWidgetsDraggable, _this.areWidgetsDraggable) || other.areWidgetsDraggable == _this.areWidgetsDraggable)&&const DeepCollectionEquality().equals(other.widgetPositions, _this.widgetPositions)&&(identical(other.speedUnit, _this.speedUnit) || other.speedUnit == _this.speedUnit)&&(identical(other.qnh, _this.qnh) || other.qnh == _this.qnh)&&(identical(other.qfe, _this.qfe) || other.qfe == _this.qfe)&&(identical(other.autoQnh, _this.autoQnh) || other.autoQnh == _this.autoQnh)&&(identical(other.altitudeUnit, _this.altitudeUnit) || other.altitudeUnit == _this.altitudeUnit)&&(identical(other.heightUnit, _this.heightUnit) || other.heightUnit == _this.heightUnit)&&(identical(other.averageSpeed, _this.averageSpeed) || other.averageSpeed == _this.averageSpeed)&&(identical(other.pilotId, _this.pilotId) || other.pilotId == _this.pilotId)&&(identical(other.airplaneId, _this.airplaneId) || other.airplaneId == _this.airplaneId)&&(identical(other.temperatureUnit, _this.temperatureUnit) || other.temperatureUnit == _this.temperatureUnit)&&(identical(other.oilTempThresholds, _this.oilTempThresholds) || other.oilTempThresholds == _this.oilTempThresholds)&&(identical(other.oilTempMaxRange, _this.oilTempMaxRange) || other.oilTempMaxRange == _this.oilTempMaxRange)&&(identical(other.pressureUnit, _this.pressureUnit) || other.pressureUnit == _this.pressureUnit)&&(identical(other.oilPressureThresholds, _this.oilPressureThresholds) || other.oilPressureThresholds == _this.oilPressureThresholds)&&(identical(other.oilPressureMaxRange, _this.oilPressureMaxRange) || other.oilPressureMaxRange == _this.oilPressureMaxRange)&&(identical(other.fuelThresholds, _this.fuelThresholds) || other.fuelThresholds == _this.fuelThresholds)&&(identical(other.egtThresholds, _this.egtThresholds) || other.egtThresholds == _this.egtThresholds)&&(identical(other.egtMaxRange, _this.egtMaxRange) || other.egtMaxRange == _this.egtMaxRange)&&(identical(other.chtThresholds, _this.chtThresholds) || other.chtThresholds == _this.chtThresholds)&&(identical(other.chtMaxRange, _this.chtMaxRange) || other.chtMaxRange == _this.chtMaxRange)&&(identical(other.rpmThresholds, _this.rpmThresholds) || other.rpmThresholds == _this.rpmThresholds)&&(identical(other.rpmMaxRange, _this.rpmMaxRange) || other.rpmMaxRange == _this.rpmMaxRange)&&(identical(other.trafficFilterMaxHorizontalDistanceEnabled, _this.trafficFilterMaxHorizontalDistanceEnabled) || other.trafficFilterMaxHorizontalDistanceEnabled == _this.trafficFilterMaxHorizontalDistanceEnabled)&&(identical(other.trafficMaxHorizontalDistance, _this.trafficMaxHorizontalDistance) || other.trafficMaxHorizontalDistance == _this.trafficMaxHorizontalDistance)&&(identical(other.trafficFilterMaxVerticalDistanceEnabled, _this.trafficFilterMaxVerticalDistanceEnabled) || other.trafficFilterMaxVerticalDistanceEnabled == _this.trafficFilterMaxVerticalDistanceEnabled)&&(identical(other.trafficMaxVerticalDistance, _this.trafficMaxVerticalDistance) || other.trafficMaxVerticalDistance == _this.trafficMaxVerticalDistance)&&(identical(other.casEnabled, _this.casEnabled) || other.casEnabled == _this.casEnabled)&&(identical(other.casLookaheadTime, _this.casLookaheadTime) || other.casLookaheadTime == _this.casLookaheadTime)&&(identical(other.casHorizontalThreshold, _this.casHorizontalThreshold) || other.casHorizontalThreshold == _this.casHorizontalThreshold)&&(identical(other.casVerticalThreshold, _this.casVerticalThreshold) || other.casVerticalThreshold == _this.casVerticalThreshold)&&(identical(other.gdl90Enabled, _this.gdl90Enabled) || other.gdl90Enabled == _this.gdl90Enabled)&&(identical(other.gdl90BindIp, _this.gdl90BindIp) || other.gdl90BindIp == _this.gdl90BindIp)&&(identical(other.gdl90UdpPort, _this.gdl90UdpPort) || other.gdl90UdpPort == _this.gdl90UdpPort)&&(identical(other.gdl90TargetExpirySeconds, _this.gdl90TargetExpirySeconds) || other.gdl90TargetExpirySeconds == _this.gdl90TargetExpirySeconds)&&(identical(other.ognEnabled, _this.ognEnabled) || other.ognEnabled == _this.ognEnabled)&&(identical(other.pureTrackEnabled, _this.pureTrackEnabled) || other.pureTrackEnabled == _this.pureTrackEnabled)&&const DeepCollectionEquality().equals(other.hiddenAircraftIds, _this.hiddenAircraftIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hashAll([runtimeType,_this.mapFontSize,_this.showUtcClock,_this.sunsetWarningMinutes,_this.mapDefaultZoom,_this.mapOverviewZoom,_this.mapFollowZoom,_this.mapFollowPitch,_this.flightSpeedThresholds,_this.flightSpeedMaxRange,_this.courseLineSegmentsCount,_this.courseLineSegmentDuration,_this.autoSelectDevice,_this.selectedDevice,_this.areWidgetsDraggable,const DeepCollectionEquality().hash(_this.widgetPositions),_this.speedUnit,_this.qnh,_this.qfe,_this.autoQnh,_this.altitudeUnit,_this.heightUnit,_this.averageSpeed,_this.pilotId,_this.airplaneId,_this.temperatureUnit,_this.oilTempThresholds,_this.oilTempMaxRange,_this.pressureUnit,_this.oilPressureThresholds,_this.oilPressureMaxRange,_this.fuelThresholds,_this.egtThresholds,_this.egtMaxRange,_this.chtThresholds,_this.chtMaxRange,_this.rpmThresholds,_this.rpmMaxRange,_this.trafficFilterMaxHorizontalDistanceEnabled,_this.trafficMaxHorizontalDistance,_this.trafficFilterMaxVerticalDistanceEnabled,_this.trafficMaxVerticalDistance,_this.casEnabled,_this.casLookaheadTime,_this.casHorizontalThreshold,_this.casVerticalThreshold,_this.gdl90Enabled,_this.gdl90BindIp,_this.gdl90UdpPort,_this.gdl90TargetExpirySeconds,_this.ognEnabled,_this.pureTrackEnabled,const DeepCollectionEquality().hash(_this.hiddenAircraftIds)]);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(mapFontSize: ${_this.mapFontSize}, showUtcClock: ${_this.showUtcClock}, sunsetWarningMinutes: ${_this.sunsetWarningMinutes}, mapDefaultZoom: ${_this.mapDefaultZoom}, mapOverviewZoom: ${_this.mapOverviewZoom}, mapFollowZoom: ${_this.mapFollowZoom}, mapFollowPitch: ${_this.mapFollowPitch}, flightSpeedThresholds: ${_this.flightSpeedThresholds}, flightSpeedMaxRange: ${_this.flightSpeedMaxRange}, courseLineSegmentsCount: ${_this.courseLineSegmentsCount}, courseLineSegmentDuration: ${_this.courseLineSegmentDuration}, autoSelectDevice: ${_this.autoSelectDevice}, selectedDevice: ${_this.selectedDevice}, areWidgetsDraggable: ${_this.areWidgetsDraggable}, widgetPositions: ${_this.widgetPositions}, speedUnit: ${_this.speedUnit}, qnh: ${_this.qnh}, qfe: ${_this.qfe}, autoQnh: ${_this.autoQnh}, altitudeUnit: ${_this.altitudeUnit}, heightUnit: ${_this.heightUnit}, averageSpeed: ${_this.averageSpeed}, pilotId: ${_this.pilotId}, airplaneId: ${_this.airplaneId}, temperatureUnit: ${_this.temperatureUnit}, oilTempThresholds: ${_this.oilTempThresholds}, oilTempMaxRange: ${_this.oilTempMaxRange}, pressureUnit: ${_this.pressureUnit}, oilPressureThresholds: ${_this.oilPressureThresholds}, oilPressureMaxRange: ${_this.oilPressureMaxRange}, fuelThresholds: ${_this.fuelThresholds}, egtThresholds: ${_this.egtThresholds}, egtMaxRange: ${_this.egtMaxRange}, chtThresholds: ${_this.chtThresholds}, chtMaxRange: ${_this.chtMaxRange}, rpmThresholds: ${_this.rpmThresholds}, rpmMaxRange: ${_this.rpmMaxRange}, trafficFilterMaxHorizontalDistanceEnabled: ${_this.trafficFilterMaxHorizontalDistanceEnabled}, trafficMaxHorizontalDistance: ${_this.trafficMaxHorizontalDistance}, trafficFilterMaxVerticalDistanceEnabled: ${_this.trafficFilterMaxVerticalDistanceEnabled}, trafficMaxVerticalDistance: ${_this.trafficMaxVerticalDistance}, casEnabled: ${_this.casEnabled}, casLookaheadTime: ${_this.casLookaheadTime}, casHorizontalThreshold: ${_this.casHorizontalThreshold}, casVerticalThreshold: ${_this.casVerticalThreshold}, gdl90Enabled: ${_this.gdl90Enabled}, gdl90BindIp: ${_this.gdl90BindIp}, gdl90UdpPort: ${_this.gdl90UdpPort}, gdl90TargetExpirySeconds: ${_this.gdl90TargetExpirySeconds}, ognEnabled: ${_this.ognEnabled}, pureTrackEnabled: ${_this.pureTrackEnabled}, hiddenAircraftIds: ${_this.hiddenAircraftIds})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 double mapFontSize, bool showUtcClock, int sunsetWarningMinutes, double mapDefaultZoom, double mapOverviewZoom, double mapFollowZoom, double mapFollowPitch, RangeThresholds flightSpeedThresholds, double flightSpeedMaxRange, int courseLineSegmentsCount, int courseLineSegmentDuration, bool autoSelectDevice, CannelloniDevice? selectedDevice, bool areWidgetsDraggable, Map<String, WidgetPosition> widgetPositions, SpeedUnit speedUnit, double qnh, double qfe, bool autoQnh, AltitudeUnit altitudeUnit, AltitudeUnit heightUnit, double averageSpeed, String? pilotId, String? airplaneId, TemperatureUnit temperatureUnit, RangeThresholds oilTempThresholds, double oilTempMaxRange, PressureUnit pressureUnit, RangeThresholds oilPressureThresholds, double oilPressureMaxRange, RangeThresholds fuelThresholds, RangeThresholds egtThresholds, double egtMaxRange, RangeThresholds chtThresholds, double chtMaxRange, RangeThresholds rpmThresholds, double rpmMaxRange, bool trafficFilterMaxHorizontalDistanceEnabled, double trafficMaxHorizontalDistance, bool trafficFilterMaxVerticalDistanceEnabled, double trafficMaxVerticalDistance, bool casEnabled, double casLookaheadTime, double casHorizontalThreshold, double casVerticalThreshold, bool gdl90Enabled, String gdl90BindIp, int gdl90UdpPort, int gdl90TargetExpirySeconds, bool ognEnabled, bool pureTrackEnabled, Set<String> hiddenAircraftIds
});


$RangeThresholdsCopyWith<$Res> get flightSpeedThresholds;$CannelloniDeviceCopyWith<$Res>? get selectedDevice;$RangeThresholdsCopyWith<$Res> get oilTempThresholds;$RangeThresholdsCopyWith<$Res> get oilPressureThresholds;$RangeThresholdsCopyWith<$Res> get fuelThresholds;$RangeThresholdsCopyWith<$Res> get egtThresholds;$RangeThresholdsCopyWith<$Res> get chtThresholds;$RangeThresholdsCopyWith<$Res> get rpmThresholds;

}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mapFontSize = null,Object? showUtcClock = null,Object? sunsetWarningMinutes = null,Object? mapDefaultZoom = null,Object? mapOverviewZoom = null,Object? mapFollowZoom = null,Object? mapFollowPitch = null,Object? flightSpeedThresholds = null,Object? flightSpeedMaxRange = null,Object? courseLineSegmentsCount = null,Object? courseLineSegmentDuration = null,Object? autoSelectDevice = null,Object? selectedDevice = freezed,Object? areWidgetsDraggable = null,Object? widgetPositions = null,Object? speedUnit = null,Object? qnh = null,Object? qfe = null,Object? autoQnh = null,Object? altitudeUnit = null,Object? heightUnit = null,Object? averageSpeed = null,Object? pilotId = freezed,Object? airplaneId = freezed,Object? temperatureUnit = null,Object? oilTempThresholds = null,Object? oilTempMaxRange = null,Object? pressureUnit = null,Object? oilPressureThresholds = null,Object? oilPressureMaxRange = null,Object? fuelThresholds = null,Object? egtThresholds = null,Object? egtMaxRange = null,Object? chtThresholds = null,Object? chtMaxRange = null,Object? rpmThresholds = null,Object? rpmMaxRange = null,Object? trafficFilterMaxHorizontalDistanceEnabled = null,Object? trafficMaxHorizontalDistance = null,Object? trafficFilterMaxVerticalDistanceEnabled = null,Object? trafficMaxVerticalDistance = null,Object? casEnabled = null,Object? casLookaheadTime = null,Object? casHorizontalThreshold = null,Object? casVerticalThreshold = null,Object? gdl90Enabled = null,Object? gdl90BindIp = null,Object? gdl90UdpPort = null,Object? gdl90TargetExpirySeconds = null,Object? ognEnabled = null,Object? pureTrackEnabled = null,Object? hiddenAircraftIds = null,}) {
  return _then(AppSettings(
mapFontSize: null == mapFontSize ? _self.mapFontSize : mapFontSize // ignore: cast_nullable_to_non_nullable
as double,showUtcClock: null == showUtcClock ? _self.showUtcClock : showUtcClock // ignore: cast_nullable_to_non_nullable
as bool,sunsetWarningMinutes: null == sunsetWarningMinutes ? _self.sunsetWarningMinutes : sunsetWarningMinutes // ignore: cast_nullable_to_non_nullable
as int,mapDefaultZoom: null == mapDefaultZoom ? _self.mapDefaultZoom : mapDefaultZoom // ignore: cast_nullable_to_non_nullable
as double,mapOverviewZoom: null == mapOverviewZoom ? _self.mapOverviewZoom : mapOverviewZoom // ignore: cast_nullable_to_non_nullable
as double,mapFollowZoom: null == mapFollowZoom ? _self.mapFollowZoom : mapFollowZoom // ignore: cast_nullable_to_non_nullable
as double,mapFollowPitch: null == mapFollowPitch ? _self.mapFollowPitch : mapFollowPitch // ignore: cast_nullable_to_non_nullable
as double,flightSpeedThresholds: null == flightSpeedThresholds ? _self.flightSpeedThresholds : flightSpeedThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,flightSpeedMaxRange: null == flightSpeedMaxRange ? _self.flightSpeedMaxRange : flightSpeedMaxRange // ignore: cast_nullable_to_non_nullable
as double,courseLineSegmentsCount: null == courseLineSegmentsCount ? _self.courseLineSegmentsCount : courseLineSegmentsCount // ignore: cast_nullable_to_non_nullable
as int,courseLineSegmentDuration: null == courseLineSegmentDuration ? _self.courseLineSegmentDuration : courseLineSegmentDuration // ignore: cast_nullable_to_non_nullable
as int,autoSelectDevice: null == autoSelectDevice ? _self.autoSelectDevice : autoSelectDevice // ignore: cast_nullable_to_non_nullable
as bool,selectedDevice: freezed == selectedDevice ? _self.selectedDevice : selectedDevice // ignore: cast_nullable_to_non_nullable
as CannelloniDevice?,areWidgetsDraggable: null == areWidgetsDraggable ? _self.areWidgetsDraggable : areWidgetsDraggable // ignore: cast_nullable_to_non_nullable
as bool,widgetPositions: null == widgetPositions ? _self.widgetPositions : widgetPositions // ignore: cast_nullable_to_non_nullable
as Map<String, WidgetPosition>,speedUnit: null == speedUnit ? _self.speedUnit : speedUnit // ignore: cast_nullable_to_non_nullable
as SpeedUnit,qnh: null == qnh ? _self.qnh : qnh // ignore: cast_nullable_to_non_nullable
as double,qfe: null == qfe ? _self.qfe : qfe // ignore: cast_nullable_to_non_nullable
as double,autoQnh: null == autoQnh ? _self.autoQnh : autoQnh // ignore: cast_nullable_to_non_nullable
as bool,altitudeUnit: null == altitudeUnit ? _self.altitudeUnit : altitudeUnit // ignore: cast_nullable_to_non_nullable
as AltitudeUnit,heightUnit: null == heightUnit ? _self.heightUnit : heightUnit // ignore: cast_nullable_to_non_nullable
as AltitudeUnit,averageSpeed: null == averageSpeed ? _self.averageSpeed : averageSpeed // ignore: cast_nullable_to_non_nullable
as double,pilotId: freezed == pilotId ? _self.pilotId : pilotId // ignore: cast_nullable_to_non_nullable
as String?,airplaneId: freezed == airplaneId ? _self.airplaneId : airplaneId // ignore: cast_nullable_to_non_nullable
as String?,temperatureUnit: null == temperatureUnit ? _self.temperatureUnit : temperatureUnit // ignore: cast_nullable_to_non_nullable
as TemperatureUnit,oilTempThresholds: null == oilTempThresholds ? _self.oilTempThresholds : oilTempThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,oilTempMaxRange: null == oilTempMaxRange ? _self.oilTempMaxRange : oilTempMaxRange // ignore: cast_nullable_to_non_nullable
as double,pressureUnit: null == pressureUnit ? _self.pressureUnit : pressureUnit // ignore: cast_nullable_to_non_nullable
as PressureUnit,oilPressureThresholds: null == oilPressureThresholds ? _self.oilPressureThresholds : oilPressureThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,oilPressureMaxRange: null == oilPressureMaxRange ? _self.oilPressureMaxRange : oilPressureMaxRange // ignore: cast_nullable_to_non_nullable
as double,fuelThresholds: null == fuelThresholds ? _self.fuelThresholds : fuelThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,egtThresholds: null == egtThresholds ? _self.egtThresholds : egtThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,egtMaxRange: null == egtMaxRange ? _self.egtMaxRange : egtMaxRange // ignore: cast_nullable_to_non_nullable
as double,chtThresholds: null == chtThresholds ? _self.chtThresholds : chtThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,chtMaxRange: null == chtMaxRange ? _self.chtMaxRange : chtMaxRange // ignore: cast_nullable_to_non_nullable
as double,rpmThresholds: null == rpmThresholds ? _self.rpmThresholds : rpmThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,rpmMaxRange: null == rpmMaxRange ? _self.rpmMaxRange : rpmMaxRange // ignore: cast_nullable_to_non_nullable
as double,trafficFilterMaxHorizontalDistanceEnabled: null == trafficFilterMaxHorizontalDistanceEnabled ? _self.trafficFilterMaxHorizontalDistanceEnabled : trafficFilterMaxHorizontalDistanceEnabled // ignore: cast_nullable_to_non_nullable
as bool,trafficMaxHorizontalDistance: null == trafficMaxHorizontalDistance ? _self.trafficMaxHorizontalDistance : trafficMaxHorizontalDistance // ignore: cast_nullable_to_non_nullable
as double,trafficFilterMaxVerticalDistanceEnabled: null == trafficFilterMaxVerticalDistanceEnabled ? _self.trafficFilterMaxVerticalDistanceEnabled : trafficFilterMaxVerticalDistanceEnabled // ignore: cast_nullable_to_non_nullable
as bool,trafficMaxVerticalDistance: null == trafficMaxVerticalDistance ? _self.trafficMaxVerticalDistance : trafficMaxVerticalDistance // ignore: cast_nullable_to_non_nullable
as double,casEnabled: null == casEnabled ? _self.casEnabled : casEnabled // ignore: cast_nullable_to_non_nullable
as bool,casLookaheadTime: null == casLookaheadTime ? _self.casLookaheadTime : casLookaheadTime // ignore: cast_nullable_to_non_nullable
as double,casHorizontalThreshold: null == casHorizontalThreshold ? _self.casHorizontalThreshold : casHorizontalThreshold // ignore: cast_nullable_to_non_nullable
as double,casVerticalThreshold: null == casVerticalThreshold ? _self.casVerticalThreshold : casVerticalThreshold // ignore: cast_nullable_to_non_nullable
as double,gdl90Enabled: null == gdl90Enabled ? _self.gdl90Enabled : gdl90Enabled // ignore: cast_nullable_to_non_nullable
as bool,gdl90BindIp: null == gdl90BindIp ? _self.gdl90BindIp : gdl90BindIp // ignore: cast_nullable_to_non_nullable
as String,gdl90UdpPort: null == gdl90UdpPort ? _self.gdl90UdpPort : gdl90UdpPort // ignore: cast_nullable_to_non_nullable
as int,gdl90TargetExpirySeconds: null == gdl90TargetExpirySeconds ? _self.gdl90TargetExpirySeconds : gdl90TargetExpirySeconds // ignore: cast_nullable_to_non_nullable
as int,ognEnabled: null == ognEnabled ? _self.ognEnabled : ognEnabled // ignore: cast_nullable_to_non_nullable
as bool,pureTrackEnabled: null == pureTrackEnabled ? _self.pureTrackEnabled : pureTrackEnabled // ignore: cast_nullable_to_non_nullable
as bool,hiddenAircraftIds: null == hiddenAircraftIds ? _self.hiddenAircraftIds : hiddenAircraftIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
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
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get oilTempThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.oilTempThresholds, (value) {
    return _then(_self.copyWith(oilTempThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get oilPressureThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.oilPressureThresholds, (value) {
    return _then(_self.copyWith(oilPressureThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get fuelThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.fuelThresholds, (value) {
    return _then(_self.copyWith(fuelThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get egtThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.egtThresholds, (value) {
    return _then(_self.copyWith(egtThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get chtThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.chtThresholds, (value) {
    return _then(_self.copyWith(chtThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get rpmThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.rpmThresholds, (value) {
    return _then(_self.copyWith(rpmThresholds: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double mapFontSize,  bool showUtcClock,  int sunsetWarningMinutes,  double mapDefaultZoom,  double mapOverviewZoom,  double mapFollowZoom,  double mapFollowPitch,  RangeThresholds flightSpeedThresholds,  double flightSpeedMaxRange,  int courseLineSegmentsCount,  int courseLineSegmentDuration,  bool autoSelectDevice,  CannelloniDevice? selectedDevice,  bool areWidgetsDraggable,  Map<String, WidgetPosition> widgetPositions,  SpeedUnit speedUnit,  double qnh,  double qfe,  bool autoQnh,  AltitudeUnit altitudeUnit,  AltitudeUnit heightUnit,  double averageSpeed,  String? pilotId,  String? airplaneId,  TemperatureUnit temperatureUnit,  RangeThresholds oilTempThresholds,  double oilTempMaxRange,  PressureUnit pressureUnit,  RangeThresholds oilPressureThresholds,  double oilPressureMaxRange,  RangeThresholds fuelThresholds,  RangeThresholds egtThresholds,  double egtMaxRange,  RangeThresholds chtThresholds,  double chtMaxRange,  RangeThresholds rpmThresholds,  double rpmMaxRange,  bool trafficFilterMaxHorizontalDistanceEnabled,  double trafficMaxHorizontalDistance,  bool trafficFilterMaxVerticalDistanceEnabled,  double trafficMaxVerticalDistance,  bool casEnabled,  double casLookaheadTime,  double casHorizontalThreshold,  double casVerticalThreshold,  bool gdl90Enabled,  String gdl90BindIp,  int gdl90UdpPort,  int gdl90TargetExpirySeconds,  bool ognEnabled,  bool pureTrackEnabled,  Set<String> hiddenAircraftIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.mapFontSize,_that.showUtcClock,_that.sunsetWarningMinutes,_that.mapDefaultZoom,_that.mapOverviewZoom,_that.mapFollowZoom,_that.mapFollowPitch,_that.flightSpeedThresholds,_that.flightSpeedMaxRange,_that.courseLineSegmentsCount,_that.courseLineSegmentDuration,_that.autoSelectDevice,_that.selectedDevice,_that.areWidgetsDraggable,_that.widgetPositions,_that.speedUnit,_that.qnh,_that.qfe,_that.autoQnh,_that.altitudeUnit,_that.heightUnit,_that.averageSpeed,_that.pilotId,_that.airplaneId,_that.temperatureUnit,_that.oilTempThresholds,_that.oilTempMaxRange,_that.pressureUnit,_that.oilPressureThresholds,_that.oilPressureMaxRange,_that.fuelThresholds,_that.egtThresholds,_that.egtMaxRange,_that.chtThresholds,_that.chtMaxRange,_that.rpmThresholds,_that.rpmMaxRange,_that.trafficFilterMaxHorizontalDistanceEnabled,_that.trafficMaxHorizontalDistance,_that.trafficFilterMaxVerticalDistanceEnabled,_that.trafficMaxVerticalDistance,_that.casEnabled,_that.casLookaheadTime,_that.casHorizontalThreshold,_that.casVerticalThreshold,_that.gdl90Enabled,_that.gdl90BindIp,_that.gdl90UdpPort,_that.gdl90TargetExpirySeconds,_that.ognEnabled,_that.pureTrackEnabled,_that.hiddenAircraftIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double mapFontSize,  bool showUtcClock,  int sunsetWarningMinutes,  double mapDefaultZoom,  double mapOverviewZoom,  double mapFollowZoom,  double mapFollowPitch,  RangeThresholds flightSpeedThresholds,  double flightSpeedMaxRange,  int courseLineSegmentsCount,  int courseLineSegmentDuration,  bool autoSelectDevice,  CannelloniDevice? selectedDevice,  bool areWidgetsDraggable,  Map<String, WidgetPosition> widgetPositions,  SpeedUnit speedUnit,  double qnh,  double qfe,  bool autoQnh,  AltitudeUnit altitudeUnit,  AltitudeUnit heightUnit,  double averageSpeed,  String? pilotId,  String? airplaneId,  TemperatureUnit temperatureUnit,  RangeThresholds oilTempThresholds,  double oilTempMaxRange,  PressureUnit pressureUnit,  RangeThresholds oilPressureThresholds,  double oilPressureMaxRange,  RangeThresholds fuelThresholds,  RangeThresholds egtThresholds,  double egtMaxRange,  RangeThresholds chtThresholds,  double chtMaxRange,  RangeThresholds rpmThresholds,  double rpmMaxRange,  bool trafficFilterMaxHorizontalDistanceEnabled,  double trafficMaxHorizontalDistance,  bool trafficFilterMaxVerticalDistanceEnabled,  double trafficMaxVerticalDistance,  bool casEnabled,  double casLookaheadTime,  double casHorizontalThreshold,  double casVerticalThreshold,  bool gdl90Enabled,  String gdl90BindIp,  int gdl90UdpPort,  int gdl90TargetExpirySeconds,  bool ognEnabled,  bool pureTrackEnabled,  Set<String> hiddenAircraftIds)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.mapFontSize,_that.showUtcClock,_that.sunsetWarningMinutes,_that.mapDefaultZoom,_that.mapOverviewZoom,_that.mapFollowZoom,_that.mapFollowPitch,_that.flightSpeedThresholds,_that.flightSpeedMaxRange,_that.courseLineSegmentsCount,_that.courseLineSegmentDuration,_that.autoSelectDevice,_that.selectedDevice,_that.areWidgetsDraggable,_that.widgetPositions,_that.speedUnit,_that.qnh,_that.qfe,_that.autoQnh,_that.altitudeUnit,_that.heightUnit,_that.averageSpeed,_that.pilotId,_that.airplaneId,_that.temperatureUnit,_that.oilTempThresholds,_that.oilTempMaxRange,_that.pressureUnit,_that.oilPressureThresholds,_that.oilPressureMaxRange,_that.fuelThresholds,_that.egtThresholds,_that.egtMaxRange,_that.chtThresholds,_that.chtMaxRange,_that.rpmThresholds,_that.rpmMaxRange,_that.trafficFilterMaxHorizontalDistanceEnabled,_that.trafficMaxHorizontalDistance,_that.trafficFilterMaxVerticalDistanceEnabled,_that.trafficMaxVerticalDistance,_that.casEnabled,_that.casLookaheadTime,_that.casHorizontalThreshold,_that.casVerticalThreshold,_that.gdl90Enabled,_that.gdl90BindIp,_that.gdl90UdpPort,_that.gdl90TargetExpirySeconds,_that.ognEnabled,_that.pureTrackEnabled,_that.hiddenAircraftIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double mapFontSize,  bool showUtcClock,  int sunsetWarningMinutes,  double mapDefaultZoom,  double mapOverviewZoom,  double mapFollowZoom,  double mapFollowPitch,  RangeThresholds flightSpeedThresholds,  double flightSpeedMaxRange,  int courseLineSegmentsCount,  int courseLineSegmentDuration,  bool autoSelectDevice,  CannelloniDevice? selectedDevice,  bool areWidgetsDraggable,  Map<String, WidgetPosition> widgetPositions,  SpeedUnit speedUnit,  double qnh,  double qfe,  bool autoQnh,  AltitudeUnit altitudeUnit,  AltitudeUnit heightUnit,  double averageSpeed,  String? pilotId,  String? airplaneId,  TemperatureUnit temperatureUnit,  RangeThresholds oilTempThresholds,  double oilTempMaxRange,  PressureUnit pressureUnit,  RangeThresholds oilPressureThresholds,  double oilPressureMaxRange,  RangeThresholds fuelThresholds,  RangeThresholds egtThresholds,  double egtMaxRange,  RangeThresholds chtThresholds,  double chtMaxRange,  RangeThresholds rpmThresholds,  double rpmMaxRange,  bool trafficFilterMaxHorizontalDistanceEnabled,  double trafficMaxHorizontalDistance,  bool trafficFilterMaxVerticalDistanceEnabled,  double trafficMaxVerticalDistance,  bool casEnabled,  double casLookaheadTime,  double casHorizontalThreshold,  double casVerticalThreshold,  bool gdl90Enabled,  String gdl90BindIp,  int gdl90UdpPort,  int gdl90TargetExpirySeconds,  bool ognEnabled,  bool pureTrackEnabled,  Set<String> hiddenAircraftIds)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.mapFontSize,_that.showUtcClock,_that.sunsetWarningMinutes,_that.mapDefaultZoom,_that.mapOverviewZoom,_that.mapFollowZoom,_that.mapFollowPitch,_that.flightSpeedThresholds,_that.flightSpeedMaxRange,_that.courseLineSegmentsCount,_that.courseLineSegmentDuration,_that.autoSelectDevice,_that.selectedDevice,_that.areWidgetsDraggable,_that.widgetPositions,_that.speedUnit,_that.qnh,_that.qfe,_that.autoQnh,_that.altitudeUnit,_that.heightUnit,_that.averageSpeed,_that.pilotId,_that.airplaneId,_that.temperatureUnit,_that.oilTempThresholds,_that.oilTempMaxRange,_that.pressureUnit,_that.oilPressureThresholds,_that.oilPressureMaxRange,_that.fuelThresholds,_that.egtThresholds,_that.egtMaxRange,_that.chtThresholds,_that.chtMaxRange,_that.rpmThresholds,_that.rpmMaxRange,_that.trafficFilterMaxHorizontalDistanceEnabled,_that.trafficMaxHorizontalDistance,_that.trafficFilterMaxVerticalDistanceEnabled,_that.trafficMaxVerticalDistance,_that.casEnabled,_that.casLookaheadTime,_that.casHorizontalThreshold,_that.casVerticalThreshold,_that.gdl90Enabled,_that.gdl90BindIp,_that.gdl90UdpPort,_that.gdl90TargetExpirySeconds,_that.ognEnabled,_that.pureTrackEnabled,_that.hiddenAircraftIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings extends AppSettings {
  const _AppSettings({this.mapFontSize = 1.0, this.showUtcClock = true, this.sunsetWarningMinutes = 60, this.mapDefaultZoom = 6.0, this.mapOverviewZoom = 10.0, this.mapFollowZoom = 12.0, this.mapFollowPitch = 30.0, this.flightSpeedThresholds = const RangeThresholds.raw(inactiveMax: 2.77, minError: 16.67, minWarning: 20.83, maxWarning: 30.56, maxError: 34.72), this.flightSpeedMaxRange = 38.89, this.courseLineSegmentsCount = 5, this.courseLineSegmentDuration = 60, this.autoSelectDevice = true, this.selectedDevice, this.areWidgetsDraggable = false,  Map<String, WidgetPosition> widgetPositions = const {}, this.speedUnit = SpeedUnit.kmh, this.qnh = 1013.25, this.qfe = 1013.25, this.autoQnh = true, this.altitudeUnit = AltitudeUnit.feet, this.heightUnit = AltitudeUnit.meters, this.averageSpeed = 27.78, this.pilotId, this.airplaneId, this.temperatureUnit = TemperatureUnit.celsius, this.oilTempThresholds = const RangeThresholds.raw(inactiveMax: 303.15, minError: 323.15, minWarning: 333.15, maxWarning: 383.15, maxError: 403.15), this.oilTempMaxRange = 413.15, this.pressureUnit = PressureUnit.bar, this.oilPressureThresholds = const RangeThresholds.raw(inactiveMax: 50.0, minError: 80.0, minWarning: 200.0, maxWarning: 500.0, maxError: 700.0), this.oilPressureMaxRange = 800.0, this.fuelThresholds = const RangeThresholds.raw(minError: 10.0, minWarning: 20.0), this.egtThresholds = const RangeThresholds.raw(inactiveMax: 423.15, minError: 773.15, minWarning: 973.15, maxWarning: 1153.15, maxError: 1173.15), this.egtMaxRange = 1223.15, this.chtThresholds = const RangeThresholds.raw(inactiveMax: 323.15, minError: 333.15, minWarning: 348.15, maxWarning: 403.15, maxError: 423.15), this.chtMaxRange = 433.15, this.rpmThresholds = const RangeThresholds.raw(inactiveMax: 10.0, minError: 1400.0, minWarning: 1800.0, maxWarning: 5500.0, maxError: 5800.0), this.rpmMaxRange = 6000.0, this.trafficFilterMaxHorizontalDistanceEnabled = true, this.trafficMaxHorizontalDistance = 50000.0, this.trafficFilterMaxVerticalDistanceEnabled = true, this.trafficMaxVerticalDistance = 1500.0, this.casEnabled = true, this.casLookaheadTime = 30.0, this.casHorizontalThreshold = 300.0, this.casVerticalThreshold = 100.0, this.gdl90Enabled = true, this.gdl90BindIp = '0.0.0.0', this.gdl90UdpPort = 4000, this.gdl90TargetExpirySeconds = 60, this.ognEnabled = true, this.pureTrackEnabled = true,  Set<String> hiddenAircraftIds = const {}}): _widgetPositions = widgetPositions,_hiddenAircraftIds = hiddenAircraftIds,super._();
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  double mapFontSize;
@override@JsonKey() final  bool showUtcClock;
@override@JsonKey() final  int sunsetWarningMinutes;
@override@JsonKey() final  double mapDefaultZoom;
@override@JsonKey() final  double mapOverviewZoom;
@override@JsonKey() final  double mapFollowZoom;
@override@JsonKey() final  double mapFollowPitch;
@override@JsonKey() final  RangeThresholds flightSpeedThresholds;
@override@JsonKey() final  double flightSpeedMaxRange;
@override@JsonKey() final  int courseLineSegmentsCount;
@override@JsonKey() final  int courseLineSegmentDuration;
@override@JsonKey() final  bool autoSelectDevice;
@override final  CannelloniDevice? selectedDevice;
@override@JsonKey() final  bool areWidgetsDraggable;
 final  Map<String, WidgetPosition> _widgetPositions;
@override@JsonKey() Map<String, WidgetPosition> get widgetPositions {
  if (_widgetPositions is EqualUnmodifiableMapView) return _widgetPositions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_widgetPositions);
}

@override@JsonKey() final  SpeedUnit speedUnit;
@override@JsonKey() final  double qnh;
@override@JsonKey() final  double qfe;
@override@JsonKey() final  bool autoQnh;
@override@JsonKey() final  AltitudeUnit altitudeUnit;
@override@JsonKey() final  AltitudeUnit heightUnit;
@override@JsonKey() final  double averageSpeed;
@override final  String? pilotId;
@override final  String? airplaneId;
@override@JsonKey() final  TemperatureUnit temperatureUnit;
@override@JsonKey() final  RangeThresholds oilTempThresholds;
@override@JsonKey() final  double oilTempMaxRange;
@override@JsonKey() final  PressureUnit pressureUnit;
@override@JsonKey() final  RangeThresholds oilPressureThresholds;
@override@JsonKey() final  double oilPressureMaxRange;
@override@JsonKey() final  RangeThresholds fuelThresholds;
@override@JsonKey() final  RangeThresholds egtThresholds;
@override@JsonKey() final  double egtMaxRange;
@override@JsonKey() final  RangeThresholds chtThresholds;
@override@JsonKey() final  double chtMaxRange;
@override@JsonKey() final  RangeThresholds rpmThresholds;
@override@JsonKey() final  double rpmMaxRange;
@override@JsonKey() final  bool trafficFilterMaxHorizontalDistanceEnabled;
@override@JsonKey() final  double trafficMaxHorizontalDistance;
@override@JsonKey() final  bool trafficFilterMaxVerticalDistanceEnabled;
@override@JsonKey() final  double trafficMaxVerticalDistance;
@override@JsonKey() final  bool casEnabled;
@override@JsonKey() final  double casLookaheadTime;
@override@JsonKey() final  double casHorizontalThreshold;
@override@JsonKey() final  double casVerticalThreshold;
@override@JsonKey() final  bool gdl90Enabled;
@override@JsonKey() final  String gdl90BindIp;
@override@JsonKey() final  int gdl90UdpPort;
@override@JsonKey() final  int gdl90TargetExpirySeconds;
@override@JsonKey() final  bool ognEnabled;
@override@JsonKey() final  bool pureTrackEnabled;
 final  Set<String> _hiddenAircraftIds;
@override@JsonKey() Set<String> get hiddenAircraftIds {
  if (_hiddenAircraftIds is EqualUnmodifiableSetView) return _hiddenAircraftIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_hiddenAircraftIds);
}


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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.mapFontSize, mapFontSize) || other.mapFontSize == mapFontSize)&&(identical(other.showUtcClock, showUtcClock) || other.showUtcClock == showUtcClock)&&(identical(other.sunsetWarningMinutes, sunsetWarningMinutes) || other.sunsetWarningMinutes == sunsetWarningMinutes)&&(identical(other.mapDefaultZoom, mapDefaultZoom) || other.mapDefaultZoom == mapDefaultZoom)&&(identical(other.mapOverviewZoom, mapOverviewZoom) || other.mapOverviewZoom == mapOverviewZoom)&&(identical(other.mapFollowZoom, mapFollowZoom) || other.mapFollowZoom == mapFollowZoom)&&(identical(other.mapFollowPitch, mapFollowPitch) || other.mapFollowPitch == mapFollowPitch)&&(identical(other.flightSpeedThresholds, flightSpeedThresholds) || other.flightSpeedThresholds == flightSpeedThresholds)&&(identical(other.flightSpeedMaxRange, flightSpeedMaxRange) || other.flightSpeedMaxRange == flightSpeedMaxRange)&&(identical(other.courseLineSegmentsCount, courseLineSegmentsCount) || other.courseLineSegmentsCount == courseLineSegmentsCount)&&(identical(other.courseLineSegmentDuration, courseLineSegmentDuration) || other.courseLineSegmentDuration == courseLineSegmentDuration)&&(identical(other.autoSelectDevice, autoSelectDevice) || other.autoSelectDevice == autoSelectDevice)&&(identical(other.selectedDevice, selectedDevice) || other.selectedDevice == selectedDevice)&&(identical(other.areWidgetsDraggable, areWidgetsDraggable) || other.areWidgetsDraggable == areWidgetsDraggable)&&const DeepCollectionEquality().equals(other.widgetPositions, _widgetPositions)&&(identical(other.speedUnit, speedUnit) || other.speedUnit == speedUnit)&&(identical(other.qnh, qnh) || other.qnh == qnh)&&(identical(other.qfe, qfe) || other.qfe == qfe)&&(identical(other.autoQnh, autoQnh) || other.autoQnh == autoQnh)&&(identical(other.altitudeUnit, altitudeUnit) || other.altitudeUnit == altitudeUnit)&&(identical(other.heightUnit, heightUnit) || other.heightUnit == heightUnit)&&(identical(other.averageSpeed, averageSpeed) || other.averageSpeed == averageSpeed)&&(identical(other.pilotId, pilotId) || other.pilotId == pilotId)&&(identical(other.airplaneId, airplaneId) || other.airplaneId == airplaneId)&&(identical(other.temperatureUnit, temperatureUnit) || other.temperatureUnit == temperatureUnit)&&(identical(other.oilTempThresholds, oilTempThresholds) || other.oilTempThresholds == oilTempThresholds)&&(identical(other.oilTempMaxRange, oilTempMaxRange) || other.oilTempMaxRange == oilTempMaxRange)&&(identical(other.pressureUnit, pressureUnit) || other.pressureUnit == pressureUnit)&&(identical(other.oilPressureThresholds, oilPressureThresholds) || other.oilPressureThresholds == oilPressureThresholds)&&(identical(other.oilPressureMaxRange, oilPressureMaxRange) || other.oilPressureMaxRange == oilPressureMaxRange)&&(identical(other.fuelThresholds, fuelThresholds) || other.fuelThresholds == fuelThresholds)&&(identical(other.egtThresholds, egtThresholds) || other.egtThresholds == egtThresholds)&&(identical(other.egtMaxRange, egtMaxRange) || other.egtMaxRange == egtMaxRange)&&(identical(other.chtThresholds, chtThresholds) || other.chtThresholds == chtThresholds)&&(identical(other.chtMaxRange, chtMaxRange) || other.chtMaxRange == chtMaxRange)&&(identical(other.rpmThresholds, rpmThresholds) || other.rpmThresholds == rpmThresholds)&&(identical(other.rpmMaxRange, rpmMaxRange) || other.rpmMaxRange == rpmMaxRange)&&(identical(other.trafficFilterMaxHorizontalDistanceEnabled, trafficFilterMaxHorizontalDistanceEnabled) || other.trafficFilterMaxHorizontalDistanceEnabled == trafficFilterMaxHorizontalDistanceEnabled)&&(identical(other.trafficMaxHorizontalDistance, trafficMaxHorizontalDistance) || other.trafficMaxHorizontalDistance == trafficMaxHorizontalDistance)&&(identical(other.trafficFilterMaxVerticalDistanceEnabled, trafficFilterMaxVerticalDistanceEnabled) || other.trafficFilterMaxVerticalDistanceEnabled == trafficFilterMaxVerticalDistanceEnabled)&&(identical(other.trafficMaxVerticalDistance, trafficMaxVerticalDistance) || other.trafficMaxVerticalDistance == trafficMaxVerticalDistance)&&(identical(other.casEnabled, casEnabled) || other.casEnabled == casEnabled)&&(identical(other.casLookaheadTime, casLookaheadTime) || other.casLookaheadTime == casLookaheadTime)&&(identical(other.casHorizontalThreshold, casHorizontalThreshold) || other.casHorizontalThreshold == casHorizontalThreshold)&&(identical(other.casVerticalThreshold, casVerticalThreshold) || other.casVerticalThreshold == casVerticalThreshold)&&(identical(other.gdl90Enabled, gdl90Enabled) || other.gdl90Enabled == gdl90Enabled)&&(identical(other.gdl90BindIp, gdl90BindIp) || other.gdl90BindIp == gdl90BindIp)&&(identical(other.gdl90UdpPort, gdl90UdpPort) || other.gdl90UdpPort == gdl90UdpPort)&&(identical(other.gdl90TargetExpirySeconds, gdl90TargetExpirySeconds) || other.gdl90TargetExpirySeconds == gdl90TargetExpirySeconds)&&(identical(other.ognEnabled, ognEnabled) || other.ognEnabled == ognEnabled)&&(identical(other.pureTrackEnabled, pureTrackEnabled) || other.pureTrackEnabled == pureTrackEnabled)&&const DeepCollectionEquality().equals(other.hiddenAircraftIds, _hiddenAircraftIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,mapFontSize,showUtcClock,sunsetWarningMinutes,mapDefaultZoom,mapOverviewZoom,mapFollowZoom,mapFollowPitch,flightSpeedThresholds,flightSpeedMaxRange,courseLineSegmentsCount,courseLineSegmentDuration,autoSelectDevice,selectedDevice,areWidgetsDraggable,const DeepCollectionEquality().hash(_widgetPositions),speedUnit,qnh,qfe,autoQnh,altitudeUnit,heightUnit,averageSpeed,pilotId,airplaneId,temperatureUnit,oilTempThresholds,oilTempMaxRange,pressureUnit,oilPressureThresholds,oilPressureMaxRange,fuelThresholds,egtThresholds,egtMaxRange,chtThresholds,chtMaxRange,rpmThresholds,rpmMaxRange,trafficFilterMaxHorizontalDistanceEnabled,trafficMaxHorizontalDistance,trafficFilterMaxVerticalDistanceEnabled,trafficMaxVerticalDistance,casEnabled,casLookaheadTime,casHorizontalThreshold,casVerticalThreshold,gdl90Enabled,gdl90BindIp,gdl90UdpPort,gdl90TargetExpirySeconds,ognEnabled,pureTrackEnabled,const DeepCollectionEquality().hash(_hiddenAircraftIds)]);
}

@override
String toString() {
    return 'AppSettings(mapFontSize: $mapFontSize, showUtcClock: $showUtcClock, sunsetWarningMinutes: $sunsetWarningMinutes, mapDefaultZoom: $mapDefaultZoom, mapOverviewZoom: $mapOverviewZoom, mapFollowZoom: $mapFollowZoom, mapFollowPitch: $mapFollowPitch, flightSpeedThresholds: $flightSpeedThresholds, flightSpeedMaxRange: $flightSpeedMaxRange, courseLineSegmentsCount: $courseLineSegmentsCount, courseLineSegmentDuration: $courseLineSegmentDuration, autoSelectDevice: $autoSelectDevice, selectedDevice: $selectedDevice, areWidgetsDraggable: $areWidgetsDraggable, widgetPositions: $widgetPositions, speedUnit: $speedUnit, qnh: $qnh, qfe: $qfe, autoQnh: $autoQnh, altitudeUnit: $altitudeUnit, heightUnit: $heightUnit, averageSpeed: $averageSpeed, pilotId: $pilotId, airplaneId: $airplaneId, temperatureUnit: $temperatureUnit, oilTempThresholds: $oilTempThresholds, oilTempMaxRange: $oilTempMaxRange, pressureUnit: $pressureUnit, oilPressureThresholds: $oilPressureThresholds, oilPressureMaxRange: $oilPressureMaxRange, fuelThresholds: $fuelThresholds, egtThresholds: $egtThresholds, egtMaxRange: $egtMaxRange, chtThresholds: $chtThresholds, chtMaxRange: $chtMaxRange, rpmThresholds: $rpmThresholds, rpmMaxRange: $rpmMaxRange, trafficFilterMaxHorizontalDistanceEnabled: $trafficFilterMaxHorizontalDistanceEnabled, trafficMaxHorizontalDistance: $trafficMaxHorizontalDistance, trafficFilterMaxVerticalDistanceEnabled: $trafficFilterMaxVerticalDistanceEnabled, trafficMaxVerticalDistance: $trafficMaxVerticalDistance, casEnabled: $casEnabled, casLookaheadTime: $casLookaheadTime, casHorizontalThreshold: $casHorizontalThreshold, casVerticalThreshold: $casVerticalThreshold, gdl90Enabled: $gdl90Enabled, gdl90BindIp: $gdl90BindIp, gdl90UdpPort: $gdl90UdpPort, gdl90TargetExpirySeconds: $gdl90TargetExpirySeconds, ognEnabled: $ognEnabled, pureTrackEnabled: $pureTrackEnabled, hiddenAircraftIds: $hiddenAircraftIds)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 double mapFontSize, bool showUtcClock, int sunsetWarningMinutes, double mapDefaultZoom, double mapOverviewZoom, double mapFollowZoom, double mapFollowPitch, RangeThresholds flightSpeedThresholds, double flightSpeedMaxRange, int courseLineSegmentsCount, int courseLineSegmentDuration, bool autoSelectDevice, CannelloniDevice? selectedDevice, bool areWidgetsDraggable, Map<String, WidgetPosition> widgetPositions, SpeedUnit speedUnit, double qnh, double qfe, bool autoQnh, AltitudeUnit altitudeUnit, AltitudeUnit heightUnit, double averageSpeed, String? pilotId, String? airplaneId, TemperatureUnit temperatureUnit, RangeThresholds oilTempThresholds, double oilTempMaxRange, PressureUnit pressureUnit, RangeThresholds oilPressureThresholds, double oilPressureMaxRange, RangeThresholds fuelThresholds, RangeThresholds egtThresholds, double egtMaxRange, RangeThresholds chtThresholds, double chtMaxRange, RangeThresholds rpmThresholds, double rpmMaxRange, bool trafficFilterMaxHorizontalDistanceEnabled, double trafficMaxHorizontalDistance, bool trafficFilterMaxVerticalDistanceEnabled, double trafficMaxVerticalDistance, bool casEnabled, double casLookaheadTime, double casHorizontalThreshold, double casVerticalThreshold, bool gdl90Enabled, String gdl90BindIp, int gdl90UdpPort, int gdl90TargetExpirySeconds, bool ognEnabled, bool pureTrackEnabled, Set<String> hiddenAircraftIds
});


@override $RangeThresholdsCopyWith<$Res> get flightSpeedThresholds;@override $CannelloniDeviceCopyWith<$Res>? get selectedDevice;@override $RangeThresholdsCopyWith<$Res> get oilTempThresholds;@override $RangeThresholdsCopyWith<$Res> get oilPressureThresholds;@override $RangeThresholdsCopyWith<$Res> get fuelThresholds;@override $RangeThresholdsCopyWith<$Res> get egtThresholds;@override $RangeThresholdsCopyWith<$Res> get chtThresholds;@override $RangeThresholdsCopyWith<$Res> get rpmThresholds;

}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mapFontSize = null,Object? showUtcClock = null,Object? sunsetWarningMinutes = null,Object? mapDefaultZoom = null,Object? mapOverviewZoom = null,Object? mapFollowZoom = null,Object? mapFollowPitch = null,Object? flightSpeedThresholds = null,Object? flightSpeedMaxRange = null,Object? courseLineSegmentsCount = null,Object? courseLineSegmentDuration = null,Object? autoSelectDevice = null,Object? selectedDevice = freezed,Object? areWidgetsDraggable = null,Object? widgetPositions = null,Object? speedUnit = null,Object? qnh = null,Object? qfe = null,Object? autoQnh = null,Object? altitudeUnit = null,Object? heightUnit = null,Object? averageSpeed = null,Object? pilotId = freezed,Object? airplaneId = freezed,Object? temperatureUnit = null,Object? oilTempThresholds = null,Object? oilTempMaxRange = null,Object? pressureUnit = null,Object? oilPressureThresholds = null,Object? oilPressureMaxRange = null,Object? fuelThresholds = null,Object? egtThresholds = null,Object? egtMaxRange = null,Object? chtThresholds = null,Object? chtMaxRange = null,Object? rpmThresholds = null,Object? rpmMaxRange = null,Object? trafficFilterMaxHorizontalDistanceEnabled = null,Object? trafficMaxHorizontalDistance = null,Object? trafficFilterMaxVerticalDistanceEnabled = null,Object? trafficMaxVerticalDistance = null,Object? casEnabled = null,Object? casLookaheadTime = null,Object? casHorizontalThreshold = null,Object? casVerticalThreshold = null,Object? gdl90Enabled = null,Object? gdl90BindIp = null,Object? gdl90UdpPort = null,Object? gdl90TargetExpirySeconds = null,Object? ognEnabled = null,Object? pureTrackEnabled = null,Object? hiddenAircraftIds = null,}) {
  return _then(_AppSettings(
mapFontSize: null == mapFontSize ? _self.mapFontSize : mapFontSize // ignore: cast_nullable_to_non_nullable
as double,showUtcClock: null == showUtcClock ? _self.showUtcClock : showUtcClock // ignore: cast_nullable_to_non_nullable
as bool,sunsetWarningMinutes: null == sunsetWarningMinutes ? _self.sunsetWarningMinutes : sunsetWarningMinutes // ignore: cast_nullable_to_non_nullable
as int,mapDefaultZoom: null == mapDefaultZoom ? _self.mapDefaultZoom : mapDefaultZoom // ignore: cast_nullable_to_non_nullable
as double,mapOverviewZoom: null == mapOverviewZoom ? _self.mapOverviewZoom : mapOverviewZoom // ignore: cast_nullable_to_non_nullable
as double,mapFollowZoom: null == mapFollowZoom ? _self.mapFollowZoom : mapFollowZoom // ignore: cast_nullable_to_non_nullable
as double,mapFollowPitch: null == mapFollowPitch ? _self.mapFollowPitch : mapFollowPitch // ignore: cast_nullable_to_non_nullable
as double,flightSpeedThresholds: null == flightSpeedThresholds ? _self.flightSpeedThresholds : flightSpeedThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,flightSpeedMaxRange: null == flightSpeedMaxRange ? _self.flightSpeedMaxRange : flightSpeedMaxRange // ignore: cast_nullable_to_non_nullable
as double,courseLineSegmentsCount: null == courseLineSegmentsCount ? _self.courseLineSegmentsCount : courseLineSegmentsCount // ignore: cast_nullable_to_non_nullable
as int,courseLineSegmentDuration: null == courseLineSegmentDuration ? _self.courseLineSegmentDuration : courseLineSegmentDuration // ignore: cast_nullable_to_non_nullable
as int,autoSelectDevice: null == autoSelectDevice ? _self.autoSelectDevice : autoSelectDevice // ignore: cast_nullable_to_non_nullable
as bool,selectedDevice: freezed == selectedDevice ? _self.selectedDevice : selectedDevice // ignore: cast_nullable_to_non_nullable
as CannelloniDevice?,areWidgetsDraggable: null == areWidgetsDraggable ? _self.areWidgetsDraggable : areWidgetsDraggable // ignore: cast_nullable_to_non_nullable
as bool,widgetPositions: null == widgetPositions ? _self._widgetPositions : widgetPositions // ignore: cast_nullable_to_non_nullable
as Map<String, WidgetPosition>,speedUnit: null == speedUnit ? _self.speedUnit : speedUnit // ignore: cast_nullable_to_non_nullable
as SpeedUnit,qnh: null == qnh ? _self.qnh : qnh // ignore: cast_nullable_to_non_nullable
as double,qfe: null == qfe ? _self.qfe : qfe // ignore: cast_nullable_to_non_nullable
as double,autoQnh: null == autoQnh ? _self.autoQnh : autoQnh // ignore: cast_nullable_to_non_nullable
as bool,altitudeUnit: null == altitudeUnit ? _self.altitudeUnit : altitudeUnit // ignore: cast_nullable_to_non_nullable
as AltitudeUnit,heightUnit: null == heightUnit ? _self.heightUnit : heightUnit // ignore: cast_nullable_to_non_nullable
as AltitudeUnit,averageSpeed: null == averageSpeed ? _self.averageSpeed : averageSpeed // ignore: cast_nullable_to_non_nullable
as double,pilotId: freezed == pilotId ? _self.pilotId : pilotId // ignore: cast_nullable_to_non_nullable
as String?,airplaneId: freezed == airplaneId ? _self.airplaneId : airplaneId // ignore: cast_nullable_to_non_nullable
as String?,temperatureUnit: null == temperatureUnit ? _self.temperatureUnit : temperatureUnit // ignore: cast_nullable_to_non_nullable
as TemperatureUnit,oilTempThresholds: null == oilTempThresholds ? _self.oilTempThresholds : oilTempThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,oilTempMaxRange: null == oilTempMaxRange ? _self.oilTempMaxRange : oilTempMaxRange // ignore: cast_nullable_to_non_nullable
as double,pressureUnit: null == pressureUnit ? _self.pressureUnit : pressureUnit // ignore: cast_nullable_to_non_nullable
as PressureUnit,oilPressureThresholds: null == oilPressureThresholds ? _self.oilPressureThresholds : oilPressureThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,oilPressureMaxRange: null == oilPressureMaxRange ? _self.oilPressureMaxRange : oilPressureMaxRange // ignore: cast_nullable_to_non_nullable
as double,fuelThresholds: null == fuelThresholds ? _self.fuelThresholds : fuelThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,egtThresholds: null == egtThresholds ? _self.egtThresholds : egtThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,egtMaxRange: null == egtMaxRange ? _self.egtMaxRange : egtMaxRange // ignore: cast_nullable_to_non_nullable
as double,chtThresholds: null == chtThresholds ? _self.chtThresholds : chtThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,chtMaxRange: null == chtMaxRange ? _self.chtMaxRange : chtMaxRange // ignore: cast_nullable_to_non_nullable
as double,rpmThresholds: null == rpmThresholds ? _self.rpmThresholds : rpmThresholds // ignore: cast_nullable_to_non_nullable
as RangeThresholds,rpmMaxRange: null == rpmMaxRange ? _self.rpmMaxRange : rpmMaxRange // ignore: cast_nullable_to_non_nullable
as double,trafficFilterMaxHorizontalDistanceEnabled: null == trafficFilterMaxHorizontalDistanceEnabled ? _self.trafficFilterMaxHorizontalDistanceEnabled : trafficFilterMaxHorizontalDistanceEnabled // ignore: cast_nullable_to_non_nullable
as bool,trafficMaxHorizontalDistance: null == trafficMaxHorizontalDistance ? _self.trafficMaxHorizontalDistance : trafficMaxHorizontalDistance // ignore: cast_nullable_to_non_nullable
as double,trafficFilterMaxVerticalDistanceEnabled: null == trafficFilterMaxVerticalDistanceEnabled ? _self.trafficFilterMaxVerticalDistanceEnabled : trafficFilterMaxVerticalDistanceEnabled // ignore: cast_nullable_to_non_nullable
as bool,trafficMaxVerticalDistance: null == trafficMaxVerticalDistance ? _self.trafficMaxVerticalDistance : trafficMaxVerticalDistance // ignore: cast_nullable_to_non_nullable
as double,casEnabled: null == casEnabled ? _self.casEnabled : casEnabled // ignore: cast_nullable_to_non_nullable
as bool,casLookaheadTime: null == casLookaheadTime ? _self.casLookaheadTime : casLookaheadTime // ignore: cast_nullable_to_non_nullable
as double,casHorizontalThreshold: null == casHorizontalThreshold ? _self.casHorizontalThreshold : casHorizontalThreshold // ignore: cast_nullable_to_non_nullable
as double,casVerticalThreshold: null == casVerticalThreshold ? _self.casVerticalThreshold : casVerticalThreshold // ignore: cast_nullable_to_non_nullable
as double,gdl90Enabled: null == gdl90Enabled ? _self.gdl90Enabled : gdl90Enabled // ignore: cast_nullable_to_non_nullable
as bool,gdl90BindIp: null == gdl90BindIp ? _self.gdl90BindIp : gdl90BindIp // ignore: cast_nullable_to_non_nullable
as String,gdl90UdpPort: null == gdl90UdpPort ? _self.gdl90UdpPort : gdl90UdpPort // ignore: cast_nullable_to_non_nullable
as int,gdl90TargetExpirySeconds: null == gdl90TargetExpirySeconds ? _self.gdl90TargetExpirySeconds : gdl90TargetExpirySeconds // ignore: cast_nullable_to_non_nullable
as int,ognEnabled: null == ognEnabled ? _self.ognEnabled : ognEnabled // ignore: cast_nullable_to_non_nullable
as bool,pureTrackEnabled: null == pureTrackEnabled ? _self.pureTrackEnabled : pureTrackEnabled // ignore: cast_nullable_to_non_nullable
as bool,hiddenAircraftIds: null == hiddenAircraftIds ? _self._hiddenAircraftIds : hiddenAircraftIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
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
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get oilTempThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.oilTempThresholds, (value) {
    return _then(_self.copyWith(oilTempThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get oilPressureThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.oilPressureThresholds, (value) {
    return _then(_self.copyWith(oilPressureThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get fuelThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.fuelThresholds, (value) {
    return _then(_self.copyWith(fuelThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get egtThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.egtThresholds, (value) {
    return _then(_self.copyWith(egtThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get chtThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.chtThresholds, (value) {
    return _then(_self.copyWith(chtThresholds: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RangeThresholdsCopyWith<$Res> get rpmThresholds {
  
  return $RangeThresholdsCopyWith<$Res>(_self.rpmThresholds, (value) {
    return _then(_self.copyWith(rpmThresholds: value));
  });
}
}

// dart format on
