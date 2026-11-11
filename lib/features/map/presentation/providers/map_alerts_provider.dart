import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/style_provider.dart';
import '../../../offline_maps/presentation/providers/offline_maps_provider.dart';
import '../../../telemetry/presentation/providers/altitude_health_provider.dart';
import '../../../telemetry/presentation/providers/gps_health_provider.dart';
import '../../../telemetry/presentation/providers/instrument_status_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_link_health_provider.dart';
import '../../../telemetry/presentation/providers/temperature_trend_provider.dart';
import '../../../telemetry/presentation/providers/traffic_provider.dart';
import '../../../telemetry/presentation/providers/traffic_source_health_provider.dart';
import '../../../telemetry/domain/models/telemetry_instrument.dart';
import '../models/map_alert.dart';
import 'airspace_data_status_provider.dart';
import 'map_alert_history_provider.dart';

export '../models/map_alert.dart';

part 'map_alerts_provider.g.dart';

/// Whether a missing network link has lasted long enough to be reported.
///
/// A short drop (cell handover, Wi-Fi roaming) should not flash a badge, and an
/// offline-first app keeps working without a link.
@visibleForTesting
bool isInternetUnavailable({
  required DateTime now,
  required bool linkAvailable,
  required DateTime? offlineSince,
  Duration grace = MapAlerts.internetGrace,
}) {
  if (linkAvailable || offlineSince == null) return false;
  return now.difference(offlineSince) >= grace;
}

/// Aggregates active health signals in priority order.
///
/// Each signal is owned by its own provider ([GpsHealth],
/// [TelemetryLinkHealth], [TrafficSourceHealth], [AltitudeHealth] and the
/// map-specific ones). This notifier only composes them, tracks how long each
/// condition has been active and drives the shared 1 Hz ticker, so there is
/// exactly one periodic timer for the whole indicator.
@riverpod
class MapAlerts extends _$MapAlerts {
  static const Duration internetGrace = Duration(seconds: 10);
  static final _instrumentKinds = MapAlertKind.values
      .where((kind) => kind.instrument != null)
      .toList(growable: false);

  Timer? _ticker;
  bool _recomputeScheduled = false;
  DateTime? _internetOfflineSince;

  final Map<MapAlertKind, DateTime> _since = {};

