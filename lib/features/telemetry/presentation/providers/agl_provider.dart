import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/terrain_elevation_service.dart';
import '../../../../core/utils/aviation_math.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/resolved_altitude.dart';
import 'telemetry_provider.dart';

part 'agl_provider.g.dart';

class AglState {
  final double? terrainElevation;
  final double? heightAboveGround;
  final bool isFetching;

  const AglState({
    this.terrainElevation,
    this.heightAboveGround,
    this.isFetching = false,
  });

  AglState copyWith({
    double? terrainElevation,
    double? heightAboveGround,
    bool? isFetching,
  }) {
    return AglState(
      terrainElevation: terrainElevation ?? this.terrainElevation,
      heightAboveGround: heightAboveGround ?? this.heightAboveGround,
      isFetching: isFetching ?? this.isFetching,
    );
  }

  @override
  String toString() =>
      'AglState(terrainElevation: $terrainElevation, heightAboveGround: $heightAboveGround, isFetching: $isFetching)';
}

@riverpod
(double, double)? telemetryCoordinates(Ref ref) {
  final lat = ref.watch(telemetryProvider.select((s) => s.latitude));
  final lon = ref.watch(telemetryProvider.select((s) => s.longitude));
  if (lat == null || lon == null) return null;

  // Round coordinates to 5 decimal places (~1.1m precision)
  // to avoid micro-fluctuations (GPS noise) from triggering updates.
  final roundedLat = (lat * 100000).roundToDouble() / 100000;
  final roundedLon = (lon * 100000).roundToDouble() / 100000;
  return (roundedLat, roundedLon);
}

@riverpod
class TerrainElevation extends _$TerrainElevation {
  @override
  AsyncValue<double?> build() {
    final coords = ref.watch(telemetryCoordinatesProvider);
    if (coords == null) return const AsyncValue.data(null);

    final service = ref.read(terrainElevationServiceProvider);

    final (isCached, cachedVal) = service.getCachedElevationState(
      coords.$1,
      coords.$2,
    );
    if (isCached) {
      return AsyncValue.data(cachedVal);
    }

    final lat = coords.$1;
    final lon = coords.$2;
    _loadElevation(lat, lon);

    return const AsyncValue.loading();
  }

  Future<void> _loadElevation(double lat, double lon) async {
    final service = ref.read(terrainElevationServiceProvider);
    try {
      final value = await service.getElevation(lat, lon);
      final currentCoords = ref.read(telemetryCoordinatesProvider);
      if (currentCoords != null &&
          currentCoords.$1 == lat &&
          currentCoords.$2 == lon) {
        state = AsyncValue.data(value);
      }
    } catch (e, st) {
      final currentCoords = ref.read(telemetryCoordinatesProvider);
      if (currentCoords != null &&
          currentCoords.$1 == lat &&
          currentCoords.$2 == lon) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

@riverpod
ResolvedAltitude resolvedAltitude(Ref ref) {
  final settings = ref.watch(appSettingsProvider).value;

  // Watch only the specific fields of TelemetryState that affect altitude:
  final airPressure = ref.watch(telemetryProvider.select((s) => s.airPressure));
  final gpsAltitude = ref.watch(telemetryProvider.select((s) => s.gpsAltitude));
  final isGpsDroneCan = ref.watch(
    telemetryProvider.select((s) => s.isGpsDroneCan),
  );

  return AltitudeResolver.resolve(
    airPressure: airPressure,
    gpsAltitude: gpsAltitude,
    isGpsDroneCan: isGpsDroneCan,
    settings: settings,
  );
}

@riverpod
double? recommendedQnh(Ref ref) {
  final airPressure = ref.watch(telemetryProvider.select((s) => s.airPressure));
  if (airPressure == null) return null;

  final autoQnh = ref.watch(
    appSettingsProvider.select((s) => s.value?.autoQnh ?? true),
  );
  if (!autoQnh) return null;

  final isFlying = ref.watch(telemetryProvider.select((s) => s.isFlying));
  if (isFlying) return null;

  final elevation = ref.watch(terrainElevationProvider).value;
  if (elevation == null) return null;

  return AviationMath.altitudeToQnhHpa(
    airPressure,
    elevation,
  ).clamp(AviationMath.minQnhHpa, AviationMath.maxQnhHpa);
}

@Riverpod(keepAlive: true)
void autoQnhCalibrator(Ref ref) {
  Timer? debounceTimer;
  double? pendingQnh;

  ref.onDispose(() {
    debounceTimer?.cancel();
  });

  ref.listen(recommendedQnhProvider, (previous, next) {
    if (next != null) {
      pendingQnh = next;
      if (debounceTimer == null || !debounceTimer!.isActive) {
        debounceTimer = Timer(const Duration(seconds: 2), () {
          if (pendingQnh != null) {
            final currentQnh =
                ref.read(appSettingsProvider).value?.qnh ?? 1013.25;
            if ((pendingQnh! - currentQnh).abs() >
                AviationMath.qnhUpdateThresholdHpa) {
              ref.read(appSettingsProvider.notifier).updateQnh(pendingQnh!);
            }
          }
        });
      }
    } else {
      debounceTimer?.cancel();
      pendingQnh = null;
    }
  });
}

@riverpod
AglState agl(Ref ref) {
  ref.watch(autoQnhCalibratorProvider);

  final resolved = ref.watch(resolvedAltitudeProvider);
  final elevationAsync = ref.watch(terrainElevationProvider);

  final msl = resolved.mslValue;
  final elevation = elevationAsync.value;

  return AglState(
    terrainElevation: elevation,
    heightAboveGround: (msl != null && elevation != null)
        ? msl - elevation
        : null,
    isFetching: elevationAsync.isLoading,
  );
}
