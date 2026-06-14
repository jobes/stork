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
