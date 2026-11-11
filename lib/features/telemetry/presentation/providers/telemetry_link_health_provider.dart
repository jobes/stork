import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/cannelloni_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

part 'telemetry_link_health_provider.g.dart';

/// Whether a telemetry link should be reported as lost.
///
/// A link that was never established (no gateway, mDNS still searching, or
/// DroneCAN intentionally unused) is not an error and must not be reported as
/// a lost connection.
@visibleForTesting
bool shouldReportTelemetryLinkLost({
  required bool hasEverConnected,
  required bool isConnected,
}) {
  return hasEverConnected && !isConnected;
}

/// Whether the link is up but no fresh telemetry is arriving.
@visibleForTesting
bool isTelemetryStale({
  required DateTime now,
  required bool isConnected,
  required DateTime? lastDataAt,
  Duration staleAfter = TelemetryLinkHealth.staleAfter,
}) {
  if (!isConnected || lastDataAt == null) return false;
  return now.difference(lastDataAt) >= staleAfter;
}

/// Health of the aircraft telemetry link.
@immutable
class TelemetryLinkHealthState {
  const TelemetryLinkHealthState({this.linkLost = false, this.stale = false});

  final bool linkLost;
  final bool stale;

  bool get hasIssue => linkLost || stale;

  @override
  bool operator ==(Object other) =>
      other is TelemetryLinkHealthState &&
      other.linkLost == linkLost &&
      other.stale == stale;

  @override
  int get hashCode => Object.hash(linkLost, stale);

  @override
  String toString() =>
      'TelemetryLinkHealthState(linkLost: $linkLost, stale: $stale)';
}

/// Watches the DroneCAN telemetry link and reports a lost connection or frozen
/// data.
///
/// Time-based conditions are aged by [refresh], driven by the map alert
/// ticker.
@riverpod
class TelemetryLinkHealth extends _$TelemetryLinkHealth {
  static const Duration graceAfterStart = Duration(seconds: 10);
  static const Duration lostConfirm = Duration(seconds: 3);
  static const Duration staleAfter = Duration(seconds: 20);

  late DateTime _startedAt;
  DateTime? _lostSince;

  @override
  TelemetryLinkHealthState build() {
    _startedAt = clock.now();
    ref.listen(cannelloniServiceProvider, (_, _) => refresh());
    ref.listen(appSettingsProvider, (_, _) => refresh());
    return _evaluate(clock.now());
  }

  /// Re-evaluates the grace period, the lost confirmation and the stale
  /// window.
  void refresh() {
    if (!ref.mounted) return;
    final next = _evaluate(clock.now());
    if (next != state) state = next;
  }

  TelemetryLinkHealthState _evaluate(DateTime now) {
    final settings = ref.read(appSettingsProvider).value;
    final supported = !kIsWeb && settings?.selectedDevice != null;

    // Give a freshly opened map time to connect before reporting a problem.
    if (!supported || now.difference(_startedAt) < graceAfterStart) {
      _lostSince = null;
      return const TelemetryLinkHealthState();
    }

    final isConnected = ref.read(cannelloniServiceProvider);
    final transport = ref.read(cannelloniServiceProvider.notifier);
    final hasEverConnected = transport.hasEverConnected;

    if (isConnected) {
      _lostSince = null;
    } else if (hasEverConnected) {
      _lostSince ??= now;
    }

    final lostSince = _lostSince;
    // Debounce short reconnects so a normal gateway restart does not flash the
    // error, and never report a link that was not established at all.
    final linkLost =
        shouldReportTelemetryLinkLost(
          hasEverConnected: hasEverConnected,
          isConnected: isConnected,
        ) &&
        lostSince != null &&
        now.difference(lostSince) >= lostConfirm;

    return TelemetryLinkHealthState(
      linkLost: linkLost,
      stale: isTelemetryStale(
        now: now,
        isConnected: isConnected,
        lastDataAt: transport.lastTelemetryActivityAt,
      ),
    );
  }
}
