import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:maplibre/maplibre.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/domain/models/aircraft.dart';
import '../../../settings/domain/models/aircraft_type.dart';
import '../../domain/models/traffic_aircraft.dart';
export '../../domain/models/traffic_aircraft.dart';
import '../../domain/utils/cas_evaluator.dart';
import 'telemetry_provider.dart';
import 'vario_provider.dart';
import '../../data/ogn_aprs_service.dart';

import '../../domain/repositories/traffic_aggregator.dart';
import '../../domain/utils/canonical_id.dart';
import '../../data/puretrack_stream_service.dart';
import 'puretrack_auth_provider.dart';
import 'agl_provider.dart';
import '../../domain/models/gdl90_target.dart';
import 'gdl90_provider.dart';

part 'traffic_provider.g.dart';

const double kTrafficFilterSignificantShiftMeters = 1500.0;
const Duration kTrafficFilterMaxUnsentDuration = Duration(seconds: 15);
const Duration kTrafficFilterDebounceDuration = Duration(seconds: 1);

@riverpod
OgnAprsService ognAprsService(Ref ref) {
  return OgnAprsService();
}

@Riverpod(keepAlive: true)
class Traffic extends _$Traffic {
  late OgnAprsService _aprsService;
  OgnInboundConnection? _inboundConnection;
  OgnOutboundManager? _outboundManager;
  Timer? _decayTimer;
  Timer? _publishTimer;
  Timer? _outboundTimer;
  Timer? _reconnectTimer;

  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  String? _activeOutboundId;

  final TrafficAggregator _aggregator = TrafficAggregator();
  final List<TrackHistoryPoint> _ownshipTrackHistory = [];

  List<TrackHistoryPoint> get ownshipTrackHistory =>
      List.unmodifiable(_ownshipTrackHistory);

  StreamSubscription<List<Gdl90Target>>? _gdl90Sub;
  final Set<String> _knownGdl90Ids = {};

