import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'gdl90_provider.dart';
import 'ogn_connection_provider.dart';
import 'puretrack_auth_provider.dart';
import 'telemetry_provider.dart';

part 'traffic_source_health_provider.g.dart';

/// Whether every enabled traffic source should be considered unavailable.
///
/// Requires the aircraft to be flying, at least one source to have been online
/// in this session, and all of them to stay offline for [grace]. Without that,
/// a source the pilot never configured (e.g. a traffic receiver that was never
/// switched on) would raise a permanent warning.
@visibleForTesting
bool evaluateTrafficSourceUnavailable({
  required DateTime now,
  required bool enabled,
  required bool anyOnline,
  required bool everOnline,
  required bool isFlying,
  required DateTime? offlineSince,
  Duration grace = TrafficSourceHealth.offlineGrace,
}) {
  if (!enabled || !everOnline || anyOnline || !isFlying) return false;
  if (offlineSince == null) return false;
  return now.difference(offlineSince) >= grace;
}

/// Health of the configured traffic sources.
@immutable
class TrafficSourceHealthState {
  const TrafficSourceHealthState({this.unavailable = false});

  /// Collision warnings are not active even though traffic is expected.
  final bool unavailable;

  @override
  bool operator ==(Object other) =>
      other is TrafficSourceHealthState && other.unavailable == unavailable;

  @override
  int get hashCode => unavailable.hashCode;

  @override
  String toString() => 'TrafficSourceHealthState(unavailable: $unavailable)';
}

/// Watches OGN, PureTrack and GDL90 so the map can report that traffic data is
/// missing without depending on the traffic list itself.
@riverpod
class TrafficSourceHealth extends _$TrafficSourceHealth {
  static const Duration offlineGrace = Duration(seconds: 30);
  // PureTrack polls every 5 seconds, with an 8-second request timeout.
  static const Duration pureTrackFreshness = Duration(seconds: 15);

  DateTime? _offlineSince;
  bool _everOnline = false;

  @override
  TrafficSourceHealthState build() {
    ref.listen(appSettingsProvider, (_, _) => refresh());
    ref.listen(ognConnectedProvider, (_, _) => refresh());
    ref.listen(pureTrackProvider, (_, _) => refresh());
    ref.listen<TelemetryState>(telemetryProvider, (_, _) => refresh());
    return _evaluate(clock.now());
  }

  /// Re-evaluates the offline grace window.
  void refresh() {
    if (!ref.mounted) return;
    final next = _evaluate(clock.now());
    if (next != state) state = next;
  }

  TrafficSourceHealthState _evaluate(DateTime now) {
    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) return const TrafficSourceHealthState();

    final enabled = _sourcesEnabled(settings);
    if (!enabled) {
      _everOnline = false;
      _offlineSince = null;
      return const TrafficSourceHealthState();
    }

    final anyOnline = _anyOnline(settings, now);
    if (anyOnline) {
      _everOnline = true;
      _offlineSince = null;
    } else if (_everOnline) {
      _offlineSince ??= now;
    }

    return TrafficSourceHealthState(
      unavailable: evaluateTrafficSourceUnavailable(
        now: now,
        enabled: enabled,
        anyOnline: anyOnline,
        everOnline: _everOnline,
        isFlying: ref.read(telemetryProvider).isFlying,
        offlineSince: _offlineSince,
      ),
    );
  }

  bool _sourcesEnabled(AppSettings settings) {
    return settings.ognEnabled ||
        settings.pureTrackEnabled ||
        settings.gdl90Enabled;
  }

  bool _anyOnline(AppSettings settings, DateTime now) {
    final ognOnline = settings.ognEnabled && ref.read(ognConnectedProvider);
    final lastPureTrackPoll = settings.pureTrackEnabled
        ? ref.read(pureTrackStreamServiceProvider).lastSuccessfulPollAt
        : null;
    final pureTrackOnline =
        lastPureTrackPoll != null &&
        now.difference(lastPureTrackPoll) < pureTrackFreshness;
    final gdl90Online =
        settings.gdl90Enabled &&
        ref.read(gdl90ServiceProvider).isHeartbeatActive;
    return ognOnline || pureTrackOnline || gdl90Online;
  }
}
