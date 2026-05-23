import 'package:freezed_annotation/freezed_annotation.dart';
import 'cannelloni_device.dart';
import 'range_thresholds.dart';
import 'widget_position.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(1.0) double mapFontSize,
    @Default(6.0) double mapDefaultZoom,
    @Default(10.0) double mapOverviewZoom,
    @Default(12.0) double mapFollowZoom,
    @Default(RangeThresholds.raw(
      inactiveMax: 10.0,
      minError: 60.0,
      minWarning: 75.0,
      maxWarning: 110.0,
      maxError: 125.0,
    )) RangeThresholds flightSpeedThresholds,
    @Default(140.0) double flightSpeedMaxRange,
    @Default(5) int courseLineSegmentsCount,
    @Default(60) int courseLineSegmentDuration,
    @Default(true) bool autoSelectDevice,
    CannelloniDevice? selectedDevice,
    @Default(false) bool areWidgetsDraggable,
    @Default({}) Map<String, WidgetPosition> widgetPositions,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
