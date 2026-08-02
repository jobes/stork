import 'package:freezed_annotation/freezed_annotation.dart';
import 'cannelloni_device.dart';
import 'range_thresholds.dart';
import 'widget_position.dart';
import 'speed_unit.dart';
import 'altitude_unit.dart';
import 'temperature_unit.dart';
import 'pressure_unit.dart';
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
    @Default(TemperatureUnit.celsius) TemperatureUnit temperatureUnit,
    @Default(
      RangeThresholds.raw(
        inactiveMax: 303.15, // 30 °C
        minError: 323.15, // 50 °C
        minWarning: 333.15, // 60 °C
        maxWarning: 383.15, // 110 °C
        maxError: 403.15, // 130 °C
      ),
    )
    RangeThresholds oilTempThresholds,
    @Default(413.15) double oilTempMaxRange, // 140 °C
    @Default(PressureUnit.bar) PressureUnit pressureUnit,
    @Default(
      RangeThresholds.raw(
        inactiveMax: 50.0, // 0.5 bar
        minError: 80.0, // 0.8 bar
        minWarning: 200.0, // 2.0 bar
        maxWarning: 500.0, // 5.0 bar
        maxError: 700.0, // 7.0 bar
      ),
    )
    RangeThresholds oilPressureThresholds,
    @Default(800.0) double oilPressureMaxRange, // 8.0 bar
    @Default(RangeThresholds.raw(minError: 10.0, minWarning: 20.0))
    RangeThresholds fuelThresholds,
    @Default(
      RangeThresholds.raw(
        inactiveMax: 423.15, // 150 °C
        minError: 773.15, // 500 °C
        minWarning: 973.15, // 700 °C
        maxWarning: 1153.15, // 880 °C
        maxError: 1173.15, // 900 °C
      ),
    )
    RangeThresholds egtThresholds,
    @Default(1223.15) double egtMaxRange, // 950 °C
    @Default(
      RangeThresholds.raw(
        inactiveMax: 323.15, // 50 °C
        minError: 333.15, // 60 °C
        minWarning: 348.15, // 75 °C
        maxWarning: 403.15, // 130 °C
        maxError: 423.15, // 150 °C
      ),
    )
    RangeThresholds chtThresholds,
    @Default(433.15) double chtMaxRange, // 160 °C
    @Default(
      RangeThresholds.raw(
        inactiveMax: 10.0,
        minError: 1400.0,
        minWarning: 1800.0,
        maxWarning: 5500.0,
        maxError: 5800.0,
      ),
    )
    RangeThresholds rpmThresholds,
    @Default(6000.0) double rpmMaxRange,
    @Default(true) bool trafficFilterMaxHorizontalDistanceEnabled,
    @Default(50000.0) double trafficMaxHorizontalDistance, // meters
    @Default(true) bool trafficFilterMaxVerticalDistanceEnabled,
    @Default(1500.0) double trafficMaxVerticalDistance, // meters
    @Default(true) bool casEnabled,
    @Default(30.0) double casLookaheadTime, // seconds
    @Default(300.0) double casHorizontalThreshold, // meters
    @Default(100.0) double casVerticalThreshold, // meters
    @Default(true) bool gdl90Enabled,
    @Default('0.0.0.0') String gdl90BindIp,
    @Default(4000) int gdl90UdpPort,
    @Default(60) int gdl90TargetExpirySeconds,
    @Default(true) bool ognEnabled,
    @Default(true) bool pureTrackEnabled,
    @Default({}) Set<String> hiddenAircraftIds,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  AppSettings copyWithValidatedQnh(double qnhValue) {
    double validatedQnh = qnhValue;
    if (!validatedQnh.isFinite || validatedQnh <= 0.0) {
      validatedQnh = AviationMath.standardPressureHpa;
    } else {
      validatedQnh = validatedQnh.clamp(
        AviationMath.minQnhHpa,
        AviationMath.maxQnhHpa,
      );
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

  AppSettings copyWithValidatedOilTempMaxRange(
    double maxRange, {
    required double defaultMaxRangeK,
    required double defaultInactiveMaxK,
    required double defaultMinErrorK,
    required double defaultMinWarningK,
    required double defaultMaxWarningK,
    required double defaultMaxErrorK,
    required double minRangeLimit,
    required double maxRangeLimit,
  }) {
    double clampedMaxRangeActive = maxRange;
    if (!clampedMaxRangeActive.isFinite || clampedMaxRangeActive <= 0.0) {
      clampedMaxRangeActive = temperatureUnit.convertFromKelvin(
        defaultMaxRangeK,
      );
    } else {
      clampedMaxRangeActive = clampedMaxRangeActive.clamp(
        minRangeLimit,
        maxRangeLimit,
      );
    }

    final normalizedMaxRangeK = temperatureUnit.convertToKelvin(
      clampedMaxRangeActive,
    );

    final thresholds = oilTempThresholds;
    final inactiveMaxActive = temperatureUnit.convertFromKelvin(
      thresholds.inactiveMax ?? defaultInactiveMaxK,
    );
    final minErrorActive = temperatureUnit.convertFromKelvin(
      thresholds.minError ?? defaultMinErrorK,
    );
    final minWarningActive = temperatureUnit.convertFromKelvin(
      thresholds.minWarning ?? defaultMinWarningK,
    );
    final maxWarningActive = temperatureUnit.convertFromKelvin(
      thresholds.maxWarning ?? defaultMaxWarningK,
    );
    final maxErrorActive = temperatureUnit.convertFromKelvin(
      thresholds.maxError ?? defaultMaxErrorK,
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
      oilTempMaxRange: normalizedMaxRangeK,
      oilTempThresholds: thresholds.copyWith(
        inactiveMax: temperatureUnit.convertToKelvin(newInactiveMaxActive),
        minError: temperatureUnit.convertToKelvin(newMinErrorActive),
        minWarning: temperatureUnit.convertToKelvin(newMinWarningActive),
        maxWarning: temperatureUnit.convertToKelvin(newMaxWarningActive),
        maxError: temperatureUnit.convertToKelvin(newMaxErrorActive),
      ),
    );
  }

  AppSettings copyWithValidatedOilPressureMaxRange(
    double maxRange, {
    required double defaultMaxRangeKpa,
    required double defaultInactiveMaxKpa,
    required double defaultMinErrorKpa,
    required double defaultMinWarningKpa,
    required double defaultMaxWarningKpa,
    required double defaultMaxErrorKpa,
    required double minRangeLimit,
    required double maxRangeLimit,
  }) {
    double clampedMaxRangeActive = maxRange;
    if (!clampedMaxRangeActive.isFinite || clampedMaxRangeActive <= 0.0) {
      clampedMaxRangeActive = pressureUnit.convertFromKpa(defaultMaxRangeKpa);
    } else {
      clampedMaxRangeActive = clampedMaxRangeActive.clamp(
        minRangeLimit,
        maxRangeLimit,
      );
    }

    final normalizedMaxRangeKpa = pressureUnit.convertToKpa(
      clampedMaxRangeActive,
    );

    final thresholds = oilPressureThresholds;
    final inactiveMaxActive = pressureUnit.convertFromKpa(
      thresholds.inactiveMax ?? defaultInactiveMaxKpa,
    );
    final minErrorActive = pressureUnit.convertFromKpa(
      thresholds.minError ?? defaultMinErrorKpa,
    );
    final minWarningActive = pressureUnit.convertFromKpa(
      thresholds.minWarning ?? defaultMinWarningKpa,
    );
    final maxWarningActive = pressureUnit.convertFromKpa(
      thresholds.maxWarning ?? defaultMaxWarningKpa,
    );
    final maxErrorActive = pressureUnit.convertFromKpa(
      thresholds.maxError ?? defaultMaxErrorKpa,
    );

    final decimalPlaces = pressureUnit == PressureUnit.bar ? 1 : 0;
    double roundValue(double val, double maxLimit) {
      final clamped = val.clamp(0.0, maxLimit);
      if (decimalPlaces > 0) {
        return double.parse(clamped.toStringAsFixed(decimalPlaces));
      } else {
        return clamped.roundToDouble();
      }
    }

    final newMaxErrorActive = roundValue(maxErrorActive, clampedMaxRangeActive);
    final newMaxWarningActive = roundValue(maxWarningActive, newMaxErrorActive);
    final newMinWarningActive = roundValue(
      minWarningActive,
      newMaxWarningActive,
    );
    final newMinErrorActive = roundValue(minErrorActive, newMinWarningActive);
    final newInactiveMaxActive = roundValue(
      inactiveMaxActive,
      newMinErrorActive,
    );

    return copyWith(
      oilPressureMaxRange: normalizedMaxRangeKpa,
      oilPressureThresholds: thresholds.copyWith(
        inactiveMax: pressureUnit.convertToKpa(newInactiveMaxActive),
        minError: pressureUnit.convertToKpa(newMinErrorActive),
        minWarning: pressureUnit.convertToKpa(newMinWarningActive),
        maxWarning: pressureUnit.convertToKpa(newMaxWarningActive),
        maxError: pressureUnit.convertToKpa(newMaxErrorActive),
      ),
    );
  }

  AppSettings copyWithValidatedEgtMaxRange(
    double maxRange, {
    required double defaultMaxRangeK,
    required double defaultInactiveMaxK,
    required double defaultMinErrorK,
    required double defaultMinWarningK,
    required double defaultMaxWarningK,
    required double defaultMaxErrorK,
    required double minRangeLimit,
    required double maxRangeLimit,
  }) {
    double clampedMaxRangeActive = maxRange;
    if (!clampedMaxRangeActive.isFinite || clampedMaxRangeActive <= 0.0) {
      clampedMaxRangeActive = temperatureUnit.convertFromKelvin(
        defaultMaxRangeK,
      );
    } else {
      clampedMaxRangeActive = clampedMaxRangeActive.clamp(
        minRangeLimit,
        maxRangeLimit,
      );
    }

    final normalizedMaxRangeK = temperatureUnit.convertToKelvin(
      clampedMaxRangeActive,
    );

    final thresholds = egtThresholds;
    final inactiveMaxActive = temperatureUnit.convertFromKelvin(
      thresholds.inactiveMax ?? defaultInactiveMaxK,
    );
    final minErrorActive = temperatureUnit.convertFromKelvin(
      thresholds.minError ?? defaultMinErrorK,
    );
    final minWarningActive = temperatureUnit.convertFromKelvin(
      thresholds.minWarning ?? defaultMinWarningK,
    );
    final maxWarningActive = temperatureUnit.convertFromKelvin(
      thresholds.maxWarning ?? defaultMaxWarningK,
    );
    final maxErrorActive = temperatureUnit.convertFromKelvin(
      thresholds.maxError ?? defaultMaxErrorK,
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
      egtMaxRange: normalizedMaxRangeK,
      egtThresholds: thresholds.copyWith(
        inactiveMax: temperatureUnit.convertToKelvin(newInactiveMaxActive),
        minError: temperatureUnit.convertToKelvin(newMinErrorActive),
        minWarning: temperatureUnit.convertToKelvin(newMinWarningActive),
        maxWarning: temperatureUnit.convertToKelvin(newMaxWarningActive),
        maxError: temperatureUnit.convertToKelvin(newMaxErrorActive),
      ),
    );
  }

  AppSettings copyWithValidatedChtMaxRange(
    double maxRange, {
    required double defaultMaxRangeK,
    required double defaultInactiveMaxK,
    required double defaultMinErrorK,
    required double defaultMinWarningK,
    required double defaultMaxWarningK,
    required double defaultMaxErrorK,
    required double minRangeLimit,
    required double maxRangeLimit,
  }) {
    double clampedMaxRangeActive = maxRange;
    if (!clampedMaxRangeActive.isFinite || clampedMaxRangeActive <= 0.0) {
      clampedMaxRangeActive = temperatureUnit.convertFromKelvin(
        defaultMaxRangeK,
      );
    } else {
      clampedMaxRangeActive = clampedMaxRangeActive.clamp(
        minRangeLimit,
        maxRangeLimit,
      );
    }

    final normalizedMaxRangeK = temperatureUnit.convertToKelvin(
      clampedMaxRangeActive,
    );

    final thresholds = chtThresholds;
    final inactiveMaxActive = temperatureUnit.convertFromKelvin(
      thresholds.inactiveMax ?? defaultInactiveMaxK,
    );
    final minErrorActive = temperatureUnit.convertFromKelvin(
      thresholds.minError ?? defaultMinErrorK,
    );
    final minWarningActive = temperatureUnit.convertFromKelvin(
      thresholds.minWarning ?? defaultMinWarningK,
    );
    final maxWarningActive = temperatureUnit.convertFromKelvin(
      thresholds.maxWarning ?? defaultMaxWarningK,
    );
    final maxErrorActive = temperatureUnit.convertFromKelvin(
      thresholds.maxError ?? defaultMaxErrorK,
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
      chtMaxRange: normalizedMaxRangeK,
      chtThresholds: thresholds.copyWith(
        inactiveMax: temperatureUnit.convertToKelvin(newInactiveMaxActive),
        minError: temperatureUnit.convertToKelvin(newMinErrorActive),
        minWarning: temperatureUnit.convertToKelvin(newMinWarningActive),
        maxWarning: temperatureUnit.convertToKelvin(newMaxWarningActive),
        maxError: temperatureUnit.convertToKelvin(newMaxErrorActive),
      ),
    );
  }

  AppSettings copyWithValidatedRpmMaxRange(
    double maxRange, {
    required double defaultMaxRange,
    required double defaultInactiveMax,
    required double defaultMinError,
    required double defaultMinWarning,
    required double defaultMaxWarning,
    required double defaultMaxError,
    required double minRangeLimit,
    required double maxRangeLimit,
  }) {
    double clampedMaxRangeActive = maxRange;
    if (!clampedMaxRangeActive.isFinite || clampedMaxRangeActive <= 0.0) {
      clampedMaxRangeActive = defaultMaxRange;
    } else {
      clampedMaxRangeActive = clampedMaxRangeActive.clamp(
        minRangeLimit,
        maxRangeLimit,
      );
    }

    final thresholds = rpmThresholds;
    final inactiveMaxActive = thresholds.inactiveMax ?? defaultInactiveMax;
    final minErrorActive = thresholds.minError ?? defaultMinError;
    final minWarningActive = thresholds.minWarning ?? defaultMinWarning;
    final maxWarningActive = thresholds.maxWarning ?? defaultMaxWarning;
    final maxErrorActive = thresholds.maxError ?? defaultMaxError;

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
      rpmMaxRange: clampedMaxRangeActive,
      rpmThresholds: thresholds.copyWith(
        inactiveMax: newInactiveMaxActive,
        minError: newMinErrorActive,
        minWarning: newMinWarningActive,
        maxWarning: newMaxWarningActive,
        maxError: newMaxErrorActive,
      ),
    );
  }
}