  @override
  List<MapAlert> build() {
    ref.listen(gpsHealthProvider, (_, _) => _scheduleRecompute());
    ref.listen(telemetryLinkHealthProvider, (_, _) => _scheduleRecompute());
    ref.listen(trafficSourceHealthProvider, (_, _) => _scheduleRecompute());
    ref.listen(altitudeHealthProvider, (_, _) => _scheduleRecompute());
    ref.listen(networkLinkAvailabilityProvider, (_, _) => _scheduleRecompute());
    ref.listen(airspaceDataStatusProvider, (_, _) => _scheduleRecompute());
    ref.listen(mapStyleProvider, (_, _) => _scheduleRecompute());
    ref.listen(offlineMapsProvider, (_, _) => _scheduleRecompute());
    ref.listen(
      activeCollisionAlertProvider.select((threat) => threat != null),
      (_, _) => _scheduleRecompute(),
    );
    for (final kind in _instrumentKinds) {
      ref.listen(
        instrumentStatusProvider(
          kind.instrument!,
        ).select((status) => status.supported ? status.issue : null),
        (_, _) => _scheduleRecompute(),
      );
    }

    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });

    unawaited(Future<void>.microtask(_recompute));
    return const [];
  }

  void _scheduleRecompute() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    unawaited(
      Future<void>.microtask(() {
        _recomputeScheduled = false;
        if (ref.mounted) _recompute();
      }),
    );
  }

  void _recompute() {
    if (!ref.mounted) return;
    final now = clock.now();

    // Age the time-based signals first; their providers notify back through
    // the listeners above when a threshold is crossed.
    ref.read(gpsHealthProvider.notifier).refresh();
    ref.read(telemetryLinkHealthProvider.notifier).refresh();
    ref.read(trafficSourceHealthProvider.notifier).refresh();
    ref.read(altitudeHealthProvider.notifier).refresh();

    final active = <MapAlertKind>{
      if (ref.read(activeCollisionAlertProvider) != null)
        MapAlertKind.collisionThreat,
      if (ref.read(mapStyleProvider).hasError) MapAlertKind.mapStyleUnavailable,
      if (ref.read(offlineMapsProvider).hasError) MapAlertKind.offlineMapsError,
      if (ref.read(airspaceDataStatusProvider).hasError)
        MapAlertKind.airspaceDataUnavailable,
      if (_isInternetUnavailable(now)) MapAlertKind.internetUnavailable,
      ..._gpsKinds(ref.read(gpsHealthProvider)),
      ..._linkKinds(ref.read(telemetryLinkHealthProvider)),
      if (ref.read(trafficSourceHealthProvider).unavailable)
        MapAlertKind.trafficSourceOffline,
      ..._altitudeKinds(ref.read(altitudeHealthProvider)),
    };
    final instrumentIssues = <MapAlertKind, InstrumentIssue>{};
    for (final kind in _instrumentKinds) {
      final status = ref.read(instrumentStatusProvider(kind.instrument!));
      final issue = status.issue;
      if (status.supported && issue != null) {
        instrumentIssues[kind] = issue;
      }
    }
    active.addAll(instrumentIssues.keys);

    _since.removeWhere((kind, _) => !active.contains(kind));
    for (final kind in active) {
      _since.putIfAbsent(kind, () => now);
    }

    final next = [
      for (final kind in active)
        MapAlert(
          kind: kind,
          since: _since[kind]!,
          instrumentIssue: instrumentIssues[kind],
        ),
    ]..sort((a, b) => a.comparePriority(b));
    if (!listEquals(state, next)) {
      state = List.unmodifiable(next);
    }

    ref.read(mapAlertHistoryProvider.notifier).observeSystemAlerts(next, now);
    ref
        .read(temperatureTrendProvider.notifier)
        .sample(now, ref.read(telemetryProvider));
    _syncTicker();
  }

  bool _isInternetUnavailable(DateTime now) {
    final linkAvailable = ref.read(networkLinkAvailabilityProvider);
    _internetOfflineSince = linkAvailable
        ? null
        : (_internetOfflineSince ?? now);
    return isInternetUnavailable(
      now: now,
      linkAvailable: linkAvailable,
      offlineSince: _internetOfflineSince,
    );
  }

  Set<MapAlertKind> _gpsKinds(GpsHealthState gps) {
    return {
      if (gps.permissionDenied) MapAlertKind.gpsPermissionDenied,
      if (gps.servicesDisabled) MapAlertKind.locationServicesDisabled,
      if (gps.streamFailed) MapAlertKind.gpsStreamError,
      if (gps.fixLost) MapAlertKind.gpsFixLost,
      if (gps.awaitingFirstFix) MapAlertKind.gpsNoFix,
      if (gps.droneCanFallback) MapAlertKind.droneCanGpsFallback,
    };
  }

  Set<MapAlertKind> _linkKinds(TelemetryLinkHealthState link) {
    return {
      if (link.linkLost) MapAlertKind.telemetryLinkLost,
      if (link.stale) MapAlertKind.telemetryStale,
    };
  }

  Set<MapAlertKind> _altitudeKinds(AltitudeHealthState altitude) {
    return {
      if (altitude.altitudeUnavailable) MapAlertKind.altitudeUnavailable,
      if (altitude.terrainUnavailable) MapAlertKind.terrainUnavailable,
      if (altitude.sourceChanged) MapAlertKind.altitudeSourceChanged,
    };
  }

  /// Runs exactly one 1 Hz ticker for as long as the indicator exists.
  ///
  /// Every grace period, confirmation and stale window is aged here. The
  /// ticker must keep running even while the map is idle: a lost link produces
  /// no further events, so its confirmation window could otherwise never
  /// mature and the alert would never appear. A tick only reads providers; OS
  /// location polling is gated separately in [GpsHealth], so an idle map stays
  /// cheap.
  void _syncTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }
}
