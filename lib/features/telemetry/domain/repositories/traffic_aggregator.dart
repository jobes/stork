import 'package:flutter/foundation.dart';
import '../models/traffic_aircraft.dart';
import '../utils/canonical_id.dart';

class TrafficAggregator {
  final Map<String, TrafficAircraft> _targets = {};

  /// Returns unmodifiable list of current aggregated aircraft targets
  List<TrafficAircraft> get targets => List.unmodifiable(_targets.values);

  /// Map of canonical IDs to target states
  Map<String, TrafficAircraft> get targetMap => Map.unmodifiable(_targets);

  /// Processes an incoming OGN aircraft packet with T_sent position arbitration.
  /// Returns the canonical ID under which the aircraft is stored (the existing
  /// key when an ICAO merge occurs, otherwise the normalized incoming ID).
  String processOgnUpdate(TrafficAircraft rawAircraft) {
    return processAircraftUpdate(rawAircraft, source: 'ogn');
  }

  /// Processes an incoming PureTrack aircraft packet with T_sent position
  /// arbitration. Returns the canonical ID under which the aircraft is stored.
  String processPureTrackUpdate(TrafficAircraft rawAircraft) {
    return processAircraftUpdate(rawAircraft, source: 'puretrack');
  }

  /// Processes an incoming GDL90 aircraft packet with T_sent position
  /// arbitration. Returns the canonical ID under which the aircraft is stored.
  String processGdl90Update(TrafficAircraft rawAircraft) {
    return processAircraftUpdate(rawAircraft, source: 'gdl90');
  }

