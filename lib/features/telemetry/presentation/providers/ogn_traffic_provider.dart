import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:maplibre/maplibre.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/domain/models/aircraft.dart';
import 'telemetry_provider.dart';
import 'vario_provider.dart';
import '../../data/ogn_aprs_service.dart';

part 'ogn_traffic_provider.g.dart';

@Riverpod(keepAlive: true)
class OgnTraffic extends _$OgnTraffic {
  final OgnAprsService _aprsService = OgnAprsService();
  OgnInboundConnection? _inboundConnection;
  OgnOutboundManager? _outboundManager;
  Timer? _decayTimer;
  Timer? _outboundTimer;
  Timer? _reconnectTimer;
  
  bool _isConnecting = false;
  
  @override
  List<OgnTrafficAircraft> build() {
    _decayTimer = Timer.periodic(const Duration(seconds: 5), (_) => _cleanupStaleTraffic());
    
    // Listen to changes in settings & active aircraft OGN config
    ref.listen(appSettingsProvider, (prev, next) {
      _updateOutboundTrackingState();
    });
    
    ref.listen(aircraftStateProvider, (prev, next) {
      _updateOutboundTrackingState();
    });

    ref.onDispose(() {
      _decayTimer?.cancel();
      _outboundTimer?.cancel();
      _reconnectTimer?.cancel();
      _filterDebounceTimer?.cancel();
      _inboundConnection?.disconnect();
      _outboundManager?.stop();
    });

    _connectInbound();

    return const [];
  }

  void _connectInbound() {
    if (_isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();

    int lineCount = 0;
    _inboundConnection = OgnInboundConnection(
      onLineReceived: (line) {
        if (lineCount < 10) {
          debugPrint('OGN Inbound line: $line');
          lineCount++;
        }
        try {
          final aircraft = _aprsService.parseAprsLine(line);
          if (aircraft != null) {
            _updateAircraft(aircraft);
          }
        } catch (e) {
          // Quiet parse error
        }
      },
      onDisconnected: () {
        _isConnecting = false;
        _reconnectTimer = Timer(const Duration(seconds: 5), () => _connectInbound());
      },
    );

    _inboundConnection!.connect().then((_) {
      _isConnecting = false;
    });
  }

  void _updateAircraft(OgnTrafficAircraft aircraft) {
    final list = List<OgnTrafficAircraft>.from(state);
    final idx = list.indexWhere((ac) => ac.id == aircraft.id);
    
    if (idx >= 0) {
      final existing = list[idx];
      list[idx] = aircraft.copyWith(
        registration: existing.registration,
        aircraftModel: existing.aircraftModel,
        cn: existing.cn,
      );
    } else {
      list.add(aircraft);
    }
    state = list;
  }

  Future<void> loadDdbDetails(String id) async {
    await loadDdbDetailsMultiple([id]);
  }

  Future<void> loadDdbDetailsMultiple(List<String> ids) async {
    final List<String> toFetch = [];
    for (final id in ids) {
      final idx = state.indexWhere((ac) => ac.id == id);
      if (idx == -1) continue;
      final aircraft = state[idx];
      if (aircraft.isAnonymous) continue;
      if (aircraft.registration != null && aircraft.registration!.isNotEmpty) continue;
      toFetch.add(id);
    }

    if (toFetch.isEmpty) return;

    final ddbInfos = await _aprsService.lookupDdbMultiple(toFetch);
    if (ddbInfos.isNotEmpty) {
      final currentList = List<OgnTrafficAircraft>.from(state);
      var stateChanged = false;

      for (final entry in ddbInfos.entries) {
        final id = entry.key;
        final info = entry.value;
        final currentIdx = currentList.indexWhere((ac) => ac.id.toUpperCase() == id);
        if (currentIdx >= 0) {
          currentList[currentIdx] = currentList[currentIdx].copyWith(
            registration: info['registration'],
            aircraftModel: info['aircraftModel'],
            cn: info['cn'],
          );
          stateChanged = true;
        }
      }

      if (stateChanged) {
        state = currentList;
      }
    }
  }

  void _cleanupStaleTraffic() {
    if (state.isEmpty) return;
    final now = DateTime.now();
    final updatedList = state.where((ac) {
      return now.difference(ac.lastSeen) < const Duration(seconds: 180);
    }).toList();
    if (updatedList.length != state.length) {
      state = updatedList;
    }
  }

  Timer? _filterDebounceTimer;

  void updateViewport(LngLatBounds bounds) {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_inboundConnection == null) return;
      final filterCommand = 'filter a/${bounds.latitudeNorth.toStringAsFixed(4)}/${bounds.longitudeWest.toStringAsFixed(4)}/${bounds.latitudeSouth.toStringAsFixed(4)}/${bounds.longitudeEast.toStringAsFixed(4)}';
      _inboundConnection!.updateFilter(filterCommand);
    });
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
        activeAircraft.ognDeviceId.length == 6) {
      _startOutboundTracking(activeAircraft);
    } else {
      _stopOutboundTracking();
    }
  }

  void _startOutboundTracking(Aircraft aircraft) {
    if (_outboundManager == null) {
      _outboundManager = OgnOutboundManager();
      final ognId = aircraft.ognDeviceId.toUpperCase();
      final callsign = ognId.startsWith(RegExp(r'^(ICA|FLR|OGN)')) ? ognId : 'OGN$ognId';
      final type = 1; // Default to Glider

      _outboundManager!.start(
        callsign: callsign,
        ognId: ognId,
        aircraftType: type,
      ).then((_) {
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
              _outboundManager!.sendPosition(
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
  }

  void _stopOutboundTracking() {
    _outboundTimer?.cancel();
    _outboundTimer = null;
    _outboundManager?.stop();
    _outboundManager = null;
  }
}
