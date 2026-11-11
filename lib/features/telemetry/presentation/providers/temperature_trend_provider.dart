import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/telemetry_instrument.dart';
import 'telemetry_provider.dart';

typedef TemperatureSensor = ({TelemetryInstrument instrument, int? channel});
typedef _Sample = ({DateTime time, double kelvin});

final temperatureTrendProvider =
    NotifierProvider<TemperatureTrend, Map<TemperatureSensor, double>>(
      TemperatureTrend.new,
    );

/// Thirty-second temperature changes, in kelvin, sampled by the map ticker.
class TemperatureTrend extends Notifier<Map<TemperatureSensor, double>> {
  static const _window = Duration(seconds: 30);
  static const _interval = Duration(seconds: 1);
  static const _maxGap = Duration(seconds: 3);

  final _samples = <TemperatureSensor, Queue<_Sample>>{};
  DateTime? _lastSample;

  @override
  Map<TemperatureSensor, double> build() => const {};

  void sample(DateTime now, TelemetryState telemetry) {
    final readings = <TemperatureSensor, double>{
      if (telemetry.isOilTempSupported)
        (instrument: TelemetryInstrument.oilTemperature, channel: null):
            ?telemetry.oilTemperature,
      if (telemetry.isChtSupported)
        for (final (index, value) in telemetry.cylinderHeadTemperatures.indexed)
          (
            instrument: TelemetryInstrument.cylinderTemperature,
            channel: index + 1,
          ): ?value,
      if (telemetry.isEgtSupported)
        for (final (index, value) in telemetry.exhaustGasTemperatures.indexed)
          (
            instrument: TelemetryInstrument.exhaustTemperature,
            channel: index + 1,
          ): ?value,
    }..removeWhere((_, value) => !value.isFinite);
    _samples.removeWhere((sensor, _) => !readings.containsKey(sensor));

    final last = _lastSample;
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed.isNegative || elapsed > _maxGap) {
        _samples.clear();
      } else if (elapsed < _interval) {
        if (state.keys.any((sensor) => !readings.containsKey(sensor))) {
          state = Map.unmodifiable(
            Map.of(state)
              ..removeWhere((sensor, _) => !readings.containsKey(sensor)),
          );
        }
        return;
      }
    }
    _lastSample = now;
    final cutoff = now.subtract(_window);
    final changes = <TemperatureSensor, double>{};

    for (final MapEntry(key: sensor, value: kelvin) in readings.entries) {
      final samples = _samples.putIfAbsent(sensor, Queue.new)
        ..addLast((time: now, kelvin: kelvin));
      while (samples.length > 1 && !samples.elementAt(1).time.isAfter(cutoff)) {
        samples.removeFirst();
      }
      final first = samples.first;
      if (first.time.isAfter(cutoff)) continue;
      final second = samples.elementAt(1);
      final fraction =
          cutoff.difference(first.time).inMicroseconds /
          second.time.difference(first.time).inMicroseconds;
      final baseline = first.kelvin + fraction * (second.kelvin - first.kelvin);
      changes[sensor] = kelvin - baseline;
    }
    if (!mapEquals(state, changes)) state = Map.unmodifiable(changes);
  }
}
