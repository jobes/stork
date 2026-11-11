import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/cannelloni_service.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/telemetry_instrument.dart';
import 'telemetry_provider.dart';

part 'instrument_status_provider.g.dart';

/// The same instrument state drives its card and the map status indicator.
/// The dialog also reads the individual measurements behind the alert.
@riverpod
InstrumentStatus instrumentStatus(Ref ref, TelemetryInstrument instrument) {
  final supported = ref.watch(telemetryProvider.select(instrument.isSupported));
  if (instrument == TelemetryInstrument.radio) {
    final radio = ref.watch(
      telemetryProvider.select(
        (t) => (frequency: t.radioActiveFrequency, flags: t.radioFlags ?? 0),
      ),
    );
    final unavailable = radio.frequency == null;
    final failed = unavailable || (radio.flags & 8) != 0;
    return (
      supported: supported,
      cardState: failed ? ThresholdState.maxError : ThresholdState.operational,
      issue: failed
          ? (
              state: ThresholdState.maxError,
              unavailable: unavailable,
              channel: null,
            )
          : null,
      alertReadings: const [],
    );
  }

  final thresholds = ref.watch(
    appSettingsProvider.select(
      (settings) => instrument.thresholds(settings.value),
    ),
  );
  final channels = switch (instrument) {
    TelemetryInstrument.cylinderTemperature => ref.watch(
      telemetryProvider.select((t) => t.cylinderHeadTemperatures),
    ),
    TelemetryInstrument.exhaustTemperature => ref.watch(
      telemetryProvider.select((t) => t.exhaustGasTemperatures),
    ),
    _ => null,
  };

  if (channels != null) {
    InstrumentIssue? worst;
    final alertReadings = <InstrumentAlertReading>[];
    var cardState = ThresholdState.inactive;
    for (final (index, value) in channels.indexed) {
      final state = value == null
          ? ThresholdState.maxError
          : thresholds.evaluate(value);
      if (index == 0) cardState = state;
      final issue = _issue(state, value, channel: index + 1);
      if (issue == null) continue;
      alertReadings.add(_alertReading(issue, value, thresholds));
      if (worst == null || _priority(issue) > _priority(worst)) {
        worst = issue;
        cardState = issue.state;
      }
    }
    alertReadings.sort((a, b) {
      final severity = _priority(b.issue).compareTo(_priority(a.issue));
      return severity != 0
          ? severity
          : a.issue.channel!.compareTo(b.issue.channel!);
    });
    return (
      supported: supported,
      cardState: cardState,
      issue: worst,
      alertReadings: List.unmodifiable(alertReadings),
    );
  }

  final value = ref.watch(
    telemetryProvider.select(
      (t) => switch (instrument) {
        TelemetryInstrument.speed => t.groundSpeed,
        TelemetryInstrument.oilTemperature => t.oilTemperature,
        TelemetryInstrument.oilPressure => t.oilPressure,
        TelemetryInstrument.fuel => t.fuelLevelPercent,
        TelemetryInstrument.rpm => t.engineRPM?.toDouble(),
        _ => null,
      },
    ),
  );
  final airspeed = instrument == TelemetryInstrument.speed
      ? ref.watch(telemetryProvider.select((t) => t.indicatedAirSpeed))
      : null;
  final reading = airspeed != null && ref.watch(cannelloniServiceProvider)
      ? airspeed
      : value;
  final cardState = reading != null
      ? thresholds.evaluate(reading)
      : switch (instrument) {
          TelemetryInstrument.speed => ThresholdState.inactive,
          TelemetryInstrument.fuel => ThresholdState.minError,
          _ => ThresholdState.maxError,
        };
  final issue = _issue(cardState, reading);
  return (
    supported: supported,
    cardState: cardState,
    issue: issue,
    alertReadings: issue == null
        ? const []
        : List.unmodifiable([_alertReading(issue, reading, thresholds)]),
  );
}

InstrumentAlertReading _alertReading(
  InstrumentIssue issue,
  double? value,
  RangeThresholds thresholds,
) {
  final limit = value == null
      ? null
      : switch (issue.state) {
          ThresholdState.minWarning => thresholds.minWarning,
          ThresholdState.maxWarning => thresholds.maxWarning,
          ThresholdState.minError => thresholds.minError,
          ThresholdState.maxError => thresholds.maxError,
          _ => null,
        };
  return (issue: issue, value: value, limit: limit);
}

InstrumentIssue? _issue(ThresholdState state, double? reading, {int? channel}) {
  return switch (state) {
    ThresholdState.inactive || ThresholdState.operational => null,
    _ => (state: state, unavailable: reading == null, channel: channel),
  };
}

int _priority(InstrumentIssue issue) => switch (issue.state) {
  ThresholdState.maxError when !issue.unavailable => 4,
  ThresholdState.minError when !issue.unavailable => 3,
  ThresholdState.minError || ThresholdState.maxError => 2,
  _ => 1,
};
