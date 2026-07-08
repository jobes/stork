import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/utils/aviation_math.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import '../../domain/models/vario_state.dart';
import 'telemetry_provider.dart';

part 'vario_provider.g.dart';

/// A time-tagged altitude sample used for linear regression smoothing.
class _AltitudeSample {
  final DateTime time;
  final double altitude;
  const _AltitudeSample(this.time, this.altitude);
}

@Riverpod(keepAlive: true)
class VarioNotifier extends _$VarioNotifier {
  Timer? _timer;

  // ── Altitude sample buffer for linear regression ──
  static const int _maxSamples = 60;
  final List<_AltitudeSample> _samples = [];

  // ── EMA (exponential moving average) filter state ──
  double _filteredVario = 0.0;
  bool _hasFilteredVario = false;
  DateTime? _lastFilterUpdate;

  // ── GPS-only fallback state ──
  static const int _maxGpsSamples = 60;
  final List<_AltitudeSample> _gpsSamples = [];
  DateTime? _lastGpsVarioTime;

  // ── Tunable filter parameters ──
  /// How much history to use for the linear regression slope estimate.
  static const Duration _regressionWindow = Duration(seconds: 3);

  /// Interval at which the pressure vario is re-computed.
  static const Duration _timerInterval = Duration(milliseconds: 250);

  /// Time constant of the EMA low-pass filter on the output vertical speed.
  /// Larger values = smoother but more lag.
  static const double _outputTimeConstant = 1.0;

  // ── GPS-specific filter parameters ──
  /// GPS altitude is much noisier than baro, so use a longer regression
  /// window and a heavier EMA time constant.
  static const Duration _gpsRegressionWindow = Duration(seconds: 8);
  static const double _gpsOutputTimeConstant = 2.5;
  static const Duration _gpsMinInterval = Duration(seconds: 1);

  @override
  VarioState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    ref.listen<TelemetryState>(telemetryProvider, (_, next) {
      _onTelemetryChanged(next);
    });