  @override
  List<TrafficAircraft> build() {
    _aprsService = ref.read(ognAprsServiceProvider);

    // Eagerly read pureTrackProvider so connection state is managed on app start
    ref.read(pureTrackProvider);

    // Eagerly initialize GDL90 service & listen to stream
    _listenToGdl90();

    _decayTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cleanupStaleTraffic(),
    );
    _publishTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => publishState(),
    );

    // Listen to changes in settings & active aircraft OGN config
    ref.listen(appSettingsProvider, (prev, next) {
      _updateOutboundTrackingState();
      final prevOgn = prev?.value?.ognEnabled ?? true;
      final nextOgn = next.value?.ognEnabled ?? true;
      if (prevOgn != nextOgn) {
        if (nextOgn) {
          _connectInbound();
        } else {
          _disconnectInbound();
          purgeSourceTraffic('ogn');
        }
      }

      final prevPt = prev?.value?.pureTrackEnabled ?? true;
      final nextPt = next.value?.pureTrackEnabled ?? true;
      if (prevPt != nextPt && !nextPt) {
        purgeSourceTraffic('puretrack');
      }

      final prevGdl = prev?.value?.gdl90Enabled ?? true;
      final nextGdl = next.value?.gdl90Enabled ?? true;
      if (prevGdl != nextGdl && !nextGdl) {
        purgeSourceTraffic('gdl90');
      }
    });

    ref.listen(aircraftStateProvider, (prev, next) {
      _updateOutboundTrackingState();
    });

    ref.listen(telemetryProvider, (prev, next) {
      if (next.heading != null) {
        final now = DateTime.now();
        final trackRad = next.heading! * math.pi / 180.0;
        _ownshipTrackHistory.add(
          TrackHistoryPoint(timestamp: now, trackRad: trackRad),
        );
        _ownshipTrackHistory.removeWhere(
          (p) => now.difference(p.timestamp).inSeconds > 15,
        );
      }
    });

    ref.onDispose(() {
      _gdl90Sub?.cancel();
      _decayTimer?.cancel();
      _publishTimer?.cancel();
      _outboundTimer?.cancel();
      _reconnectTimer?.cancel();
      _filterDebounceTimer?.cancel();
      _inboundConnection?.disconnect();
      _outboundManager?.stop();
    });

    final initialSettings = ref.read(appSettingsProvider).value;
    if (initialSettings?.ognEnabled ?? true) {
      _connectInbound();
    }

    return const [];
  }

  void publishState() {
    state = _aggregator.targets;
  }

  void _connectInbound() {
    final settings = ref.read(appSettingsProvider).value;
    if (settings != null && !settings.ognEnabled) return;
    if (_isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();

    _inboundConnection = OgnInboundConnection(
      onLineReceived: (line) {
        try {
          final aircraft = _aprsService.parseAprsLine(line);
          if (aircraft != null) {
            _updateAircraft(aircraft);
          }
        } catch (e) {
          debugPrint('[OGN APRS Parse Error] $e for line: $line');
        }
      },
      onDisconnected: () {
        _isConnecting = false;
        _scheduleReconnect();
      },
    );

    _inboundConnection!
        .connect()
        .then((_) {
          _isConnecting = false;
          _reconnectAttempts = 0;
        })
        .catchError((_) {
          _isConnecting = false;
          _scheduleReconnect();
        });
  }

  void _disconnectInbound() {
    _reconnectTimer?.cancel();
    _inboundConnection?.disconnect(isManual: true);
    _inboundConnection = null;
    _isConnecting = false;
  }

  void _scheduleReconnect() {
    final settings = ref.read(appSettingsProvider).value;
    if (settings != null && !settings.ognEnabled) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 30);
    _reconnectTimer = Timer(
      Duration(seconds: delaySeconds),
      () => _connectInbound(),
    );
  }

  final Map<String, List<TrackHistoryPoint>> _trackHistories = {};

  void _updateAircraft(TrafficAircraft aircraft) {
    final settings = ref.read(appSettingsProvider).value;
    if (settings != null && !settings.ognEnabled) return;

    // The stored key can differ from the incoming id when the aircraft is
    // merged into an existing cross-source entry (e.g. OGN FLARM id vs GDL90
    // ICAO) — always address the aggregator/history by the stored key.
    final storedKey = _aggregator.processOgnUpdate(aircraft);

    final history = _trackHistories.putIfAbsent(storedKey, () => []);
    history.add(
      TrackHistoryPoint(
        timestamp: aircraft.lastSeen,
        trackRad: aircraft.track * math.pi / 180.0,
      ),
    );
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final latestTime = history.last.timestamp;
    history.removeWhere(
      (p) => latestTime.difference(p.timestamp).inSeconds > 15,
    );

    final turnRate = CasEvaluator.calculateTurnRate(history);
    final isCircling = CasEvaluator.detectCircling(history);

    _aggregator.updateComputedFields(
      storedKey,
      turnRate: turnRate,
      isCircling: isCircling,
    );
  }

  void processPureTrackPacket(PureTrackPacket packet) {
    final settings = ref.read(appSettingsProvider).value;
    if (settings != null && !settings.pureTrackEnabled) return;
    final mappedType = AircraftType.fromPureTrackType(
      packet.aircraftType,
    ).ognCode;
    final aircraft = TrafficAircraft(
      id: packet.canonicalId,
      callsign: packet.callsign,
      registration: packet.registration,
      aircraftModel: packet.model,
      cn: packet.cn,
      icaoHex: CanonicalId.isIcaoHex(packet.canonicalId)
          ? packet.canonicalId
          : null,
      latitude: packet.latitude,
      longitude: packet.longitude,
      altitude: packet.altitude,
      track: packet.track,
      groundSpeed: packet.groundSpeed,
      verticalSpeed: packet.verticalSpeed,
      aircraftType: mappedType,
      lastSeen: packet.tSent,
      sources: const {'puretrack'},
      activeSource: 'puretrack',
    );
    final storedKey = _aggregator.processPureTrackUpdate(aircraft);

    final history = _trackHistories.putIfAbsent(storedKey, () => []);
    history.add(
      TrackHistoryPoint(
        timestamp: packet.tSent,
        trackRad: packet.track * math.pi / 180.0,
      ),
    );
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final latestTime = history.last.timestamp;
    history.removeWhere(
      (p) => latestTime.difference(p.timestamp).inSeconds > 15,
    );

    final turnRate = CasEvaluator.calculateTurnRate(history);
    final isCircling = CasEvaluator.detectCircling(history);

    _aggregator.updateComputedFields(
      storedKey,
      turnRate: turnRate,
      isCircling: isCircling,
    );
  }

  void _listenToGdl90() {
    final gdl90Service = ref.read(gdl90ServiceProvider);
    _gdl90Sub?.cancel();
    _gdl90Sub = gdl90Service.targetStream.listen(_processGdl90Targets);
    // Process any targets already received before the stream subscription
    // was set up (broadcast streams don't replay past events).
    _processGdl90Targets(gdl90Service.targets);
  }

  /// Processes the current GDL90 target list and mirrors the service's own
  /// expiry: when the service drops a target, its 'gdl90' source is removed
  /// from the aggregator so the aircraft does not linger on the map until the
  /// much longer aggregator stale-purge.
  void _processGdl90Targets(List<Gdl90Target> targets) {
    final currentIds = <String>{};
    for (final t in targets) {
      currentIds.add(t.id);
      processGdl90Target(t);
    }

    final removedIds = _knownGdl90Ids.difference(currentIds);
    if (removedIds.isNotEmpty) {
      for (final id in removedIds) {
        final purgedKeys = _aggregator.purgeSourceFromIcao('gdl90', id);
        for (final key in purgedKeys) {
          _trackHistories.remove(key);
        }
      }
    }

    // Publish immediately (once per batch) so GDL90 updates/expiries reach the
    // UI without waiting for the periodic publish timer.
    publishState();

    _knownGdl90Ids
      ..clear()
      ..addAll(currentIds);
  }

  void processGdl90Target(Gdl90Target target) {
    final vsMs = target.verticalSpeedFpm * 0.00508;
    final mappedType = _mapGdl90EmitterCategory(target.emitterCategory);

    final aircraft = TrafficAircraft(
      id: target.id,
      callsign: target.callsign ?? target.id,
      icaoHex: target.id, // GDL90 ID is the ICAO 24-bit hex address
      latitude: target.latitude,
      longitude: target.longitude,
      altitude: target.altitudeFeet * 0.3048, // feet -> meters AMSL
      altitudeValid: target.altitudeValid,
      track: target.trackDegrees,
      groundSpeed: target.speedKnots * 0.514444, // kts -> m/s
      speedValid: target.speedValid,
      verticalSpeed: vsMs, // ft/min -> m/s
      verticalSpeedValid: target.verticalSpeedValid,
      aircraftType: mappedType,
      lastSeen: target.lastUpdated,
      sources: const {'gdl90'},
      activeSource: 'gdl90',
    );
    final storedKey = _aggregator.processGdl90Update(aircraft);

    final history = _trackHistories.putIfAbsent(storedKey, () => []);
    history.add(
      TrackHistoryPoint(
        timestamp: target.lastUpdated,
        trackRad: target.trackDegrees * math.pi / 180.0,
      ),
    );
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final latestTime = history.last.timestamp;
    history.removeWhere(
      (p) => latestTime.difference(p.timestamp).inSeconds > 15,
    );

    final turnRate = CasEvaluator.calculateTurnRate(history);
    final isCircling = CasEvaluator.detectCircling(history);

    _aggregator.updateComputedFields(
      storedKey,
      turnRate: turnRate,
      isCircling: isCircling,
    );
  }

  /// Maps a GDL90 Traffic Report emitter category (GDL90 ICD §3.5.1.10) to an
  /// `AircraftType`. Note: the GDL90 table differs from the ADS-B (DO-282)
  /// table — code 8 is reserved, glider is 9, lighter-than-air is 10,
  /// parachutist is 11, ultralight/hang glider/paraglider is 12 and UAV is 14.
  /// SafeSky gliders are transmitted as category 9, so mapping 9 to anything
  /// but `glider` would mislabel them.
  int _mapGdl90EmitterCategory(int cat) {
    return AircraftType.fromGdl90EmitterCategory(cat).ognCode;
  }

  void _cleanupStaleTraffic() {
    final purgedIds = _aggregator.purgeStaleTargets(
      maxAge: const Duration(minutes: 15),
    );
    for (final id in purgedIds) {
      _trackHistories.remove(id);
    }
    if (purgedIds.isNotEmpty) {
      publishState();
    }
  }

  void purgeSourceTraffic(String source) {
    final purgedIds = _aggregator.purgeSource(source);
    for (final id in purgedIds) {
      _trackHistories.remove(id);
    }
    if (source == 'gdl90') {
      _knownGdl90Ids.clear();
    }
    publishState();
  }

  Future<void> loadDdbDetails(String id) async {
    await loadDdbDetailsMultiple([id]);
  }

  Future<void> loadDdbDetailsMultiple(List<String> ids) async {
    final List<String> toFetch = [];
    final targetMap = _aggregator.targetMap;

    for (final id in ids) {
      final canonicalId = CanonicalId.normalize(id);
      final aircraft = targetMap[canonicalId];
      if (aircraft == null) continue;
      if (aircraft.isAnonymous) continue;
      if (aircraft.registration != null && aircraft.registration!.isNotEmpty) {
        continue;
      }
      toFetch.add(id);
    }

    if (toFetch.isEmpty) return;

    final ddbInfos = await _aprsService.lookupDdbMultiple(toFetch);
    if (ddbInfos.isNotEmpty) {
      var stateChanged = false;

      for (final entry in ddbInfos.entries) {
        final id = entry.key;
        final info = entry.value;
        final canonicalId = CanonicalId.normalize(id);
        final existing = _aggregator.targetMap[canonicalId];
        if (existing != null) {
          _aggregator.processOgnUpdate(
            existing.copyWith(
              registration: info['registration'],
              aircraftModel: info['aircraftModel'],
              cn: info['cn'],
            ),
          );
          stateChanged = true;
        }
      }

      if (stateChanged) {
        publishState();
      }
    }
  }

  Timer? _filterDebounceTimer;
  DateTime? _lastFilterSentTime;
  LngLatBounds? _lastSentBounds;

  void updateViewport(LngLatBounds bounds) {
    final now = DateTime.now();
    final timeSinceLastSent = _lastFilterSentTime != null
        ? now.difference(_lastFilterSentTime!)
        : const Duration(seconds: 999);

    bool significantShift = false;
    if (_lastSentBounds != null) {
      final oldCenterLat =
          (_lastSentBounds!.latitudeNorth + _lastSentBounds!.latitudeSouth) / 2;
      final oldCenterLon =
          (_lastSentBounds!.longitudeEast + _lastSentBounds!.longitudeWest) / 2;
      final newCenterLat = (bounds.latitudeNorth + bounds.latitudeSouth) / 2;
      final newCenterLon = (bounds.longitudeEast + bounds.longitudeWest) / 2;

      final dist = GeoUtils.distanceBetween(
        oldCenterLat,
        oldCenterLon,
        newCenterLat,
        newCenterLon,
      );
      // Trigger instant update if camera center shifted significantly (e.g. sharp 180° turn or fast pan)
      if (dist > kTrafficFilterSignificantShiftMeters) {
        significantShift = true;
      }
    }

    // Force immediate filter update if time elapsed >= 15s OR if camera turned/shifted significantly
    if (timeSinceLastSent >= kTrafficFilterMaxUnsentDuration ||
        significantShift) {
      _filterDebounceTimer?.cancel();
      _sendFilter(bounds);
      return;
    }

    // Trailing debounce for minor manual panning/zooming
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(kTrafficFilterDebounceDuration, () {
      _sendFilter(bounds);
    });
  }

  void _sendFilter(LngLatBounds bounds) {
    _lastFilterSentTime = DateTime.now();
    _lastSentBounds = bounds;
    if (_inboundConnection != null) {
      final filterCommand =
          'filter a/${bounds.latitudeNorth.toStringAsFixed(4)}/${bounds.longitudeWest.toStringAsFixed(4)}/${bounds.latitudeSouth.toStringAsFixed(4)}/${bounds.longitudeEast.toStringAsFixed(4)}';
      _inboundConnection!.updateFilter(filterCommand);
    }

    ref
        .read(pureTrackStreamServiceProvider)
        .updateViewport(
          lat1: bounds.latitudeNorth,
          long1: bounds.longitudeWest,
          lat2: bounds.latitudeSouth,
          long2: bounds.longitudeEast,
        );

    // Purge targets outside current viewport (plus 0.5° margin ~ 55km) to keep DB target count minimal and clean
    const margin = 0.5;
    final purgedIds = _aggregator.purgeTargetsOutside(
      latNorth: bounds.latitudeNorth + margin,
      lonWest: bounds.longitudeWest - margin,
      latSouth: bounds.latitudeSouth - margin,
      lonEast: bounds.longitudeEast + margin,
    );
    for (final id in purgedIds) {
      _trackHistories.remove(id);
    }
    if (purgedIds.isNotEmpty) {
      publishState();
    }
  }

  void _updateOutboundTrackingState() {
    final settings = ref.read(appSettingsProvider).value;
    final aircrafts = ref.read(aircraftStateProvider).value ?? [];

    if (settings == null) {
      _stopOutboundTracking();
      return;
    }

    final activeAircraftId = settings.airplaneId;
    final activeAircraft = aircrafts.cast<Aircraft?>().firstWhere(
      (a) => a?.id == activeAircraftId,
      orElse: () => null,
    );

    if (settings.ognEnabled &&
        activeAircraft != null &&
        activeAircraft.sendLivePosition &&
        RegExp(
          r'^[0-9A-Fa-f]{6}$',
        ).hasMatch(activeAircraft.ognDeviceId.trim())) {
      _startOutboundTracking(activeAircraft);
    } else {
      _stopOutboundTracking();
    }
  }

  void _startOutboundTracking(Aircraft aircraft) {
    final ognId = aircraft.ognDeviceId.trim().toUpperCase();
    if (_outboundManager != null && _activeOutboundId == ognId) {
      return;
    }

    _stopOutboundTracking();
    _activeOutboundId = ognId;
    _outboundManager = OgnOutboundManager();
    final callsign = ognId.startsWith(RegExp(r'^(ICA|FLR|OGN)'))
        ? ognId
        : 'OGN$ognId';
    final type = aircraft.type.ognCode;

    _outboundManager!
        .start(callsign: callsign, ognId: ognId, aircraftType: type)
        .then((_) {
          _outboundTimer?.cancel();
          _outboundTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
            final telemetry = ref.read(telemetryProvider);
            if (telemetry.latitude != null &&
                telemetry.longitude != null &&
                telemetry.latitude != 0.0 &&
                telemetry.longitude != 0.0) {
              if (telemetry.isFlying) {
                final vario = ref.read(varioProvider);
                final vsVal = vario.verticalSpeed ?? 0.0;
                _outboundManager?.sendPosition(
                  lat: telemetry.latitude!,
                  lon: telemetry.longitude!,
                  altitude: telemetry.gpsAltitude ?? 0.0,
                  heading: telemetry.heading ?? 0.0,
                  speed: telemetry.groundSpeed ?? 0.0,
                  vs: vsVal,
                  timestamp: telemetry.gpsTimestamp,
                );
              }
            }
          });
        });
  }

  void _stopOutboundTracking() {
    _activeOutboundId = null;
    _outboundTimer?.cancel();
    _outboundTimer = null;
    _outboundManager?.stop();
    _outboundManager = null;
  }
}

