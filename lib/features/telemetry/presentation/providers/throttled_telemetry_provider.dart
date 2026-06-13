import 'dart:async';
import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'telemetry_provider.dart';
import '../../domain/models/telemetry_state.dart';

part 'throttled_telemetry_provider.g.dart';

@Riverpod(keepAlive: true)
class ThrottledTelemetry extends _$ThrottledTelemetry {
  Timer? _timer;
  TelemetryState? _latestRaw;
  DateTime _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(0).subtract(const Duration(days: 1));

  @override
  TelemetryState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    ref.listen<TelemetryState>(telemetryProvider, (previous, next) {
      _latestRaw = next;
      scheduleMicrotask(() {
        if (!ref.mounted || _latestRaw != next) return;
        final now = clock.now();

        final hasLocationFix = next.latitude != null && next.longitude != null && next.latitude != 0.0 && next.longitude != 0.0;
        final hadLocationFix = state.latitude != null && state.longitude != null && state.latitude != 0.0 && state.longitude != 0.0;
        final isInitialFix = hasLocationFix && !hadLocationFix;

        if (isInitialFix || now.difference(_lastUpdateTime) >= const Duration(seconds: 5)) {
          _updateState(next);
        } else {
          // If an update is already scheduled, we don't need to schedule another one.
          if (_timer == null) {
            final delay = const Duration(seconds: 5) - now.difference(_lastUpdateTime);
            _timer = Timer(delay, () {
              if (_latestRaw != null && ref.mounted) {
                _updateState(_latestRaw!);
              }
            });
          }
        }
      });
    });

    return ref.read(telemetryProvider);
  }

  void _updateState(TelemetryState newState) {
    _timer?.cancel();
    _timer = null;
    _lastUpdateTime = clock.now();
    state = newState;
  }
}