    return const VarioState(source: VarioSource.none);
  }

  // ─────────────────────────────────────────────────
  //  Top-level dispatch
  // ─────────────────────────────────────────────────

  void _onTelemetryChanged(TelemetryState telemetry) {
    if (telemetry.airPressure != null) {
      _startPressureVario(telemetry);
    } else if (_isGpsUsable(telemetry)) {
      _stopTimer();
      _computeGpsVario(telemetry);
    } else {
      _stopTimer();
      _samples.clear();
      _gpsSamples.clear();
      _lastGpsVarioTime = null;
      _hasFilteredVario = false;
      _lastFilterUpdate = null;
      state = const VarioState(source: VarioSource.none);
    }
  }

  // ─────────────────────────────────────────────────
  //  Pressure-based vario (primary)
  // ─────────────────────────────────────────────────

  void _startPressureVario(TelemetryState telemetry) {
    if (_timer != null) return;
    _addPressureSample(telemetry);

    _timer = Timer.periodic(_timerInterval, (_) {
      if (!ref.mounted) return;
      final current = ref.read(telemetryProvider);
      if (current.airPressure != null) {
        _addPressureSample(current);
        _computeFilteredPressureVario();
      } else {
        _stopTimer();
      }
    });
  }

  void _addPressureSample(TelemetryState telemetry) {
    final qnh = ref.read(appSettingsProvider).value?.qnh ?? 1013.25;
    final altitude = AviationMath.pressureToAltitudeMeters(
      telemetry.airPressure!,
      qnh,
    );
    _samples.add(_AltitudeSample(DateTime.now(), altitude));
    if (_samples.length > _maxSamples) {
      _samples.removeAt(0);
    }
  }

  /// Computes vertical speed via linear regression over the recent
  /// sample window, then applies an EMA low-pass filter to the output.
  void _computeFilteredPressureVario() {
    if (_samples.length < 3) return;

    final now = DateTime.now();
    final cutoff = now.subtract(_regressionWindow);

    // Find first sample inside the window (avoid walking the whole list
    // every time – samples are in chronological order).
    int startIdx = 0;
    while (startIdx < _samples.length - 2 &&
        _samples[startIdx].time.isBefore(cutoff)) {
      startIdx++;
    }

    final usable = _samples.sublist(startIdx);
    if (usable.length < 3) return;

    // ── Ordinary least-squares linear regression ──
    // Model: altitude(t) = intercept + slope * t
    // where t is seconds since the first sample in the window.
    final t0 = usable.first.time;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = usable.length;

    for (final s in usable) {
      final x = s.time.difference(t0).inMilliseconds / 1000.0;
      sumX += x;
      sumY += s.altitude;
      sumXY += x * s.altitude;
      sumXX += x * x;
    }

    final denom = n * sumXX - sumX * sumX;
    if (denom == 0) return;
    final rawVario = (n * sumXY - sumX * sumY) / denom;

    // ── EMA low-pass filter on the output ──
    final dt = _lastFilterUpdate != null
        ? now.difference(_lastFilterUpdate!).inMilliseconds / 1000.0
        : _timerInterval.inMilliseconds / 1000.0;

    // Guard against unrealistically large dt (e.g., app was suspended).
    if (dt > 10.0) {
      _lastFilterUpdate = now;
      return;
    }

    final alpha = dt / (_outputTimeConstant + dt);
    _filteredVario = _hasFilteredVario
        ? (1 - alpha) * _filteredVario + alpha * rawVario
        : rawVario;
    _hasFilteredVario = true;
    _lastFilterUpdate = now;

    state = VarioState(
      verticalSpeed: _filteredVario,
      source: VarioSource.baro,
      lastUpdate: now,
    );
  }

  // ─────────────────────────────────────────────────
  //  GPS-based vario (fallback when no baro)
  // ─────────────────────────────────────────────────

  bool _isGpsUsable(TelemetryState telemetry) {
    return telemetry.gpsAltitude != null &&
        telemetry.gpsVerticalAccuracy != null &&
        telemetry.gpsVerticalAccuracy! <=
            AviationMath.maxGpsVerticalAccuracyMeters;
  }

  void _computeGpsVario(TelemetryState telemetry) {
    final now = DateTime.now();
    final altitude = telemetry.gpsAltitude!;

    // Always buffer the sample so the regression window fills quickly.
    _gpsSamples.add(_AltitudeSample(now, altitude));
    if (_gpsSamples.length > _maxGpsSamples) {
      _gpsSamples.removeAt(0);
    }

    // Throttle computation to ~1 Hz — GPS altitude is inherently noisy
    // and there is no point recomputing the regression faster than that.
    if (_lastGpsVarioTime != null &&
        now.difference(_lastGpsVarioTime!) < _gpsMinInterval) {
      return;
    }
    _lastGpsVarioTime = now;

    // ── Linear regression over the GPS window ──
    final cutoff = now.subtract(_gpsRegressionWindow);
    int startIdx = 0;
    while (startIdx < _gpsSamples.length - 2 &&
        _gpsSamples[startIdx].time.isBefore(cutoff)) {
      startIdx++;
    }

    final usable = _gpsSamples.sublist(startIdx);
    if (usable.length < 3) return;

    final t0 = usable.first.time;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = usable.length;

    for (final s in usable) {
      final x = s.time.difference(t0).inMilliseconds / 1000.0;
      sumX += x;
      sumY += s.altitude;
      sumXY += x * s.altitude;
      sumXX += x * x;
    }

    final denom = n * sumXX - sumX * sumX;
    if (denom == 0) return;
    final rawVario = (n * sumXY - sumX * sumY) / denom;

    // ── Heavier EMA filter for GPS ──
    final dt = _lastFilterUpdate != null
        ? now.difference(_lastFilterUpdate!).inMilliseconds / 1000.0
        : _gpsMinInterval.inMilliseconds / 1000.0;

    if (dt > 10.0) {
      _lastFilterUpdate = now;
      return;
    }

    final alpha = dt / (_gpsOutputTimeConstant + dt);
    _filteredVario = _hasFilteredVario
        ? (1 - alpha) * _filteredVario + alpha * rawVario
        : rawVario;
    _hasFilteredVario = true;
    _lastFilterUpdate = now;

    state = VarioState(
      verticalSpeed: _filteredVario,
      source: VarioSource.gps,
      lastUpdate: now,
    );
  }

  // ─────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _samples.clear();
    // GPS samples, EMA state, and last-GPS-time are preserved here so that
    // _computeGpsVario (called right after _stopTimer in the GPS fallback
    // path) can continue accumulating samples with EMA continuity.
    // Full reset of all fields is done explicitly in the none-state branch
    // of _onTelemetryChanged.
  }
}
