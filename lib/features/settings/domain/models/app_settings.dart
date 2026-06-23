import 'package:freezed_annotation/freezed_annotation.dart';
import 'cannelloni_device.dart';
import 'range_thresholds.dart';
import 'widget_position.dart';
import 'speed_unit.dart';
import 'altitude_unit.dart';
import '../../../../../core/utils/aviation_math.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(1.0) double mapFontSize,
    @Default(6.0) double mapDefaultZoom,
    @Default(10.0) double mapOverviewZoom,
    @Default(12.0) double mapFollowZoom,
    @Default(
      RangeThresholds.raw(
        inactiveMax: 2.77,
        minError: 16.67,
        minWarning: 20.83,
        maxWarning: 30.56,
        maxError: 34.72,
      ),
    )
    RangeThresholds flightSpeedThresholds,
    @Default(38.89) double flightSpeedMaxRange,
    @Default(5) int courseLineSegmentsCount,
    @Default(60) int courseLineSegmentDuration,
    @Default(true) bool autoSelectDevice,
    CannelloniDevice? selectedDevice,
    @Default(false) bool areWidgetsDraggable,
    @Default({}) Map<String, WidgetPosition> widgetPositions,
    @Default(SpeedUnit.kmh) SpeedUnit speedUnit,
    @Default(1013.25) double qnh,
    @Default(1013.25) double qfe,
    @Default(true) bool autoQnh,
    @Default(AltitudeUnit.feet) AltitudeUnit altitudeUnit,
    @Default(AltitudeUnit.meters) AltitudeUnit heightUnit,
    @Default(27.78) double averageSpeed,
    String? pilotId,
    String? airplaneId,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  AppSettings copyWithValidatedQnh(double qnhValue) {
    double validatedQnh = qnhValue;
    if (!validatedQnh.isFinite || validatedQnh <= 0.0) {
      validatedQnh = AviationMath.standardPressureHpa;
    } else {
      validatedQnh = validatedQnh.clamp(AviationMath.minQnhHpa, AviationMath.maxQnhHpa);
    }
    return copyWith(qnh: validatedQnh);
  }

  AppSettings copyWithValidatedAverageSpeed(double speedValue) {
    double validatedSpeed = speedValue;
    if (!validatedSpeed.isFinite || validatedSpeed < 0.001) {
      validatedSpeed = 0.001;
    }
    final speedMs = speedUnit.convertToMs(validatedSpeed);
    return copyWith(averageSpeed: speedMs);
  }

  AppSettings copyWithValidatedFlightSpeedMaxRange(
    double maxRange, {
    required double defaultMaxRangeMs,
    required double defaultInactiveMaxMs,
    required double defaultMinErrorMs,
    required double defaultMinWarningMs,
    required double defaultMaxWarningMs,
    required double defaultMaxErrorMs,
    required double minRangeLimit,
    required double maxRangeLimit,
  }) {
    double clampedMaxRangeActive = maxRange;
    if (!clampedMaxRangeActive.isFinite || clampedMaxRangeActive <= 0.0) {
      clampedMaxRangeActive = speedUnit.convertFromMs(defaultMaxRangeMs);
    } else {
      clampedMaxRangeActive = clampedMaxRangeActive.clamp(
        minRangeLimit,
        maxRangeLimit,
      );
    }

    final normalizedMaxRangeMs = speedUnit.convertToMs(clampedMaxRangeActive);

    final thresholds = flightSpeedThresholds;
    final inactiveMaxActive = speedUnit.convertFromMs(
      thresholds.inactiveMax ?? defaultInactiveMaxMs,
    );
    final minErrorActive = speedUnit.convertFromMs(
      thresholds.minError ?? defaultMinErrorMs,
    );
    final minWarningActive = speedUnit.convertFromMs(
      thresholds.minWarning ?? defaultMinWarningMs,
    );
    final maxWarningActive = speedUnit.convertFromMs(
      thresholds.maxWarning ?? defaultMaxWarningMs,
    );
    final maxErrorActive = speedUnit.convertFromMs(
      thresholds.maxError ?? defaultMaxErrorMs,
    );

    final newMaxErrorActive = maxErrorActive
        .clamp(0.0, clampedMaxRangeActive)
        .roundToDouble();
    final newMaxWarningActive = maxWarningActive
        .clamp(0.0, newMaxErrorActive)
        .roundToDouble();
    final newMinWarningActive = minWarningActive
        .clamp(0.0, newMaxWarningActive)
        .roundToDouble();
    final newMinErrorActive = minErrorActive
        .clamp(0.0, newMinWarningActive)
        .roundToDouble();
    final newInactiveMaxActive = inactiveMaxActive
        .clamp(0.0, newMinErrorActive)
        .roundToDouble();

    return copyWith(
      flightSpeedMaxRange: normalizedMaxRangeMs,
      flightSpeedThresholds: thresholds.copyWith(
        inactiveMax: speedUnit.convertToMs(newInactiveMaxActive),
        minError: speedUnit.convertToMs(newMinErrorActive),
        minWarning: speedUnit.convertToMs(newMinWarningActive),
        maxWarning: speedUnit.convertToMs(newMaxWarningActive),
        maxError: speedUnit.convertToMs(newMaxErrorActive),
      ),
    );
  }
}
