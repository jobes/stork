import 'dart:async';
import 'dart:math' as math;
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'telemetry_provider.dart';

part 'flight_duration_provider.g.dart';

class FlightSummary {
  final Duration duration;
  final double distanceMeters;
  final DateTime? startTime;

  const FlightSummary({
    this.duration = Duration.zero,
    this.distanceMeters = 0.0,
    this.startTime,
  });

  FlightSummary copyWith({
    Duration? duration,
    double? distanceMeters,
    DateTime? startTime,
    bool resetStartTime = false,
  }) {
    return FlightSummary(
      duration: duration ?? this.duration,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      startTime: resetStartTime ? null : (startTime ?? this.startTime),
    );
  }
}

@Riverpod(keepAlive: true)
class FlightDuration extends _$FlightDuration {
  Timer? _timer;
  DateTime? _flightStartTime;
  double _distanceMeters = 0.0;
  double? _lastLatitude;
  double? _lastLongitude;

  @override
  FlightSummary build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    ref.listen(
      telemetryProvider.select(
        (s) => (
          isFlying: s.isFlying,
          latitude: s.latitude,
          longitude: s.longitude,
        ),
      ),
      (previous, next) {
        _handleTelemetryChange(previous, next);
      },
    );

    final telemetry = ref.read(telemetryProvider);
    if (telemetry.isFlying) {
      _flightStartTime = clock.now();
      _lastLatitude = telemetry.latitude;
      _lastLongitude = telemetry.longitude;
      _startTimer();
      return FlightSummary(
        duration: Duration.zero,
        distanceMeters: 0.0,
        startTime: _flightStartTime,
      );
    }

    return const FlightSummary();
  }

  void _handleTelemetryChange(
    ({bool isFlying, double? latitude, double? longitude})? previous,
    ({bool isFlying, double? latitude, double? longitude}) next,
  ) {
    final wasFlying = previous?.isFlying ?? false;
    final isFlying = next.isFlying;

    if (isFlying && !wasFlying) {
      // Started flying
      _flightStartTime = clock.now();
      _distanceMeters = 0.0;
      _lastLatitude = next.latitude;
      _lastLongitude = next.longitude;

      state = FlightSummary(
        duration: Duration.zero,
        distanceMeters: 0.0,
        startTime: _flightStartTime,
      );
      _startTimer();
    } else if (!isFlying && wasFlying) {
      // Stopped flying
      _timer?.cancel();
      _timer = null;
      if (_flightStartTime != null) {
        state = FlightSummary(
          duration: clock.now().difference(_flightStartTime!),
          distanceMeters: _distanceMeters,
          startTime: _flightStartTime,
        );
        _flightStartTime = null;
      }
      _lastLatitude = null;
      _lastLongitude = null;
    } else if (isFlying) {
      // Currently flying, update distance if coordinates changed
      if (next.latitude != null && next.longitude != null) {
        if (_lastLatitude != null && _lastLongitude != null) {
          final distance = _calculateDistanceMeters(
            _lastLatitude!,
            _lastLongitude!,
            next.latitude!,
            next.longitude!,
          );
          // Only accumulate if distance is reasonable (e.g. above 1m, to ignore GPS noise while stationary)
          if (distance > 1.0) {
            _distanceMeters += distance;
          }
        }
        _lastLatitude = next.latitude;
        _lastLongitude = next.longitude;

        // Update the state with the new distance (and elapsed duration)
        final elapsed = _flightStartTime != null
            ? clock.now().difference(_flightStartTime!)
            : Duration.zero;
        state = FlightSummary(
          duration: elapsed,
          distanceMeters: _distanceMeters,
          startTime: _flightStartTime,
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_flightStartTime != null) {
        state = state.copyWith(
          duration: clock.now().difference(_flightStartTime!),
        );
      }
    });
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // in meters
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
}