  /// Processes an incoming aircraft update from any telemetry source with
  /// T_sent position arbitration. Returns the canonical ID under which the
  /// aircraft is stored (the existing key when an ICAO merge occurs, otherwise
  /// the normalized incoming ID).
  String processAircraftUpdate(
    TrafficAircraft rawAircraft, {
    required String source,
  }) {
    final canonicalId = CanonicalId.normalize(rawAircraft.id);
    if (canonicalId.isEmpty) return canonicalId;

    final now = DateTime.now();
    var tSent = rawAircraft.lastSeen;

    // Transmitter Clock Drift Check:
    // If onboard device reports a timestamp > T_local + 60s, clamp to T_local
    if (tSent.isAfter(now.add(const Duration(seconds: 60)))) {
      tSent = now;
    }

    var existing = _targets[canonicalId];
    var existingKey = canonicalId;

    // Cross-source deduplication by ICAO 24-bit hex address:
    // When a new source reports an aircraft with a known ICAO (e.g. GDL90
    // sends id=166752), search for an existing target from another source
    // that shares the same ICAO but a different canonical ID (e.g. OGN
    // uses FLARM id FLRDDA5E6 for the same physical aircraft).
    if (existing == null && rawAircraft.icaoHex != null) {
      final icaoNormalized = rawAircraft.icaoHex!.toLowerCase();
      for (final entry in _targets.entries) {
        if (entry.value.icaoHex?.toLowerCase() == icaoNormalized) {
          // Found a match by ICAO — merge this new source into the existing
          // target using the existing canonical ID as the key, so the same
          // aircraft never appears twice on the map.
          existing = entry.value;
          existingKey = entry.key;
          debugPrint(
            '[TrafficAggregator] [$source ICAO-MERGE] GDL90 id=$canonicalId '
            'matched existing OGN id=${entry.key} via ICAO $icaoNormalized',
          );
          break;
        }
      }
    }

    if (existing == null) {
      _targets[canonicalId] = rawAircraft.copyWith(
        id: canonicalId,
        lastSeen: tSent,
        sources: {source},
        activeSource: source,
      );
    } else {
      final updatedSources = {...existing.sources, source};

      // T_sent arbitration rule: only update position & dynamic fields if tSent is strictly newer
      if (tSent.isAfter(existing.lastSeen)) {
        // When a source reports a field as unavailable (e.g. GDL90 0xFFF
        // altitude), keep the previously known value instead of resetting it
        // to 0, and record the validity flag for the UI.
        _targets[existingKey] = existing.copyWith(
          callsign: rawAircraft.callsign.isNotEmpty
              ? rawAircraft.callsign
              : existing.callsign,
          registration: rawAircraft.registration ?? existing.registration,
          aircraftModel: rawAircraft.aircraftModel ?? existing.aircraftModel,
          cn: rawAircraft.cn ?? existing.cn,
          latitude: rawAircraft.latitude,
          longitude: rawAircraft.longitude,
          altitude: rawAircraft.altitudeValid
              ? rawAircraft.altitude
              : existing.altitude,
          track: rawAircraft.track,
          groundSpeed: rawAircraft.speedValid
              ? rawAircraft.groundSpeed
              : existing.groundSpeed,
          verticalSpeed: rawAircraft.verticalSpeedValid
              ? rawAircraft.verticalSpeed
              : existing.verticalSpeed,
          aircraftType: rawAircraft.aircraftType != 0
              ? rawAircraft.aircraftType
              : existing.aircraftType,
          lastSeen: tSent,
          isAnonymous: rawAircraft.isAnonymous,
          icaoHex: existing.icaoHex ?? rawAircraft.icaoHex,
          altitudeValid: rawAircraft.altitudeValid,
          speedValid: rawAircraft.speedValid,
          verticalSpeedValid: rawAircraft.verticalSpeedValid,
          sources: updatedSources,
          activeSource: source,
        );
      } else {
        // Discard unchanged or stale position update, but preserve metadata
        _targets[existingKey] = existing.copyWith(
          registration: existing.registration ?? rawAircraft.registration,
          aircraftModel: existing.aircraftModel ?? rawAircraft.aircraftModel,
          cn: existing.cn ?? rawAircraft.cn,
          icaoHex: existing.icaoHex ?? rawAircraft.icaoHex,
          sources: updatedSources,
        );
      }
    }

    return existingKey;
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

  /// Purges targets whose T_sent fix timestamp is older than maxAge (default 15 minutes)
  List<String> purgeStaleTargets({
    Duration maxAge = const Duration(minutes: 15),
  }) {
    if (_targets.isEmpty) return const [];
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

    return staleKeys;
  }

  /// Purges targets that fall outside the specified bounding box
  List<String> purgeTargetsOutside({
    required double latNorth,
    required double lonWest,
    required double latSouth,
    required double lonEast,
  }) {
    if (_targets.isEmpty) return const [];
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

    return staleKeys;
  }

  /// Purges a source from all target aircraft. If an aircraft has no remaining sources, it is removed.
  List<String> purgeSource(String source) {
    if (_targets.isEmpty) return const [];
    final removedKeys = <String>[];

    for (final entry in List.of(_targets.entries)) {
      final key = entry.key;
      final ac = entry.value;
      if (ac.sources.contains(source)) {
        final updatedSources = Set<String>.from(ac.sources)..remove(source);
        if (updatedSources.isEmpty) {
          _targets.remove(key);
          removedKeys.add(key);
        } else {
          final newActiveSource = ac.activeSource == source
              ? updatedSources.first
              : ac.activeSource;
          _targets[key] = ac.copyWith(
            sources: updatedSources,
            activeSource: newActiveSource,
          );
        }
      }
    }

    if (removedKeys.isNotEmpty) {
      debugPrint(
        '[TrafficAggregator] [PURGE SOURCE: $source] Removed ${removedKeys.length} targets | Remaining in DB: ${_targets.length}',
      );
    }

    return removedKeys;
  }

  /// Removes [source] only from targets whose ICAO hex address matches
  /// [icaoHex] — used when a live source (e.g. GDL90) drops a single target.
  /// If an aircraft ends up with no remaining sources, it is removed entirely.
  List<String> purgeSourceFromIcao(String source, String icaoHex) {
    if (_targets.isEmpty) return const [];
    final normalized = icaoHex.toLowerCase();
    final removedKeys = <String>[];

    for (final entry in List.of(_targets.entries)) {
      final key = entry.key;
      final ac = entry.value;
      if (ac.sources.contains(source) &&
          ac.icaoHex?.toLowerCase() == normalized) {
        final updatedSources = Set<String>.from(ac.sources)..remove(source);
        if (updatedSources.isEmpty) {
          _targets.remove(key);
          removedKeys.add(key);
        } else {
          final newActiveSource = ac.activeSource == source
              ? updatedSources.first
              : ac.activeSource;
          _targets[key] = ac.copyWith(
            sources: updatedSources,
            activeSource: newActiveSource,
          );
        }
      }
    }

    return removedKeys;
  }

  /// Clears all stored targets
  void clear() {
    _targets.clear();
  }
}
