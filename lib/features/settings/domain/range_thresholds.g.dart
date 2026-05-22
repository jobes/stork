// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'range_thresholds.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RangeThresholds _$RangeThresholdsFromJson(Map<String, dynamic> json) =>
    _RangeThresholds(
      inactiveMax: (json['inactiveMax'] as num?)?.toDouble(),
      minError: (json['minError'] as num?)?.toDouble(),
      minWarning: (json['minWarning'] as num?)?.toDouble(),
      maxWarning: (json['maxWarning'] as num?)?.toDouble(),
      maxError: (json['maxError'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RangeThresholdsToJson(_RangeThresholds instance) =>
    <String, dynamic>{
      'inactiveMax': instance.inactiveMax,
      'minError': instance.minError,
      'minWarning': instance.minWarning,
      'maxWarning': instance.maxWarning,
      'maxError': instance.maxError,
    };
