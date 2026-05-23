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
          inactiveMax: 10.0,
          minError: 60.0,
          minWarning: 75.0,
          maxWarning: 110.0,
          maxError: 125.0,
        )
      : RangeThresholds.fromJson(
          json['flightSpeedThresholds'] as Map<String, dynamic>,
        ),
  flightSpeedMaxRange:
      (json['flightSpeedMaxRange'] as num?)?.toDouble() ?? 140.0,
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
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'mapFontSize': instance.mapFontSize,
      'mapDefaultZoom': instance.mapDefaultZoom,
      'mapOverviewZoom': instance.mapOverviewZoom,
      'mapFollowZoom': instance.mapFollowZoom,
      'flightSpeedThresholds': instance.flightSpeedThresholds,
      'flightSpeedMaxRange': instance.flightSpeedMaxRange,
      'autoSelectDevice': instance.autoSelectDevice,
      'selectedDevice': instance.selectedDevice,
      'areWidgetsDraggable': instance.areWidgetsDraggable,
      'widgetPositions': instance.widgetPositions,
    };
