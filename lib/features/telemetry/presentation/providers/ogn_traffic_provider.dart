import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:maplibre/maplibre.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/domain/models/aircraft.dart';
import '../../domain/utils/cas_evaluator.dart';
import 'telemetry_provider.dart';
import 'vario_provider.dart';
import '../../data/ogn_aprs_service.dart';

import '../../domain/repositories/traffic_aggregator.dart';
import '../../domain/utils/canonical_id.dart';
import '../../data/puretrack_stream_service.dart';
import 'puretrack_auth_provider.dart';
import 'agl_provider.dart';

part 'ogn_traffic_provider.g.dart';

const double kOgnFilterSignificantShiftMeters = 1500.0;
const Duration kOgnFilterMaxUnsentDuration = Duration(seconds: 15);
const Duration kOgnFilterDebounceDuration = Duration(seconds: 1);

@riverpod
OgnAprsService ognAprsService(Ref ref) {
  return OgnAprsService();
}

@Riverpod(keepAlive: true)
class OgnTraffic extends _$OgnTraffic {
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

  @override
  List<OgnTrafficAircraft> build() {
    _aprsService = ref.read(ognAprsServiceProvider);

    // Eagerly read pureTrackProvider so connection state is managed on app start
    ref.read(pureTrackProvider);

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
      _decayTimer?.cancel();
      _publishTimer?.cancel();
      _outboundTimer?.cancel();
      _reconnectTimer?.cancel();
      _filterDebounceTimer?.cancel();
      _inboundConnection?.disconnect();
      _outboundManager?.stop();
    });

    _connectInbound();

    return const [];
  }

  void publishState() {
    state = _aggregator.targets;
    debugPrint(
      '[OgnTraffic] [PUBLISH STATE] Published ${state.length} targets to Riverpod UI listeners',
    );
  }

  void _connectInbound() {
    if (_isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();
    debugPrint('[OgnTraffic] Connecting to OGN APRS server...');

    int lineCount = 0;
    _inboundConnection = OgnInboundConnection(
      onLineReceived: (line) {
        if (lineCount < 5) {
          debugPrint('[OGN APRS Raw Line sample] $line');
          lineCount++;
        }
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

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 30);
    _reconnectTimer = Timer(
      Duration(seconds: delaySeconds),
      () => _connectInbound(),
    );
  }

  final Map<String, List<TrackHistoryPoint>> _trackHistories = {};

  void _updateAircraft(OgnTrafficAircraft aircraft) {
    _aggregator.processOgnUpdate(aircraft);

    final canonicalId = CanonicalId.normalize(aircraft.id);
    final history = _trackHistories.putIfAbsent(canonicalId, () => []);
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
      canonicalId,
      turnRate: turnRate,
      isCircling: isCircling,
    );
  }

  void processPureTrackPacket(PureTrackPacket packet) {
    _aggregator.processPureTrackPacket(packet);

    final canonicalId = packet.canonicalId;
    final history = _trackHistories.putIfAbsent(canonicalId, () => []);
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
      canonicalId,
      turnRate: turnRate,
      isCircling: isCircling,
    );
  }

  void _cleanupStaleTraffic() {
    final purged = _aggregator.purgeStaleTargets(
      maxAge: const Duration(minutes: 3),
    );
    if (purged > 0) {
      publishState();
    }
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
      if (aircraft.registration != null && aircraft.registration!.isNotEmpty)
        continue;
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
      if (dist > kOgnFilterSignificantShiftMeters) {
        significantShift = true;
      }
    }

    // Force immediate filter update if time elapsed >= 15s OR if camera turned/shifted significantly
    if (timeSinceLastSent >= kOgnFilterMaxUnsentDuration || significantShift) {
      _filterDebounceTimer?.cancel();
      _sendFilter(bounds);
      return;
    }

    // Trailing debounce for minor manual panning/zooming
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(kOgnFilterDebounceDuration, () {
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
    final purgedCount = _aggregator.purgeTargetsOutside(
      latNorth: bounds.latitudeNorth + margin,
      lonWest: bounds.longitudeWest - margin,
      latSouth: bounds.latitudeSouth - margin,
      lonEast: bounds.longitudeEast + margin,
    );
    if (purgedCount > 0) {
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

    if (activeAircraft != null &&
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
class FilteredOgnTraffic extends _$FilteredOgnTraffic {
  DateTime? _lastCasEvaluationTime;
  Map<String, CasThreatEvaluation> _cachedCasEvaluations = {};

  @override
  List<OgnTrafficAircraft> build() {
    final traffic = ref.watch(ognTrafficProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final telemetry = ref.watch(telemetryProvider);
    final resolvedAlt = ref.watch(resolvedAltitudeProvider).mslValue;
    final vario = ref.watch(varioProvider);

    if (settings == null) return traffic;

    final filtered = traffic.where((ac) {
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
          .read(ognTrafficProvider.notifier)
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
OgnTrafficAircraft? activeCollisionAlert(Ref ref) {
  final filtered = ref.watch(filteredOgnTrafficProvider);
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
