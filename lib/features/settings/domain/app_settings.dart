import 'package:freezed_annotation/freezed_annotation.dart';
import 'cannelloni_device.dart';
import 'range_thresholds.dart';
import 'widget_position.dart';
import 'speed_unit.dart';

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
      inactiveMax: 2.77,
      minError: 16.67,
      minWarning: 20.83,
      maxWarning: 30.56,
      maxError: 34.72,
    )) RangeThresholds flightSpeedThresholds,
    @Default(38.89) double flightSpeedMaxRange,
    @Default(5) int courseLineSegmentsCount,
    @Default(60) int courseLineSegmentDuration,
    @Default(true) bool autoSelectDevice,
    CannelloniDevice? selectedDevice,
    @Default(false) bool areWidgetsDraggable,
    @Default({}) Map<String, WidgetPosition> widgetPositions,
    @Default(SpeedUnit.kmh) SpeedUnit speedUnit,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
