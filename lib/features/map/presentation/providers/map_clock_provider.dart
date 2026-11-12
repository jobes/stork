import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../domain/models/solar_times.dart';

part 'map_clock_provider.g.dart';

@riverpod
class MapClock extends _$MapClock {
  @override
  DateTime build() {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = clock.now().toUtc();
    });
    ref.onDispose(timer.cancel);
    return clock.now().toUtc();
  }
}

@riverpod
({SolarTimes today, SolarTimes tomorrow}) mapSolarTimes(Ref ref) {
  final (latitude, longitude) = ref.watch(
    telemetryProvider.select((state) => (state.latitude, state.longitude)),
  );
  if (latitude == null || longitude == null) {
    return (
      today: const SolarTimes.empty(),
      tomorrow: const SolarTimes.empty(),
    );
  }

  final (today, tomorrow, dayAfter) = ref.watch(
    mapClockProvider.select((now) {
      final local = now.toLocal();
      return (
        DateTime(local.year, local.month, local.day).toUtc(),
        DateTime(local.year, local.month, local.day + 1).toUtc(),
        DateTime(local.year, local.month, local.day + 2).toUtc(),
      );
    }),
  );
  return (
    today: calculateSolarTimes(
      latitude: latitude,
      longitude: longitude,
      start: today,
      end: tomorrow,
    ),
    tomorrow: calculateSolarTimes(
      latitude: latitude,
      longitude: longitude,
      start: tomorrow,
      end: dayAfter,
    ),
  );
}
