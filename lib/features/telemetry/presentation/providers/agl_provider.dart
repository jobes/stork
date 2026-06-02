import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/terrain_elevation_service.dart';
import '../../../../core/utils/aviation_math.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/resolved_altitude.dart';
import '../../domain/models/telemetry_state.dart';
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

class AutoQnhCalibratorState {
  final double? estimatedH;
  final double? estimatedQnh;
  final double p11;
  final double p12;
  final double p22;
  final DateTime? lastFilterUpdateTime;
  final bool wasFlying;

  const AutoQnhCalibratorState({
    this.estimatedH,
    this.estimatedQnh,
    this.p11 = 10.0,
    this.p12 = 0.0,
    this.p22 = 1.0,
    this.lastFilterUpdateTime,
    this.wasFlying = false,
  });

  AutoQnhCalibratorState copyWith({
    double? estimatedH,
    double? estimatedQnh,
    double? p11,
    double? p12,
    double? p22,
    DateTime? lastFilterUpdateTime,
    bool? wasFlying,
  }) {
    return AutoQnhCalibratorState(
      estimatedH: estimatedH ?? this.estimatedH,
      estimatedQnh: estimatedQnh ?? this.estimatedQnh,
      p11: p11 ?? this.p11,
      p12: p12 ?? this.p12,
      p22: p22 ?? this.p22,
      lastFilterUpdateTime: lastFilterUpdateTime ?? this.lastFilterUpdateTime,
      wasFlying: wasFlying ?? this.wasFlying,
    );
  }

  @override
  String toString() =>
      'AutoQnhCalibratorState(estimatedH: $estimatedH, estimatedQnh: $estimatedQnh, p11: $p11, p12: $p12, p22: $p22, lastFilterUpdateTime: $lastFilterUpdateTime, wasFlying: $wasFlying)';
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
class AutoQnhCalibrator extends _$AutoQnhCalibrator {
  Timer? _debounceTimer;
  double? _pendingQnh;
  DateTime? _lastSaveTime;

  @override
  AutoQnhCalibratorState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    ref.listen(telemetryProvider, (previous, next) {
      _handleTelemetryUpdate(next);
    });

    // Keep the original listener for ground calibration
    ref.listen(recommendedQnhProvider, (previous, next) {
      _handleRecommendedQnhUpdate(next);
    });

    return const AutoQnhCalibratorState();
  }

