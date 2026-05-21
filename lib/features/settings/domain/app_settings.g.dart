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
  flightMinSpeed: (json['flightMinSpeed'] as num?)?.toDouble() ?? 15.0,
  autoSelectDevice: json['autoSelectDevice'] as bool? ?? true,
  selectedDevice: json['selectedDevice'] == null
      ? null
      : CannelloniDevice.fromJson(
          json['selectedDevice'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'mapFontSize': instance.mapFontSize,
      'mapDefaultZoom': instance.mapDefaultZoom,
      'mapOverviewZoom': instance.mapOverviewZoom,
      'mapFollowZoom': instance.mapFollowZoom,
      'flightMinSpeed': instance.flightMinSpeed,
      'autoSelectDevice': instance.autoSelectDevice,
      'selectedDevice': instance.selectedDevice,
    };
