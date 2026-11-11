import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/location_access_provider.dart';
import '../../../../core/services/location_provider.dart';
import '../../domain/models/map_view_state.dart';
import 'telemetry_provider.dart';

part 'gps_health_provider.g.dart';

/// Time-based GPS fix conditions.
///
/// Kept separate from [GpsHealthState] so the age thresholds can be unit
/// tested without any provider container.
@immutable
class GpsFixHealth {
  const GpsFixHealth({this.fixLost = false, this.awaitingFirstFix = false});

  /// A fix was received before but is now older than
  /// [GpsHealth.fixStaleAfter].
  final bool fixLost;

  /// GPS is expected but no fix has been received yet.
  final bool awaitingFirstFix;

  bool get hasIssue => fixLost || awaitingFirstFix;

  @override
  bool operator ==(Object other) =>
      other is GpsFixHealth &&
      other.fixLost == fixLost &&
      other.awaitingFirstFix == awaitingFirstFix;

  @override
  int get hashCode => Object.hash(fixLost, awaitingFirstFix);

  @override
  String toString() =>
      'GpsFixHealth(fixLost: $fixLost, awaitingFirstFix: $awaitingFirstFix)';
}

/// Evaluates how old the last GPS fix is.
///
/// A fix that is absent only becomes a problem after [noFixAfter] so the map
/// does not complain while the receiver is still acquiring satellites.
@visibleForTesting
GpsFixHealth evaluateGpsFixHealth({
  required DateTime now,
  required bool gpsExpected,
  required DateTime? lastFixAt,
  required DateTime? expectedSince,
  Duration fixStaleAfter = GpsHealth.fixStaleAfter,
  Duration noFixAfter = GpsHealth.noFixAfter,
}) {
  if (!gpsExpected) return const GpsFixHealth();

  if (lastFixAt == null) {
    final since = expectedSince;
    return GpsFixHealth(
      awaitingFirstFix: since != null && now.difference(since) >= noFixAfter,
    );
  }

  return GpsFixHealth(fixLost: now.difference(lastFixAt) >= fixStaleAfter);
}

/// Aggregated GPS health reported by the OS and the telemetry pipeline.
@immutable
class GpsHealthState {
  const GpsHealthState({
    this.permissionDenied = false,
    this.servicesDisabled = false,
    this.streamFailed = false,
    this.fixLost = false,
    this.awaitingFirstFix = false,
    this.droneCanFallback = false,
  });

  final bool permissionDenied;
  final bool servicesDisabled;
  final bool streamFailed;
  final bool fixLost;
  final bool awaitingFirstFix;

  /// The DroneCAN GPS stopped sending and the device GPS took over.
  final bool droneCanFallback;

  bool get hasIssue =>
      permissionDenied ||
      servicesDisabled ||
      streamFailed ||
      fixLost ||
      awaitingFirstFix;

  @override
  bool operator ==(Object other) =>
      other is GpsHealthState &&
      other.permissionDenied == permissionDenied &&
      other.servicesDisabled == servicesDisabled &&
      other.streamFailed == streamFailed &&
      other.fixLost == fixLost &&
      other.awaitingFirstFix == awaitingFirstFix &&
      other.droneCanFallback == droneCanFallback;

  @override
  int get hashCode => Object.hash(
    permissionDenied,
    servicesDisabled,
    streamFailed,
    fixLost,
    awaitingFirstFix,
    droneCanFallback,
  );

  @override
  String toString() =>
      'GpsHealthState(permissionDenied: $permissionDenied, '
      'servicesDisabled: $servicesDisabled, streamFailed: $streamFailed, '
      'fixLost: $fixLost, awaitingFirstFix: $awaitingFirstFix, '
      'droneCanFallback: $droneCanFallback)';
}

