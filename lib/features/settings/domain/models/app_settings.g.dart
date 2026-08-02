// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  mapFontSize: (json['mapFontSize'] as num?)?.toDouble() ?? 1.0,
  mapDefaultZoom: (json['mapDefaultZoom'] as num?)?.toDouble() ?? 6.0,
  mapOverviewZoom: (json['mapOverviewZoom'] as num?)?.toDouble() ?? 10.0,
  mapFollowZoom: (json['mapFollowZoom'] as num?)?.toDouble() ?? 12.0,
  flightSpeedThresholds: json['flightSpeedThresholds'] == null
      ? const RangeThresholds.raw(
          inactiveMax: 2.77,
          minError: 16.67,
          minWarning: 20.83,
          maxWarning: 30.56,
          maxError: 34.72,
        )
      : RangeThresholds.fromJson(
          json['flightSpeedThresholds'] as Map<String, dynamic>,
        ),
  flightSpeedMaxRange:
      (json['flightSpeedMaxRange'] as num?)?.toDouble() ?? 38.89,
  courseLineSegmentsCount:
      (json['courseLineSegmentsCount'] as num?)?.toInt() ?? 5,
  courseLineSegmentDuration:
      (json['courseLineSegmentDuration'] as num?)?.toInt() ?? 60,
  autoSelectDevice: json['autoSelectDevice'] as bool? ?? true,
  selectedDevice: json['selectedDevice'] == null
      ? null
      : CannelloniDevice.fromJson(
          json['selectedDevice'] as Map<String, dynamic>,
        ),
  areWidgetsDraggable: json['areWidgetsDraggable'] as bool? ?? false,
  widgetPositions:
      (json['widgetPositions'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, WidgetPosition.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  speedUnit:
      $enumDecodeNullable(_$SpeedUnitEnumMap, json['speedUnit']) ??
      SpeedUnit.kmh,
  qnh: (json['qnh'] as num?)?.toDouble() ?? 1013.25,
  qfe: (json['qfe'] as num?)?.toDouble() ?? 1013.25,
  autoQnh: json['autoQnh'] as bool? ?? true,
  altitudeUnit:
      $enumDecodeNullable(_$AltitudeUnitEnumMap, json['altitudeUnit']) ??
      AltitudeUnit.feet,
  heightUnit:
      $enumDecodeNullable(_$AltitudeUnitEnumMap, json['heightUnit']) ??
      AltitudeUnit.meters,
  averageSpeed: (json['averageSpeed'] as num?)?.toDouble() ?? 27.78,
  pilotId: json['pilotId'] as String?,
  airplaneId: json['airplaneId'] as String?,
  temperatureUnit:
      $enumDecodeNullable(_$TemperatureUnitEnumMap, json['temperatureUnit']) ??
      TemperatureUnit.celsius,
  oilTempThresholds: json['oilTempThresholds'] == null
      ? const RangeThresholds.raw(
          inactiveMax: 303.15,
          minError: 323.15,
          minWarning: 333.15,
          maxWarning: 383.15,
          maxError: 403.15,
        )
      : RangeThresholds.fromJson(
          json['oilTempThresholds'] as Map<String, dynamic>,
        ),
  oilTempMaxRange: (json['oilTempMaxRange'] as num?)?.toDouble() ?? 413.15,
  pressureUnit:
      $enumDecodeNullable(_$PressureUnitEnumMap, json['pressureUnit']) ??
      PressureUnit.bar,
  oilPressureThresholds: json['oilPressureThresholds'] == null
      ? const RangeThresholds.raw(
          inactiveMax: 50.0,
          minError: 80.0,
          minWarning: 200.0,
          maxWarning: 500.0,
          maxError: 700.0,
        )
      : RangeThresholds.fromJson(
          json['oilPressureThresholds'] as Map<String, dynamic>,
        ),
  oilPressureMaxRange:
      (json['oilPressureMaxRange'] as num?)?.toDouble() ?? 800.0,
  fuelThresholds: json['fuelThresholds'] == null
      ? const RangeThresholds.raw(minError: 10.0, minWarning: 20.0)
      : RangeThresholds.fromJson(
          json['fuelThresholds'] as Map<String, dynamic>,
        ),
  egtThresholds: json['egtThresholds'] == null
      ? const RangeThresholds.raw(
          inactiveMax: 423.15,
          minError: 773.15,
          minWarning: 973.15,
          maxWarning: 1153.15,
          maxError: 1173.15,
        )
      : RangeThresholds.fromJson(json['egtThresholds'] as Map<String, dynamic>),
  egtMaxRange: (json['egtMaxRange'] as num?)?.toDouble() ?? 1223.15,
  chtThresholds: json['chtThresholds'] == null
      ? const RangeThresholds.raw(
          inactiveMax: 323.15,
          minError: 333.15,
          minWarning: 348.15,
          maxWarning: 403.15,
          maxError: 423.15,
        )
      : RangeThresholds.fromJson(json['chtThresholds'] as Map<String, dynamic>),
  chtMaxRange: (json['chtMaxRange'] as num?)?.toDouble() ?? 433.15,
  rpmThresholds: json['rpmThresholds'] == null
      ? const RangeThresholds.raw(
          inactiveMax: 10.0,
          minError: 1400.0,
          minWarning: 1800.0,
          maxWarning: 5500.0,
          maxError: 5800.0,
        )
      : RangeThresholds.fromJson(json['rpmThresholds'] as Map<String, dynamic>),
  rpmMaxRange: (json['rpmMaxRange'] as num?)?.toDouble() ?? 6000.0,
  trafficFilterMaxHorizontalDistanceEnabled:
      json['trafficFilterMaxHorizontalDistanceEnabled'] as bool? ?? true,
  trafficMaxHorizontalDistance:
      (json['trafficMaxHorizontalDistance'] as num?)?.toDouble() ?? 50000.0,
  trafficFilterMaxVerticalDistanceEnabled:
      json['trafficFilterMaxVerticalDistanceEnabled'] as bool? ?? true,
  trafficMaxVerticalDistance:
      (json['trafficMaxVerticalDistance'] as num?)?.toDouble() ?? 1500.0,
  casEnabled: json['casEnabled'] as bool? ?? true,
  casLookaheadTime: (json['casLookaheadTime'] as num?)?.toDouble() ?? 30.0,
  casHorizontalThreshold:
      (json['casHorizontalThreshold'] as num?)?.toDouble() ?? 300.0,
  casVerticalThreshold:
      (json['casVerticalThreshold'] as num?)?.toDouble() ?? 100.0,
  gdl90Enabled: json['gdl90Enabled'] as bool? ?? true,
  gdl90BindIp: json['gdl90BindIp'] as String? ?? '0.0.0.0',
  gdl90UdpPort: (json['gdl90UdpPort'] as num?)?.toInt() ?? 4000,
  gdl90TargetExpirySeconds:
      (json['gdl90TargetExpirySeconds'] as num?)?.toInt() ?? 60,
  ognEnabled: json['ognEnabled'] as bool? ?? true,
  pureTrackEnabled: json['pureTrackEnabled'] as bool? ?? true,
  hiddenAircraftIds:
      (json['hiddenAircraftIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const {},
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'mapFontSize': instance.mapFontSize,
      'mapDefaultZoom': instance.mapDefaultZoom,
      'mapOverviewZoom': instance.mapOverviewZoom,
      'mapFollowZoom': instance.mapFollowZoom,
      'flightSpeedThresholds': instance.flightSpeedThresholds,
      'flightSpeedMaxRange': instance.flightSpeedMaxRange,
      'courseLineSegmentsCount': instance.courseLineSegmentsCount,
      'courseLineSegmentDuration': instance.courseLineSegmentDuration,
      'autoSelectDevice': instance.autoSelectDevice,
      'selectedDevice': instance.selectedDevice,
      'areWidgetsDraggable': instance.areWidgetsDraggable,
      'widgetPositions': instance.widgetPositions,
      'speedUnit': _$SpeedUnitEnumMap[instance.speedUnit]!,
      'qnh': instance.qnh,
      'qfe': instance.qfe,
      'autoQnh': instance.autoQnh,
      'altitudeUnit': _$AltitudeUnitEnumMap[instance.altitudeUnit]!,
      'heightUnit': _$AltitudeUnitEnumMap[instance.heightUnit]!,
      'averageSpeed': instance.averageSpeed,
      'pilotId': instance.pilotId,
      'airplaneId': instance.airplaneId,
      'temperatureUnit': _$TemperatureUnitEnumMap[instance.temperatureUnit]!,
      'oilTempThresholds': instance.oilTempThresholds,
      'oilTempMaxRange': instance.oilTempMaxRange,
      'pressureUnit': _$PressureUnitEnumMap[instance.pressureUnit]!,
      'oilPressureThresholds': instance.oilPressureThresholds,
      'oilPressureMaxRange': instance.oilPressureMaxRange,
      'fuelThresholds': instance.fuelThresholds,
      'egtThresholds': instance.egtThresholds,
      'egtMaxRange': instance.egtMaxRange,
      'chtThresholds': instance.chtThresholds,
      'chtMaxRange': instance.chtMaxRange,
      'rpmThresholds': instance.rpmThresholds,
      'rpmMaxRange': instance.rpmMaxRange,
      'trafficFilterMaxHorizontalDistanceEnabled':
          instance.trafficFilterMaxHorizontalDistanceEnabled,
      'trafficMaxHorizontalDistance': instance.trafficMaxHorizontalDistance,
      'trafficFilterMaxVerticalDistanceEnabled':
          instance.trafficFilterMaxVerticalDistanceEnabled,
      'trafficMaxVerticalDistance': instance.trafficMaxVerticalDistance,
      'casEnabled': instance.casEnabled,
      'casLookaheadTime': instance.casLookaheadTime,
      'casHorizontalThreshold': instance.casHorizontalThreshold,
      'casVerticalThreshold': instance.casVerticalThreshold,
      'gdl90Enabled': instance.gdl90Enabled,
      'gdl90BindIp': instance.gdl90BindIp,
      'gdl90UdpPort': instance.gdl90UdpPort,
      'gdl90TargetExpirySeconds': instance.gdl90TargetExpirySeconds,
      'ognEnabled': instance.ognEnabled,
      'pureTrackEnabled': instance.pureTrackEnabled,
      'hiddenAircraftIds': instance.hiddenAircraftIds.toList(),
    };

const _$SpeedUnitEnumMap = {
  SpeedUnit.ms: 'ms',
  SpeedUnit.kmh: 'kmh',
  SpeedUnit.mph: 'mph',
  SpeedUnit.knots: 'knots',
};

const _$AltitudeUnitEnumMap = {
  AltitudeUnit.meters: 'meters',
  AltitudeUnit.feet: 'feet',
  AltitudeUnit.flightLevel: 'flightLevel',
};

const _$TemperatureUnitEnumMap = {
  TemperatureUnit.celsius: 'celsius',
  TemperatureUnit.kelvin: 'kelvin',
  TemperatureUnit.fahrenheit: 'fahrenheit',
};

const _$PressureUnitEnumMap = {
  PressureUnit.bar: 'bar',
  PressureUnit.psi: 'psi',
  PressureUnit.kPa: 'kPa',
};
