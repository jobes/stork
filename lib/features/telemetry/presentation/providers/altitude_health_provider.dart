import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/resolved_altitude.dart';
import 'agl_provider.dart';
import 'telemetry_provider.dart';

part 'altitude_health_provider.g.dart';

/// Whether terrain elevation is missing long enough to warn the pilot.
@visibleForTesting
bool evaluateTerrainUnavailable({
  required DateTime now,
  required bool isFlying,
  required bool hasMslAltitude,
  required bool hasTerrainElevation,
  required bool isFetching,
  required DateTime? missingSince,
  Duration grace = AltitudeHealth.terrainGrace,
}) {
  if (!isFlying || !hasMslAltitude || hasTerrainElevation || isFetching) {
    return false;
  }
  if (missingSince == null) return false;
  return now.difference(missingSince) >= grace;
}

/// Altitude- and terrain-related conditions shown on the map.
@immutable
class AltitudeHealthState {
  const AltitudeHealthState({
    this.altitudeUnavailable = false,
    this.terrainUnavailable = false,
    this.sourceChanged = false,
  });

  final bool altitudeUnavailable;
  final bool terrainUnavailable;
  final bool sourceChanged;

  bool get hasIssue =>
      altitudeUnavailable || terrainUnavailable || sourceChanged;

  @override
  bool operator ==(Object other) =>
      other is AltitudeHealthState &&
      other.altitudeUnavailable == altitudeUnavailable &&
      other.terrainUnavailable == terrainUnavailable &&
      other.sourceChanged == sourceChanged;

  @override
  int get hashCode =>
      Object.hash(altitudeUnavailable, terrainUnavailable, sourceChanged);

  @override
  String toString() =>
      'AltitudeHealthState(altitudeUnavailable: $altitudeUnavailable, '
      'terrainUnavailable: $terrainUnavailable, sourceChanged: $sourceChanged)';
}

/// Watches the resolved altitude, terrain elevation and altitude-source
/// transitions.
@riverpod
class AltitudeHealth extends _$AltitudeHealth {
  static const Duration terrainGrace = Duration(seconds: 5);
  static const Duration sourceChangedDuration = Duration(seconds: 20);

  DateTime? _terrainMissingSince;
  DateTime? _sourceChangedAt;
  AltitudeSource? _previousSource;

  @override
  AltitudeHealthState build() {
    _previousSource = ref.read(aglProvider).resolvedAltitude.source;

    ref.listen(aglProvider, (_, _) => refresh());
    ref.listen<TelemetryState>(telemetryProvider, (_, _) => refresh());
    return _evaluate(clock.now());
  }

  /// Re-evaluates the terrain grace window and the source-change notice.
  void refresh() {
    if (!ref.mounted) return;
    final next = _evaluate(clock.now());
    if (next != state) state = next;
  }

  AltitudeHealthState _evaluate(DateTime now) {
    final agl = ref.read(aglProvider);
    final telemetry = ref.read(telemetryProvider);
    final resolution = agl.resolvedAltitude;
    final source = resolution.source;
    final mslValue = resolution.mslValue;
    final previousSource = _previousSource;

    if (telemetry.isFlying &&
        previousSource != null &&
        previousSource != source &&
        previousSource != AltitudeSource.none &&
        source != AltitudeSource.none) {
      _sourceChangedAt = now;
    }
    _previousSource = source;

    if (telemetry.isFlying &&
        mslValue != null &&
        agl.terrainElevation == null &&
        !agl.isFetching) {
      _terrainMissingSince ??= now;
    } else {
      _terrainMissingSince = null;
    }

    final missingSince = _terrainMissingSince;
    final changedAt = _sourceChangedAt;

    return AltitudeHealthState(
      altitudeUnavailable: telemetry.isFlying && source == AltitudeSource.none,
      terrainUnavailable: evaluateTerrainUnavailable(
        now: now,
        isFlying: telemetry.isFlying,
        hasMslAltitude: mslValue != null,
        hasTerrainElevation: agl.terrainElevation != null,
        isFetching: agl.isFetching,
        missingSince: missingSince,
      ),
      sourceChanged:
          telemetry.isFlying &&
          changedAt != null &&
          now.difference(changedAt) < sourceChangedDuration,
    );
  }
}
