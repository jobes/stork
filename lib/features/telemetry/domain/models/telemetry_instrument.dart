import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import 'telemetry_state.dart';

enum TelemetryInstrument {
  speed,
  oilTemperature,
  oilPressure,
  cylinderTemperature,
  exhaustTemperature,
  fuel,
  rpm,
  radio;

  bool isSupported(TelemetryState telemetry) => switch (this) {
    speed => true,
    oilTemperature => telemetry.isOilTempSupported,
    oilPressure => telemetry.isOilPressureSupported,
    cylinderTemperature => telemetry.isChtSupported,
    exhaustTemperature => telemetry.isEgtSupported,
    fuel => telemetry.isFuelSupported,
    rpm => telemetry.isEngineRpmSupported,
    radio => telemetry.isRadioSupported,
  };

  RangeThresholds thresholds(AppSettings? settings) {
    final defaults = settings ?? const AppSettings();
    return switch (this) {
      speed => settings?.flightSpeedThresholds ?? const RangeThresholds.raw(),
      oilTemperature => defaults.oilTempThresholds,
      oilPressure => defaults.oilPressureThresholds,
      cylinderTemperature => defaults.chtThresholds,
      exhaustTemperature => defaults.egtThresholds,
      fuel => defaults.fuelThresholds,
      rpm => defaults.rpmThresholds,
      radio => const RangeThresholds.raw(),
    };
  }
}

typedef InstrumentIssue = ({
  ThresholdState state,
  bool unavailable,
  int? channel,
});

typedef InstrumentStatus = ({
  bool supported,
  ThresholdState cardState,
  InstrumentIssue? issue,
  List<InstrumentAlertReading> alertReadings,
});

typedef InstrumentAlertReading = ({
  InstrumentIssue issue,
  double? value,
  double? limit,
});
