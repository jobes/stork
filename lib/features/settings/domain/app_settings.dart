import 'package:freezed_annotation/freezed_annotation.dart';
import 'cannelloni_device.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(1.0) double mapFontSize,
    @Default(6.0) double mapDefaultZoom,
    @Default(10.0) double mapOverviewZoom,
    @Default(12.0) double mapFollowZoom,
    @Default(15.0) double flightMinSpeed,
    @Default(true) bool autoSelectDevice,
    CannelloniDevice? selectedDevice,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
