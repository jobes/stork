import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/gps_health_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../domain/models/solar_times.dart';

part 'map_clock_provider.g.dart';

@riverpod
bool mapSunsetWarning(Ref ref) {
  final minutes = ref.watch(
    appSettingsProvider.select(
      (s) => (s.value ?? const AppSettings()).sunsetWarningMinutes,
    ),
  );
  final lastFix = ref.watch(
    telemetryProvider.select((state) => state.gpsLastFixAt),
  );
  if (lastFix == null || minutes <= 0) return false;

  final solar = ref.watch(mapSolarTimesProvider);
  final threshold = Duration(minutes: minutes);
  return ref.watch(
    mapClockProvider.select((now) {
      if (now.difference(lastFix) >= GpsHealth.fixStaleAfter) return false;
      for (final day in [solar.today, solar.tomorrow]) {
        for (final crossing in day.crossings) {
          if (crossing.event == SolarEvent.sunset &&
              crossing.time.isAfter(now)) {
            return crossing.time.difference(now) <= threshold;
          }
        }
      }
      return false;
    }),
  );
}

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
