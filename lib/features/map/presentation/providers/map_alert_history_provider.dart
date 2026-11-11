import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../settings/domain/models/range_thresholds.dart';
import '../../../telemetry/domain/models/telemetry_instrument.dart';
import '../../../telemetry/presentation/providers/instrument_status_provider.dart';
import '../models/map_alert.dart';

final mapAlertHistoryProvider =
    NotifierProvider<MapAlertHistory, List<MapAlertHistoryEntry>>(
      MapAlertHistory.new,
    );

class MapAlertHistoryEntry {
  const MapAlertHistoryEntry({
    required this.id,
    required this.alert,
    this.peak,
    this.endedAt,
  });

  final String id;

  final MapAlert alert;
  final double? peak;
  final DateTime? endedAt;
}

enum _Band { status, low, high, missing }

typedef _Observation = ({MapAlert alert, double? peak});

typedef _AlertKey = ({MapAlertKind kind, int? channel, _Band band});

/// Keeps episodes for the current app session, including time on the ground.
class MapAlertHistory extends Notifier<List<MapAlertHistoryEntry>> {
  final _active = <_AlertKey, MapAlertHistoryEntry>{};
  final _completed = <MapAlertHistoryEntry>[];
  bool _observingInstruments = false;

  late StreamController<MapAlertHistoryEntry> _changes;
  Stream<MapAlertHistoryEntry> get changes => _changes.stream;

  @override
  List<MapAlertHistoryEntry> build() {
    final changes = StreamController<MapAlertHistoryEntry>.broadcast(
      sync: true,
    );
    _changes = changes;
    ref.onDispose(changes.close);
    return const [];
  }

  bool _startObservingInstruments(DateTime now) {
    if (_observingInstruments) return false;
    _observingInstruments = true;
    for (final kind in MapAlertKind.values.where(_hasReadings)) {
      final provider = instrumentStatusProvider(kind.instrument!);
      _syncInstrument(kind, ref.read(provider), now);
      ref.listen(provider, (_, next) {
        if (_syncInstrument(kind, next, clock.now())) state = _snapshot();
      });
    }
    return _active.isNotEmpty;
  }

  static bool _hasReadings(MapAlertKind kind) =>
      kind.instrument != null && kind.instrument != TelemetryInstrument.radio;

  void observeSystemAlerts(List<MapAlert> alerts, DateTime now) {
    final instrumentsAdded = _startObservingInstruments(now);
    final current = {
      for (final alert in alerts.where((alert) => !_hasReadings(alert.kind)))
        (
          kind: alert.kind,
          channel: null,
          band: alert.instrumentIssue?.unavailable == true
              ? _Band.missing
              : _Band.status,
        ): (
          peak: null,
          alert: MapAlert(
            kind: alert.kind,
            since: now,
            instrumentIssue: alert.instrumentIssue,
          ),
        ),
    };
    final systemChanged = _sync(current, (key) => !_hasReadings(key.kind), now);
    if (systemChanged || instrumentsAdded) {
      state = _snapshot();
    }
  }

  bool _syncInstrument(
    MapAlertKind kind,
    InstrumentStatus status,
    DateTime now,
  ) {
    final current = <_AlertKey, _Observation>{};
    if (status.supported) {
      for (final reading in status.alertReadings) {
        final issue = reading.issue;
        final band = issue.unavailable
            ? _Band.missing
            : switch (issue.state) {
                ThresholdState.minWarning ||
                ThresholdState.minError => _Band.low,
                _ => _Band.high,
              };
        current[(kind: kind, channel: issue.channel, band: band)] = (
          alert: MapAlert(kind: kind, since: now, instrumentIssue: issue),
          peak: reading.value?.isFinite == true ? reading.value : null,
        );
      }
    }
    return _sync(current, (key) => key.kind == kind, now);
  }

  bool _sync(
    Map<_AlertKey, _Observation> current,
    bool Function(_AlertKey) inScope,
    DateTime now,
  ) {
    var changed = false;
    _active.removeWhere((key, entry) {
      if (!inScope(key) || current.containsKey(key)) return false;
      final ended = MapAlertHistoryEntry(
        id: entry.id,
        alert: entry.alert,
        peak: entry.peak,
        endedAt: now.isBefore(entry.alert.since) ? entry.alert.since : now,
      );
      _completed.add(ended);
      _changes.add(ended);
      changed = true;
      return true;
    });

    for (final MapEntry(key: key, value: next) in current.entries) {
      final previous = _active[key];
      if (previous == null) {
        final started = MapAlertHistoryEntry(
          id: const Uuid().v4(),
          alert: next.alert,
          peak: next.peak,
        );
        _active[key] = started;
        _changes.add(started);
        changed = true;
        continue;
      }
      final escalated =
          next.alert.severity.index < previous.alert.severity.index;
      final value = next.peak;
      final oldPeak = previous.peak;
      final newPeak =
          value != null &&
          (oldPeak == null ||
              (key.band == _Band.low ? value < oldPeak : value > oldPeak));
      if (!escalated && !newPeak) continue;
      final updated = MapAlertHistoryEntry(
        id: previous.id,
        alert: escalated
            ? MapAlert(
                kind: key.kind,
                since: previous.alert.since,
                instrumentIssue: next.alert.instrumentIssue,
              )
            : previous.alert,
        peak: newPeak ? value : oldPeak,
      );
      _active[key] = updated;
      if (escalated) _changes.add(updated);
      changed = true;
    }
    return changed;
  }

  List<MapAlertHistoryEntry> _snapshot() {
    final entries = [..._active.values, ..._completed]
      ..sort((a, b) => b.alert.since.compareTo(a.alert.since));
    return List.unmodifiable(entries);
  }
}
