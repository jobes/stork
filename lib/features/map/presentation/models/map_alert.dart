import 'package:flutter/foundation.dart';

import '../../../settings/domain/models/range_thresholds.dart';
import '../../../telemetry/domain/models/telemetry_instrument.dart';

/// Importance of a map alert. Used for both ordering and visual treatment.
enum MapAlertSeverity { critical, warning, info }

/// Every condition the map status indicator can report.
///
/// The declaration order breaks ties between equally severe conditions.
enum MapAlertKind {
  collisionThreat(MapAlertSeverity.critical),
  telemetryLinkLost(MapAlertSeverity.critical),
  telemetryStale(MapAlertSeverity.warning),
  oilTemperature(
    MapAlertSeverity.warning,
    instrument: TelemetryInstrument.oilTemperature,
  ),
  cylinderTemperature(
    MapAlertSeverity.warning,
    instrument: TelemetryInstrument.cylinderTemperature,
  ),
  exhaustTemperature(
    MapAlertSeverity.warning,
    instrument: TelemetryInstrument.exhaustTemperature,
  ),
  oilPressure(
    MapAlertSeverity.warning,
    instrument: TelemetryInstrument.oilPressure,
  ),
  engineRpm(MapAlertSeverity.warning, instrument: TelemetryInstrument.rpm),
  fuelLevel(MapAlertSeverity.warning, instrument: TelemetryInstrument.fuel),
  flightSpeed(MapAlertSeverity.warning, instrument: TelemetryInstrument.speed),
  radio(MapAlertSeverity.warning, instrument: TelemetryInstrument.radio),
  mapStyleUnavailable(MapAlertSeverity.critical),
  gpsPermissionDenied(MapAlertSeverity.critical),
  locationServicesDisabled(MapAlertSeverity.critical),
  gpsStreamError(MapAlertSeverity.critical),
  gpsFixLost(MapAlertSeverity.critical),
  gpsNoFix(MapAlertSeverity.critical),
  altitudeUnavailable(MapAlertSeverity.critical),
  trafficSourceOffline(MapAlertSeverity.warning),
  // A missing airspace download is an operational consequence, so it ranks
  // above the network link that most likely caused it.
  airspaceDataUnavailable(MapAlertSeverity.warning),
  // The app is offline-first and a glider often flies without mobile data, so
  // a missing network link is informational rather than a warning.
  internetUnavailable(MapAlertSeverity.info),
  terrainUnavailable(MapAlertSeverity.warning),
  offlineMapsError(MapAlertSeverity.warning),
  droneCanGpsFallback(MapAlertSeverity.warning),
  altitudeSourceChanged(MapAlertSeverity.info);

  const MapAlertKind(this.severity, {this.instrument});

  final MapAlertSeverity severity;
  final TelemetryInstrument? instrument;
}

/// One active condition shown by the map status indicator.
@immutable
class MapAlert {
  const MapAlert({
    required this.kind,
    required this.since,
    this.instrumentIssue,
  });

  final MapAlertKind kind;
  final InstrumentIssue? instrumentIssue;

  /// When the condition started, so the dialog can tell the pilot how long it
  /// has been active.
  final DateTime since;

  MapAlertSeverity get severity => switch (instrumentIssue?.state) {
    ThresholdState.minError ||
    ThresholdState.maxError => MapAlertSeverity.critical,
    _ => kind.severity,
  };

  bool get isEngineOverheating =>
      instrumentIssue?.state == ThresholdState.maxError &&
      instrumentIssue?.unavailable == false &&
      (kind == MapAlertKind.oilTemperature ||
          kind == MapAlertKind.cylinderTemperature ||
          kind == MapAlertKind.exhaustTemperature);

  int comparePriority(MapAlert other) {
    final bySeverity = severity.index.compareTo(other.severity.index);
    if (bySeverity != 0) return bySeverity;
    final byUrgency = _urgentPriority.compareTo(other._urgentPriority);
    return byUrgency != 0 ? byUrgency : kind.index.compareTo(other.kind.index);
  }

  int get _urgentPriority => switch (this) {
    // The aircraft link supplies the measurements behind the engine alerts.
    MapAlert(
      kind: MapAlertKind.collisionThreat || MapAlertKind.telemetryLinkLost,
    ) =>
      0,
    MapAlert(isEngineOverheating: true) => 1,
    _ => 2,
  };

  @override
  bool operator ==(Object other) =>
      other is MapAlert &&
      other.kind == kind &&
      other.since == since &&
      other.instrumentIssue == instrumentIssue;

  @override
  int get hashCode => Object.hash(kind, since, instrumentIssue);

  @override
  String toString() => 'MapAlert(kind: $kind, since: $since)';
}

/// Picks the most important active condition.
///
/// The indicator deliberately shows only one condition at a time: the most
/// severe active one. Less important conditions become visible automatically
/// once the more important ones clear, which keeps the map uncluttered during
/// flight.
///
/// Severity outranks the declaration order so a warning can never hide a
/// critical condition, and an informational hint can never hide a warning.
MapAlertKind? mostImportantAlert(Set<MapAlertKind> active) {
  return prioritizedAlertKinds(active).firstOrNull;
}

Iterable<MapAlertKind> prioritizedAlertKinds(Set<MapAlertKind> active) sync* {
  for (final severity in MapAlertSeverity.values) {
    yield* MapAlertKind.values.where(
      (kind) => kind.severity == severity && active.contains(kind),
    );
  }
}
