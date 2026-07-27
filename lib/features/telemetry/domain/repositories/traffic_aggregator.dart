import 'package:flutter/foundation.dart';
import '../../data/ogn_aprs_service.dart';
import '../../data/puretrack_stream_service.dart';
import '../../../settings/domain/models/aircraft_type.dart';
import '../utils/canonical_id.dart';

class TrafficAggregator {
  final Map<String, OgnTrafficAircraft> _targets = {};

  /// Returns unmodifiable list of current aggregated aircraft targets
  List<OgnTrafficAircraft> get targets => List.unmodifiable(_targets.values);

  /// Map of canonical IDs to target states
  Map<String, OgnTrafficAircraft> get targetMap => Map.unmodifiable(_targets);

  /// Processes an incoming OGN aircraft packet with T_sent position arbitration
  void processOgnUpdate(OgnTrafficAircraft rawAircraft) {
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
        sources: {'ogn'},
        activeSource: 'ogn',
      );
      debugPrint('[TrafficAggregator] [OGN ADD] ID: $canonicalId (${rawAircraft.callsign}) | Total targets in DB: ${_targets.length}');
    } else {
      final updatedSources = {...existing.sources, 'ogn'};

      // T_sent arbitration rule: only update position & dynamic fields if tSent is strictly newer
      if (tSent.isAfter(existing.lastSeen)) {
        _targets[canonicalId] = existing.copyWith(
          callsign: rawAircraft.callsign.isNotEmpty ? rawAircraft.callsign : existing.callsign,
          registration: rawAircraft.registration ?? existing.registration,
          aircraftModel: rawAircraft.aircraftModel ?? existing.aircraftModel,
          cn: rawAircraft.cn ?? existing.cn,
          latitude: rawAircraft.latitude,
          longitude: rawAircraft.longitude,
          altitude: rawAircraft.altitude,
          track: rawAircraft.track,
          groundSpeed: rawAircraft.groundSpeed,
          verticalSpeed: rawAircraft.verticalSpeed,
          aircraftType: rawAircraft.aircraftType != 0 ? rawAircraft.aircraftType : existing.aircraftType,
          lastSeen: tSent,
          isAnonymous: rawAircraft.isAnonymous,
          sources: updatedSources,
          activeSource: 'ogn',
        );
        debugPrint('[TrafficAggregator] [OGN UPDATE] ID: $canonicalId (${rawAircraft.callsign}) | Fix timestamp advanced to $tSent | Total targets in DB: ${_targets.length}');
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

  /// Processes an incoming PureTrack telemetry packet with T_sent position arbitration
  void processPureTrackPacket(PureTrackPacket packet) {
    final canonicalId = packet.canonicalId;
    if (canonicalId.isEmpty) return;

    final now = DateTime.now();
    var tSent = packet.tSent;

    // Transmitter Clock Drift Check:
    // If onboard device reports a timestamp > T_local + 60s, clamp to T_local
    if (tSent.isAfter(now.add(const Duration(seconds: 60)))) {
      tSent = now;
    }

    final existing = _targets[canonicalId];
    final mappedType = AircraftType.fromPureTrackType(packet.aircraftType).ognCode;

    if (existing == null) {
      _targets[canonicalId] = OgnTrafficAircraft(
        id: canonicalId,
        callsign: packet.callsign,
        registration: packet.registration,
        aircraftModel: packet.model,
        cn: packet.cn,
        latitude: packet.latitude,
        longitude: packet.longitude,
        altitude: packet.altitude,
        track: packet.track,
        groundSpeed: packet.groundSpeed,
        verticalSpeed: packet.verticalSpeed,
        aircraftType: mappedType,
        lastSeen: tSent,
        sources: {'puretrack'},
        activeSource: 'puretrack',
      );
      debugPrint('[TrafficAggregator] [PureTrack ADD] ID: $canonicalId (${packet.callsign}) | Total targets in DB: ${_targets.length}');
    } else {
      final updatedSources = {...existing.sources, 'puretrack'};

      // T_sent arbitration rule: only update position & dynamic fields if tSent is strictly newer
      if (tSent.isAfter(existing.lastSeen)) {
        _targets[canonicalId] = existing.copyWith(
          callsign: packet.callsign.isNotEmpty ? packet.callsign : existing.callsign,
          registration: packet.registration ?? existing.registration,
          aircraftModel: packet.model ?? existing.aircraftModel,
          cn: packet.cn ?? existing.cn,
          latitude: packet.latitude,
          longitude: packet.longitude,
          altitude: packet.altitude,
          track: packet.track,
          groundSpeed: packet.groundSpeed,
          verticalSpeed: packet.verticalSpeed,
          aircraftType: mappedType != 0 ? mappedType : existing.aircraftType,
          lastSeen: tSent,
          sources: updatedSources,
          activeSource: 'puretrack',
        );
        debugPrint('[TrafficAggregator] [PureTrack UPDATE] ID: $canonicalId (${packet.callsign}) | Fix timestamp advanced to $tSent | Total targets in DB: ${_targets.length}');
      } else {
        // Discard unchanged or stale position update, but preserve metadata
        _targets[canonicalId] = existing.copyWith(
          registration: existing.registration ?? packet.registration,
          aircraftModel: existing.aircraftModel ?? packet.model,
          cn: existing.cn ?? packet.cn,
          sources: updatedSources,
        );
      }
    }
  }

  /// Updates computed fields (turnRate, isCircling) on an existing target without changing activeSource or position arbitration
  void updateComputedFields(String canonicalId, {double? turnRate, bool? isCircling}) {
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
      debugPrint('[TrafficAggregator] [PURGE STALE] Purged ${staleKeys.length} stale targets | Remaining in DB: ${_targets.length}');
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
      debugPrint('[TrafficAggregator] [PURGE OUT OF BOUNDS] Removed ${staleKeys.length} targets outside viewport | Remaining in DB: ${_targets.length}');
    }

    return staleKeys.length;
  }

  /// Clears all stored targets
  void clear() {
    _targets.clear();
  }
}