  void _handleTelemetryUpdate(TelemetryState next) {
    final settings = ref.read(appSettingsProvider).value;
    final autoQnh = settings?.autoQnh ?? true;
    if (!autoQnh) return;

    final isFlying = next.isFlying;

    if (!isFlying) {
      // Reset Kalman filter state variables on ground so they are ready for the next flight
      if (state.wasFlying ||
          state.estimatedH != null ||
          state.estimatedQnh != null) {
        state = const AutoQnhCalibratorState();
      }
      return;
    }

    // In flight calibration:
    final airPressure = next.airPressure;
    final gpsAltitude = next.gpsAltitude;
    final gpsVerticalAccuracy = next.gpsVerticalAccuracy;

    // Use GPS altitude only when vertical accuracy is between min and max thresholds
    if (airPressure != null &&
        gpsAltitude != null &&
        gpsVerticalAccuracy != null &&
        gpsVerticalAccuracy >= AviationMath.minGpsVerticalAccuracyMeters &&
        gpsVerticalAccuracy <= AviationMath.maxGpsVerticalAccuracyMeters) {
      final now = DateTime.now();

      double? currentEstH = state.estimatedH;
      double? currentEstQnh = state.estimatedQnh;
      double currentP11 = state.p11;
      double currentP12 = state.p12;
      double currentP22 = state.p22;
      DateTime? currentLastFilterUpdateTime = state.lastFilterUpdateTime;
      bool currentWasFlying = state.wasFlying;

      if (!currentWasFlying ||
          currentEstH == null ||
          currentEstQnh == null ||
          currentLastFilterUpdateTime == null) {
        currentWasFlying = true;
        currentEstH = gpsAltitude;
        currentEstQnh = settings?.qnh ?? 1013.25;
        currentP11 = 10.0;
        currentP12 = 0.0;
        currentP22 = 1.0;
        currentLastFilterUpdateTime = now;
      }

      final dt =
          now.difference(currentLastFilterUpdateTime).inMilliseconds / 1000.0;
      currentLastFilterUpdateTime = now;

      if (dt > 0.0) {
        // 1. Predict Step
        // Process noise rate for altitude: Q_H = 100.0 m^2/s (climb/descent uncertainty)
        const double qH = 100.0;
        // Process noise rate for QNH: Q_QNH = 2.5e-5 hPa^2/s (slow weather changes)
        const double qQnh = 2.5e-5;

        currentP11 += qH * dt;
        currentP22 += qQnh * dt;
      }

      // 2. Update Step (2D Extended Kalman Filter)
      // Predicted pressure measurement based on physical equations:
      // pred_P = QNH * 100 * (1 - H / 44330.77)^barometricExponent (in Pa)
      final double base = (1.0 - (currentEstH! / 44330.77)).clamp(0.0001, 1.0);
      final double predP =
          currentEstQnh! *
          100.0 *
          math.pow(base, AviationMath.barometricExponent);

      // Jacobian H_jac of measurement model h(x) = [H, P]^T
      // h11 = dH/dH = 1.0, h12 = dH/dQNH = 0.0
      // h21 = dP/dH = - (barometricExponent * predP) / (44330.77 - H)
      // h22 = dP/dQNH = predP / QNH
      final double denominator = (44330.77 - currentEstH).clamp(
        1000.0,
        44330.77,
      );
      final double h21 =
          -(AviationMath.barometricExponent * predP) / denominator;
      final double h22 = predP / currentEstQnh;

      // M = P * H_jac^T
      final double m11 = currentP11;
      final double m12 = currentP11 * h21 + currentP12 * h22;
      final double m21 = currentP12;
      final double m22 = currentP12 * h21 + currentP22 * h22;

      // Innovation covariance matrix S = H_jac * M + R
      // R_gps = gpsVerticalAccuracy^2
      // R_baro = 4.0 Pa^2 (barometer sensor noise standard deviation = 2.0 Pa)
      final double rGps = gpsVerticalAccuracy * gpsVerticalAccuracy;
      const double rBaro = 4.0;

      final double s11 = currentP11 + rGps;
      final double s12 = m12;
      final double s21 = s12;
      final double s22 = h21 * m12 + h22 * m22 + rBaro;

      // Invert 2x2 matrix S analytically
      final double det = s11 * s22 - s12 * s21;
      if (det.abs() > 1e-6) {
        final double si11 = s22 / det;
        final double si12 = -s12 / det;
        final double si21 = si12;
        final double si22 = s11 / det;

        // Kalman Gain K = M * S^-1
        final double k11 = m11 * si11 + m12 * si21;
        final double k12 = m11 * si12 + m12 * si22;
        final double k21 = m21 * si11 + m22 * si21;
        final double k22 = m21 * si12 + m22 * si22;

        // Innovation y = z - h(x)
        final double y1 = gpsAltitude - currentEstH;
        final double y2 = airPressure - predP;

        // State Update
        currentEstH = currentEstH + k11 * y1 + k12 * y2;
        currentEstQnh = (currentEstQnh + k21 * y1 + k22 * y2).clamp(
          AviationMath.minQnhHpa,
          AviationMath.maxQnhHpa,
        );

        // Covariance Update P = (I - K * H_jac) * P
        // W = I - K * H_jac
        final double w11 = 1.0 - k11 - k12 * h21;
        final double w12 = -k12 * h22;
        final double w21 = -k21 - k22 * h21;
        final double w22 = 1.0 - k22 * h22;

        final double p11New = w11 * currentP11 + w12 * currentP12;
        final double p12New = w11 * currentP12 + w12 * currentP22;
        final double p21New = w21 * currentP11 + w22 * currentP12;
        final double p22New = w21 * currentP12 + w22 * currentP22;

        currentP11 = p11New;
        currentP12 = (p12New + p21New) / 2.0; // preserve symmetry
        currentP22 = p22New;
      }

      state = AutoQnhCalibratorState(
        estimatedH: currentEstH,
        estimatedQnh: currentEstQnh,
        p11: currentP11,
        p12: currentP12,
        p22: currentP22,
        lastFilterUpdateTime: currentLastFilterUpdateTime,
        wasFlying: currentWasFlying,
      );

      // Check if we need to update the settings QNH
      if (currentEstQnh != null) {
        final currentQnh = ref.read(appSettingsProvider).value?.qnh ?? 1013.25;
        final diff = (currentEstQnh - currentQnh).abs();
        if (diff > AviationMath.qnhUpdateThresholdHpa) {
          _pendingQnh = currentEstQnh;

          if (_lastSaveTime == null ||
              now.difference(_lastSaveTime!) >= const Duration(seconds: 15)) {
            _lastSaveTime = now;
            ref.read(appSettingsProvider.notifier).updateQnh(currentEstQnh);
            _debounceTimer?.cancel();
          } else {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 15), () {
              if (_pendingQnh != null) {
                final latestQnh =
                    ref.read(appSettingsProvider).value?.qnh ?? 1013.25;
                if ((_pendingQnh! - latestQnh).abs() >
                    AviationMath.qnhUpdateThresholdHpa) {
                  _lastSaveTime = DateTime.now();
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateQnh(_pendingQnh!);
                }
              }
            });
          }
        } else {
          _debounceTimer?.cancel();
          _pendingQnh = null;
        }
      }
    }
  }

  void _handleRecommendedQnhUpdate(double? next) {
    final settings = ref.read(appSettingsProvider).value;
    final autoQnh = settings?.autoQnh ?? true;
    if (!autoQnh) return;

    final isFlying = ref.read(telemetryProvider.select((s) => s.isFlying));
    if (isFlying) return;

    if (next != null) {
      _pendingQnh = next;
      if (_debounceTimer == null || !_debounceTimer!.isActive) {
        _debounceTimer = Timer(const Duration(seconds: 2), () {
          if (_pendingQnh != null) {
            final currentQnh =
                ref.read(appSettingsProvider).value?.qnh ?? 1013.25;
            if ((_pendingQnh! - currentQnh).abs() >
                AviationMath.qnhUpdateThresholdHpa) {
              ref.read(appSettingsProvider.notifier).updateQnh(_pendingQnh!);
            }
          }
        });
      }
    } else {
      _debounceTimer?.cancel();
      _pendingQnh = null;
    }
  }
}

@riverpod
AglState agl(Ref ref) {
  ref.listen(autoQnhCalibratorProvider, (_, __) {});

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