@riverpod
class FilteredTraffic extends _$FilteredTraffic {
  DateTime? _lastCasEvaluationTime;
  Map<String, CasThreatEvaluation> _cachedCasEvaluations = {};

  @override
  List<TrafficAircraft> build() {
    final traffic = ref.watch(trafficProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final telemetry = ref.watch(telemetryProvider);
    final resolvedAlt = ref.watch(resolvedAltitudeProvider).mslValue;
    final vario = ref.watch(varioProvider);

    if (settings == null) return traffic;

    final hiddenIds = settings.hiddenAircraftIds;

    final filtered = traffic.where((ac) {
      if (hiddenIds.isNotEmpty) {
        final acId = ac.id.trim().toLowerCase();
        final acIcao = ac.icaoHex?.trim().toLowerCase();
        if (hiddenIds.contains(acId) ||
            (acIcao != null && hiddenIds.contains(acIcao))) {
          return false;
        }
      }

      if (settings.trafficFilterMaxHorizontalDistanceEnabled) {
        if (telemetry.latitude != null &&
            telemetry.longitude != null &&
            telemetry.latitude != 0.0 &&
            telemetry.longitude != 0.0) {
          final distMeters = GeoUtils.distanceBetween(
            telemetry.latitude!,
            telemetry.longitude!,
            ac.latitude,
            ac.longitude,
          );
          if (distMeters > settings.trafficMaxHorizontalDistance) {
            return false;
          }
        }
      }
      if (settings.trafficFilterMaxVerticalDistanceEnabled) {
        if (telemetry.latitude != null &&
            telemetry.longitude != null &&
            telemetry.latitude != 0.0 &&
            telemetry.longitude != 0.0) {
          final myAlt = resolvedAlt ?? telemetry.gpsAltitude;
          if (myAlt != null) {
            final vertDiffMeters = (myAlt - ac.altitude).abs();
            if (vertDiffMeters > settings.trafficMaxVerticalDistance) {
              return false;
            }
          }
        }
      }
      return true;
    }).toList();

    if (telemetry.latitude == null ||
        telemetry.longitude == null ||
        telemetry.latitude == 0.0 ||
        telemetry.longitude == 0.0) {
      return filtered;
    }

    if (!settings.casEnabled) return filtered;

    final now = DateTime.now();
    final filteredIds = filtered.map((ac) => ac.id).toSet();
    final cachedIds = _cachedCasEvaluations.keys.toSet();
    final membershipChanged =
        filteredIds.length != cachedIds.length ||
        !filteredIds.containsAll(cachedIds);

    final shouldRecalculateCas =
        _lastCasEvaluationTime == null ||
        now.difference(_lastCasEvaluationTime!) >= const Duration(seconds: 1) ||
        membershipChanged;

    if (shouldRecalculateCas) {
      final myHeading = telemetry.heading ?? 0.0;
      final ownshipHistory = ref
          .read(trafficProvider.notifier)
          .ownshipTrackHistory;
      final myOmega = CasEvaluator.calculateTurnRate(ownshipHistory);
      final myIsCircling = CasEvaluator.detectCircling(ownshipHistory);
      final myLat = telemetry.latitude!;
      final myLon = telemetry.longitude!;
      final myAlt = resolvedAlt ?? telemetry.gpsAltitude ?? 0.0;
      final myGs = telemetry.groundSpeed ?? 0.0;
      final myVs = vario.verticalSpeed ?? 0.0;

      final newEvaluations = <String, CasThreatEvaluation>{};

      for (final ac in filtered) {
        final threatEval = CasEvaluator.evaluateThreat(
          latA: myLat,
          lonA: myLon,
          altA: myAlt,
          gsA: myGs,
          trackA: myHeading,
          omegaA: myOmega,
          vsA: myVs,
          isCirclingA: myIsCircling,
          latB: ac.latitude,
          lonB: ac.longitude,
          altB: ac.altitude,
          gsB: ac.groundSpeed,
          trackB: ac.track,
          omegaB: ac.turnRate,
          vsB: ac.verticalSpeed,
          isCirclingB: ac.isCircling,
          maxBroadPhaseHorizDist: settings.trafficMaxHorizontalDistance,
          maxBroadPhaseVertDist: settings.trafficMaxVerticalDistance,
          lookaheadTimeSec: settings.casLookaheadTime,
          horizThresholdMeters: settings.casHorizontalThreshold,
          vertThresholdMeters: settings.casVerticalThreshold,
        );
        newEvaluations[ac.id] = threatEval;
      }

      _cachedCasEvaluations = newEvaluations;
      _lastCasEvaluationTime = now;
    }

    return filtered.map((ac) {
      final threatEval = _cachedCasEvaluations[ac.id];
      if (threatEval == null) return ac;

      return ac.copyWith(
        isCollisionThreat: threatEval.isCollisionThreat,
        tCpa: threatEval.tCpa,
        minDistance: threatEval.minDistance,
      );
    }).toList();
  }
}

@riverpod
TrafficAircraft? activeCollisionAlert(Ref ref) {
  final filtered = ref.watch(filteredTrafficProvider);
  final threats = filtered.where((ac) => ac.isCollisionThreat).toList();
  if (threats.isEmpty) return null;

  threats.sort((a, b) {
    final tA = a.tCpa ?? 999.0;
    final tB = b.tCpa ?? 999.0;
    if (tA != tB) return tA.compareTo(tB);
    final dA = a.minDistance ?? 99999.0;
    final dB = b.minDistance ?? 99999.0;
    return dA.compareTo(dB);
  });

  return threats.first;
}
