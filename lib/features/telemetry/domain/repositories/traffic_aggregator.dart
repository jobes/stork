import 'package:flutter/foundation.dart';
import '../models/traffic_aircraft.dart';
import '../utils/canonical_id.dart';

class TrafficAggregator {
  final Map<String, TrafficAircraft> _targets = {};

  /// Returns unmodifiable list of current aggregated aircraft targets
  List<TrafficAircraft> get targets => List.unmodifiable(_targets.values);

  /// Map of canonical IDs to target states
  Map<String, TrafficAircraft> get targetMap => Map.unmodifiable(_targets);

  /// Processes an incoming OGN aircraft packet with T_sent position arbitration
  void processOgnUpdate(TrafficAircraft rawAircraft) {
    processAircraftUpdate(rawAircraft, source: 'ogn');
  }

  /// Processes an incoming PureTrack aircraft packet with T_sent position arbitration
  void processPureTrackUpdate(TrafficAircraft rawAircraft) {
    processAircraftUpdate(rawAircraft, source: 'puretrack');
  }

  /// Processes an incoming aircraft update from any telemetry source with T_sent position arbitration
  void processAircraftUpdate(
    TrafficAircraft rawAircraft, {
    required String source,
  }) {
    final canonicalId = CanonicalId.normalize(rawAircraft.id);
    if (canonicalId.isEmpty) return;

    final now = DateTime.now();
    var tSent = rawAircraft.lastSeen;

    // Transmitter Clock Drift Check:
    // If onboard device reports a timestamp > T_local + 60s, clamp to T_local
    if (tSent.isAfter(now.add(const Duration(seconds: 60)))) {
      tSent = now;
    }

    final existing = _targets[canonicalId];

    if (existing == null) {
      _targets[canonicalId] = rawAircraft.copyWith(
        id: canonicalId,
        lastSeen: tSent,
        sources: {source},
        activeSource: source,
      );
      debugPrint(
        '[TrafficAggregator] [$source ADD] ID: $canonicalId (${rawAircraft.callsign}) | Total targets in DB: ${_targets.length}',
      );
    } else {
      final updatedSources = {...existing.sources, source};

      // T_sent arbitration rule: only update position & dynamic fields if tSent is strictly newer
      if (tSent.isAfter(existing.lastSeen)) {
        _targets[canonicalId] = existing.copyWith(
          callsign: rawAircraft.callsign.isNotEmpty
              ? rawAircraft.callsign
              : existing.callsign,
          registration: rawAircraft.registration ?? existing.registration,
          aircraftModel: rawAircraft.aircraftModel ?? existing.aircraftModel,
          cn: rawAircraft.cn ?? existing.cn,
          latitude: rawAircraft.latitude,
          longitude: rawAircraft.longitude,
          altitude: rawAircraft.altitude,
          track: rawAircraft.track,
          groundSpeed: rawAircraft.groundSpeed,
          verticalSpeed: rawAircraft.verticalSpeed,
          aircraftType: rawAircraft.aircraftType != 0
              ? rawAircraft.aircraftType
              : existing.aircraftType,
          lastSeen: tSent,
          isAnonymous: rawAircraft.isAnonymous,
          sources: updatedSources,
          activeSource: source,
        );
        debugPrint(
          '[TrafficAggregator] [$source UPDATE] ID: $canonicalId (${rawAircraft.callsign}) | Fix timestamp advanced to $tSent | Total targets in DB: ${_targets.length}',
        );
      } else {
        // Discard unchanged or stale position update, but preserve metadata
        _targets[canonicalId] = existing.copyWith(
          registration: existing.registration ?? rawAircraft.registration,
          aircraftModel: existing.aircraftModel ?? rawAircraft.aircraftModel,
          cn: existing.cn ?? rawAircraft.cn,
          sources: updatedSources,
        );
      }
    }
  }

  /// Updates computed fields (turnRate, isCircling) on an existing target without changing activeSource or position arbitration
  void updateComputedFields(
    String canonicalId, {
    double? turnRate,
    bool? isCircling,
  }) {
    final existing = _targets[canonicalId];
    if (existing != null) {
      _targets[canonicalId] = existing.copyWith(
        turnRate: turnRate ?? existing.turnRate,
        isCircling: isCircling ?? existing.isCircling,
      );
    }
  }

  /// Purges targets whose T_sent fix timestamp is older than maxAge (default 3 minutes)
  int purgeStaleTargets({Duration maxAge = const Duration(minutes: 3)}) {
    if (_targets.isEmpty) return 0;
    final now = DateTime.now();
    final staleKeys = <String>[];

    for (final entry in _targets.entries) {
      if (now.difference(entry.value.lastSeen) > maxAge) {
        staleKeys.add(entry.key);
      }
    }

    for (final key in staleKeys) {
      _targets.remove(key);
    }

    if (staleKeys.isNotEmpty) {
      debugPrint(
        '[TrafficAggregator] [PURGE STALE] Purged ${staleKeys.length} stale targets | Remaining in DB: ${_targets.length}',
      );
    }

    return staleKeys.length;
  }

  /// Purges targets that fall outside the specified bounding box
  int purgeTargetsOutside({
    required double latNorth,
    required double lonWest,
    required double latSouth,
    required double lonEast,
  }) {
    if (_targets.isEmpty) return 0;
    final staleKeys = <String>[];

    for (final entry in _targets.entries) {
      final ac = entry.value;
      if (ac.latitude > latNorth ||
          ac.latitude < latSouth ||
          ac.longitude < lonWest ||
          ac.longitude > lonEast) {
        staleKeys.add(entry.key);
      }
    }

    for (final key in staleKeys) {
      _targets.remove(key);
    }

    if (staleKeys.isNotEmpty) {
      debugPrint(
        '[TrafficAggregator] [PURGE OUT OF BOUNDS] Removed ${staleKeys.length} targets outside viewport | Remaining in DB: ${_targets.length}',
      );
    }

    return staleKeys.length;
  }

  /// Clears all stored targets
  void clear() {
    _targets.clear();
  }
}