/// Watches the GPS pipeline: OS permission/services, the stream status, fix
/// age and DroneCAN fallback.
///
/// Time-based conditions are aged by [refresh], which the map alert notifier
/// calls from its single ticker, so the app keeps only one periodic timer.
@riverpod
class GpsHealth extends _$GpsHealth {
  static const Duration fixStaleAfter = Duration(seconds: 12);
  static const Duration noFixAfter = Duration(seconds: 20);
  static const Duration droneCanFallbackDuration = Duration(seconds: 30);
  static const Duration accessPollInterval = Duration(seconds: 5);

  DateTime? _expectedSince;
  DateTime? _lastAccessPoll;
  DateTime? _droneCanFallbackAt;
  bool _accessRequested = false;
  bool _accessPollInFlight = false;

  @override
  GpsHealthState build() {
    final telemetry = ref.read(telemetryProvider);
    if (telemetry.mapViewState != MapViewState.init) {
      _accessRequested = true;
      _expectedSince = clock.now();
    }

    ref.listen<TelemetryState>(telemetryProvider, _observeTelemetry);
    ref.listen(geolocatorStreamProvider, (_, _) => refresh());
    ref.listen(locationAccessProvider, (_, _) => refresh());
    return _evaluate(clock.now());
  }

  /// Re-evaluates time-based conditions.
  void refresh() {
    if (!ref.mounted) return;
    final now = clock.now();
    _pollLocationAccess(now);
    final next = _evaluate(now);
    if (next != state) state = next;
  }

  void _observeTelemetry(TelemetryState? previous, TelemetryState next) {
    if (next.mapViewState != MapViewState.init) {
      // Latched: once the pilot asked for GPS, a permission problem must stay
      // visible even when the map falls back to `init`.
      _accessRequested = true;
      _expectedSince ??= clock.now();
    } else {
      _expectedSince = null;
    }

    if (next.isGpsDroneCan) {
      _droneCanFallbackAt = null;
    } else if (previous?.isGpsDroneCan == true) {
      _droneCanFallbackAt = clock.now();
    }

    refresh();
  }

  GpsHealthState _evaluate(DateTime now) {
    final telemetry = ref.read(telemetryProvider);
    final access = ref.read(locationAccessProvider);
    final fix = evaluateGpsFixHealth(
      now: now,
      gpsExpected: telemetry.mapViewState != MapViewState.init,
      lastFixAt: telemetry.gpsLastFixAt,
      expectedSince: _expectedSince,
    );
    final fallbackAt = _droneCanFallbackAt;
    final lastFixAt = telemetry.gpsLastFixAt;
    final usesDeviceGps = !telemetry.isGpsDroneCan;

    return GpsHealthState(
      permissionDenied: usesDeviceGps && access.permissionDenied,
      servicesDisabled: usesDeviceGps && access.servicesDisabled,
      streamFailed:
          usesDeviceGps &&
          ref.read(geolocatorStreamProvider).status is GeolocatorStreamFailed,
      fixLost: fix.fixLost,
      awaitingFirstFix: fix.awaitingFirstFix,
      droneCanFallback:
          usesDeviceGps &&
          fallbackAt != null &&
          lastFixAt != null &&
          !lastFixAt.isBefore(fallbackAt) &&
          !fix.fixLost &&
          now.difference(fallbackAt) < droneCanFallbackDuration,
    );
  }

  void _pollLocationAccess(DateTime now) {
    if (!_accessRequested) return;

    // An idle map must not touch the OS location channel every few seconds,
    // but a reported problem has to keep being re-checked so a fix made in the
    // system settings is noticed even after the map fell back to `init`.
    final gpsExpected =
        ref.read(telemetryProvider).mapViewState != MapViewState.init;
    final hasAccessIssue = state.permissionDenied || state.servicesDisabled;
    if (!gpsExpected && !hasAccessIssue) return;

    final last = _lastAccessPoll;
    if (_accessPollInFlight ||
        (last != null && now.difference(last) < accessPollInterval)) {
      return;
    }

    _lastAccessPoll = now;
    _accessPollInFlight = true;
    unawaited(_checkLocationAccess());
  }

  Future<void> _checkLocationAccess() async {
    try {
      await ref.read(locationAccessProvider.notifier).refresh();
    } finally {
      _accessPollInFlight = false;
    }
  }
}
