import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/native/canard_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/core/native/dronecan_types.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/core/utils/time_utils.dart';
import 'package:stork/core/services/dna_allocation_service.dart';
import 'package:stork/core/services/dronecan_node_transport.dart';
import 'package:stork/core/services/dronecan_transfer_signature.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/core/native/dronecan/dronecan_transfer_ids.dart';
import 'package:stork/core/services/mdns_service.dart';

part 'cannelloni_service_io.g.dart';

class PendingRequest {
  final Completer<Uint8List> completer;
  final int dataTypeId;
  final int transferId;
  final int destinationNodeId;
  final Timer timeoutTimer;

  PendingRequest({
    required this.completer,
    required this.dataTypeId,
    required this.transferId,
    required this.destinationNodeId,
    required this.timeoutTimer,
  });
}

CannelloniService? _activeInstance;

/// Microseconds in one second (1e6), used for leap-second conversion.
const int _microsecondsPerSecond = 1000000;

/// Seconds between TAI and UTC that are independent of leap seconds
/// (UTC = TAI - 10, before the leap-second correction).
const int _taiUtcOffsetSeconds = 10;

/// Seconds between GPS time and UTC that are independent of leap seconds
/// (UTC = GPS + 9, before the leap-second correction).
const int _gpsUtcOffsetSeconds = 9;

/// DroneCAN [Fix2.gnssTimeStandard] values (uavcan.equipment.gnss.Fix2).
const int _gnssTimeStandardTai = 1;
const int _gnssTimeStandardUtc = 2;
const int _gnssTimeStandardGps = 3;

/// Converts a DroneCAN [Fix2] GNSS timestamp to a UTC [DateTime], or `null`
/// when no UTC time can be derived.
///
/// [Fix2.gnssTimestamp] is microseconds since the epoch of
/// [Fix2.gnssTimeStandard]. Per the DroneCAN spec, all three standards are
/// measured from the corresponding time scale at UTC 1970-01-01 (there is no
/// 1980 GPS epoch offset), and convert to UTC as follows:
/// - UTC: already in the UNIX epoch — returned unchanged.
/// - GPS: UTC = GPS - [Fix2.numLeapSeconds] + 9 seconds.
/// - TAI: UTC = TAI - [Fix2.numLeapSeconds] - 10 seconds.
/// - UNKNOWN or any unsupported standard: no UTC time — returns `null`.
@visibleForTesting
DateTime? gnssTimestampToUtc(Fix2 fix2) {
  if (fix2.gnssTimestamp <= 0) return null;
  switch (fix2.gnssTimeStandard) {
    case _gnssTimeStandardUtc:
      return DateTime.fromMicrosecondsSinceEpoch(
        fix2.gnssTimestamp,
        isUtc: true,
      );
    case _gnssTimeStandardGps:
      return DateTime.fromMicrosecondsSinceEpoch(
        fix2.gnssTimestamp -
            fix2.numLeapSeconds * _microsecondsPerSecond +
            _gpsUtcOffsetSeconds * _microsecondsPerSecond,
        isUtc: true,
      );
    case _gnssTimeStandardTai:
      return DateTime.fromMicrosecondsSinceEpoch(
        fix2.gnssTimestamp -
            fix2.numLeapSeconds * _microsecondsPerSecond -
            _taiUtcOffsetSeconds * _microsecondsPerSecond,
        isUtc: true,
      );
    default:
      // UNKNOWN (and any unsupported standard, e.g. GLONASS): no UTC time.
      return null;
  }
}

/// Publishes a DroneCAN [Fix2] into telemetry as the authoritative GPS source.
///
/// Invalid fixes (see [Fix2.hasValidFix]) are ignored: publishing them would
/// mark DroneCAN GPS as active and suppress the phone's own GPS stream,
/// freezing the map on a stale/zero coordinate. The 5 s DroneCAN timeout in
/// [TelemetryNotifier] never fires because every (even invalid) broadcast
/// re-arms it. Returns `true` when the fix was actually published.
@visibleForTesting
bool publishDroneCanFix(Fix2 fix2, TelemetryNotifier telemetry) {
  if (!fix2.hasValidFix) {
    debugPrint(
      '[DroneCAN] Ignoring Fix2 with invalid fix '
      '(status=${fix2.status}, sats=${fix2.satellites}, '
      'lat=${fix2.latitude.toStringAsFixed(6)}, '
      'lon=${fix2.longitude.toStringAsFixed(6)})',
    );
    return false;
  }

  final DateTime? timestamp = gnssTimestampToUtc(fix2);

  telemetry.updateGPS(
    latitude: fix2.latitude,
    longitude: fix2.longitude,
    heading: fix2.heading,
    groundSpeed: fix2.groundSpeed,
    gpsSatelliteCount: fix2.satellites,
    gpsHorizontalAccuracy: fix2.horizontalAccuracy,
    gpsVerticalAccuracy: fix2.verticalAccuracy,
    gpsAltitude: fix2.altitude,
    gpsTimestamp: timestamp,
    isDroneCan: true,
  );
  return true;
}

@Riverpod(keepAlive: true)
class CannelloniService extends _$CannelloniService
    implements DroneCanNodeTransport {
  static const _disconnectGracePeriod = Duration(milliseconds: 3000);
  static const _receiveWatchdogPeriod = Duration(seconds: 5);

  RawDatagramSocket? _socket;
  String? _lastIp;
  int? _lastPort;
  Timer? _heartbeatTimer;
  CanardBindings? _canard;

  /// Buffer for a received Cannelloni packet; the native parser reads from it
  /// while it iterates the frames, so nothing else may write into it.
  Pointer<Uint8>? _packetDataBuffer;

  /// Separate buffer for outgoing Cannelloni packets.
  ///
  /// TX packets can be generated from inside the native transfer callback
  /// (e.g. while answering a `file.Read`), which runs while [_packetDataBuffer]
  /// is still being parsed.
  Pointer<Uint8>? _txDataBuffer;

  static const int _packetBufferSize = 4096;

  int? _nodeId;
  DnaAllocationHandler? _dnaHandler;
  Timer? _nodeStatusTimer;
  Timer? _txTimer;

  DateTime? _lastDataReceivedTime;
  bool _isDiscovered = true;
  Timer? _disconnectTimer;
  Timer? _receiveWatchdogTimer;

  final Map<String, PendingRequest> _pendingRequests = {};
  StreamController<NodeStatusEvent> _nodeStatusController =
      StreamController<NodeStatusEvent>.broadcast();

  /// Stream of DroneCAN node status heartbeats and registry resets.
  @override
  Stream<NodeStatusEvent> get nodeStatusEvents => _nodeStatusController.stream;

  @override
  bool build() {
    // The controller is closed with the previous lifecycle, so a rebuild would
    // silently stop node discovery; existing subscribers keep the same stream.
    if (_nodeStatusController.isClosed) {
      _nodeStatusController = StreamController<NodeStatusEvent>.broadcast();
    }

    _activeInstance = this;

    debugPrint('CannelloniService: Initializing CanardBindings...');
    _canard = CanardBindings();

    // Register the native log callback to route native logs to the Dart Debug Console
    final logCallbackPointer =
        Pointer.fromFunction<StorkCanardLogCallbackNative>(
          _storkCanardLogCallback,
        );
    _canard?.storkCanardRegisterLogCallback(logCallbackPointer);

    // Register transfer callback for incoming DroneCAN messages
    final transferCbPointer =
        Pointer.fromFunction<StorkCanardTransferCallbackNative>(
          _storkCanardTransferCallback,
        );
    _canard?.storkCanardRegisterTransferCallback(transferCbPointer);

    // Register accept callback for validating and assigning signatures
    final acceptCbPointer =
        Pointer.fromFunction<StorkCanardShouldAcceptCallbackNative>(
          _storkCanardShouldAcceptCallback,
          0,
        );
    _canard?.storkCanardRegisterAcceptCallback(acceptCbPointer);

    debugPrint('CannelloniService: Calling storkCanardInit(0)...');
    _canard?.storkCanardInit(0); // Anonymous node ID initially
    debugPrint('CannelloniService: storkCanardInit executed successfully.');

    // Preallocated buffers for Cannelloni packets
    _packetDataBuffer = malloc.allocate<Uint8>(_packetBufferSize);
    _txDataBuffer = malloc.allocate<Uint8>(_packetBufferSize);

    ref.listen(appSettingsProvider, (previous, next) {
      final prevDevice = previous?.asData?.value.selectedDevice;
      final nextDevice = next.asData?.value.selectedDevice;
      if (prevDevice != nextDevice) {
        _updateConnection();
      }
    }, fireImmediately: true);

    ref.listen(discoveredDevicesProvider, (previous, next) {
      final prevList = previous?.asData?.value;
      final nextList = next.asData?.value;
      if (!listEquals(prevList, nextList)) {
        _updateConnection();
      }
    }, fireImmediately: true);

    ref.onDispose(() {
      _activeInstance = null;
      _disconnect();
      if (_packetDataBuffer != null) {
        malloc.free(_packetDataBuffer!);
      }
      if (_txDataBuffer != null) {
        malloc.free(_txDataBuffer!);
      }
      disposeAllTransferIds();
      _nodeStatusController.close();
    });

    return false;
  }

  void _updateConnection() {
    final settingsAsync = ref.read(appSettingsProvider);
    final devicesAsync = ref.read(discoveredDevicesProvider);

    settingsAsync.whenData((settings) {
      final device = settings.selectedDevice;

      if (device == null) {
        _disconnect();
        return;
      }

      // If the discovered devices list hasn't loaded yet, wait until the first scan completes.
      if (!devicesAsync.hasValue) {
        return;
      }

      final discoveredDevices = devicesAsync.value ?? [];
      final isDiscovered = discoveredDevices.any((d) => d == device);
      _isDiscovered = isDiscovered;

      if (!isDiscovered) {
        final now = DateTime.now();
        final lastData = _lastDataReceivedTime;
        if (_socket != null &&
            lastData != null &&
            now.difference(lastData) < _disconnectGracePeriod) {
          final remaining = _disconnectGracePeriod - now.difference(lastData);
          _startDisconnectTimer(remaining, 'after mDNS became unavailable');
        } else {
          _disconnect();
        }
        return;
      } else {
        _disconnectTimer?.cancel();
        _disconnectTimer = null;
      }

      if (_socket != null && device.ip == _lastIp && device.port == _lastPort) {
        return;
      }

      if (device.ip != _lastIp || device.port != _lastPort) {
        debugPrint(
          'CannelloniService: Settings changed, reconnecting to ${device.ip}:${device.port}',
        );
        _connect(device.ip, device.port);
      }
    });
  }

  void _disconnect() {
    if (_socket != null) {
      debugPrint('CannelloniService: Disconnecting from $_lastIp:$_lastPort');
    }
    _resetConnectionState();
    debugPrint('CannelloniService: DroneCAN cleared and Node ID removed.');
  }

  void _resetConnectionState() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _dnaHandler?.stop();
    _dnaHandler = null;
    _nodeStatusTimer?.cancel();
    _nodeStatusTimer = null;
    _txTimer?.cancel();
    _txTimer = null;
    _nodeId = null;

    _socket?.close();
    _socket = null;
    _lastIp = null;
    _lastPort = null;

    _disconnectTimer?.cancel();
    _disconnectTimer = null;
    _receiveWatchdogTimer?.cancel();
    _receiveWatchdogTimer = null;
    _lastDataReceivedTime = null;
    _isDiscovered = true;

    // Clear DroneCAN and remove Node ID (0 is anonymous)
    _canard?.storkCanardInit(0);
    state = false;

    if (!_nodeStatusController.isClosed) {
      _nodeStatusController.add(const NodeStatusRegistryClearedEvent());
    }
  }

  void _startDisconnectTimer(Duration duration, String contextMessage) {
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(duration, () {
      debugPrint(
        'CannelloniService: No data received for ${_disconnectGracePeriod.inMilliseconds}ms $contextMessage. Disconnecting...',
      );
      _disconnect();
    });
  }

  void _resetDisconnectTimerIfNeeded() {
    if (!_isDiscovered && _socket != null) {
      _startDisconnectTimer(
        _disconnectGracePeriod,
        'while mDNS is unavailable',
      );
    }
  }

  void _startReceiveWatchdog() {
    _receiveWatchdogTimer?.cancel();
    _receiveWatchdogTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkReceiveWatchdog(),
    );
  }

  void _checkReceiveWatchdog() {
    if (_socket == null || _lastIp == null || _lastPort == null) return;

    final lastData = _lastDataReceivedTime;
    if (lastData == null) return;

    final elapsed = DateTime.now().difference(lastData);
    if (elapsed >= _receiveWatchdogPeriod) {
      debugPrint(
        'CannelloniService: No data received for ${elapsed.inSeconds}s. '
        'Watchdog triggered — reconnecting to $_lastIp:$_lastPort',
      );
      final ip = _lastIp!;
      final port = _lastPort!;
      _connect(ip, port).catchError((e) {
        debugPrint(
          'CannelloniService: Watchdog reconnect failed: $e. '
          'Restarting watchdog for next attempt.',
        );
        _startReceiveWatchdog();
      });
    }
  }

  void _listenToSocket() {
    _socket?.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null &&
              datagram.data.isNotEmpty &&
              _canard != null &&
              _packetDataBuffer != null) {
            _lastDataReceivedTime = DateTime.now();
            _resetDisconnectTimerIfNeeded();

            final data = datagram.data;
            final len = data.length;
            final copyLen = len > _packetBufferSize ? _packetBufferSize : len;

            // Copy data into the native buffer efficiently
            final bufferList = _packetDataBuffer!.asTypedList(
              _packetBufferSize,
            );
            bufferList.setRange(0, copyLen, data);

            final timestamp = DateTime.now().microsecondsSinceEpoch;
            _canard!.storkCanardProcessPacket(
              _packetDataBuffer!,
              copyLen,
              timestamp,
            );
          }
        }
      },
      onError: (e) {
        debugPrint('CannelloniService: Socket error: $e');
      },
      onDone: () {
        debugPrint(
          'CannelloniService: Socket stream ended unexpectedly. '
          'Last IP: $_lastIp, Last data: $_lastDataReceivedTime',
        );
        _resetConnectionState();
      },
    );
    _startReceiveWatchdog();
  }

  Future<Uint8List> _loadOrGenerateUniqueId() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final savedUidHex = prefs.getString('dronecan_unique_id');
    final uniqueId = Uint8List(16);
    if (savedUidHex != null && savedUidHex.length == 32) {
      try {
        for (int i = 0; i < 16; i++) {
          uniqueId[i] = int.parse(
            savedUidHex.substring(i * 2, i * 2 + 2),
            radix: 16,
          );
        }
        return uniqueId;
      } catch (e) {
        debugPrint(
          'CannelloniService: Failed to parse unique ID hex "$savedUidHex", regenerating: $e',
        );
      }
    }

    final rand = math.Random();
    for (int i = 0; i < 16; i++) {
      uniqueId[i] = rand.nextInt(256);
    }
    final hex = uniqueId.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString('dronecan_unique_id', hex);
    return uniqueId;
  }

  Future<void> _connect(String ip, int port) async {
    _disconnect();

    try {
      _lastIp = ip;
      _lastPort = port;

      // Load or generate a persistent Unique ID for DroneCAN using SharedPreferences
      final uniqueId = await _loadOrGenerateUniqueId();

      _nodeId = 0;
      _canard?.storkCanardInit(0);

      // Bind to any available local port
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      debugPrint(
        'CannelloniService: Connected to $ip:$port (local port: ${_socket?.port})',
      );

      _listenToSocket();

      state = true;

      // Start the DNA allocation process
      _startDnaAllocation(uniqueId);

      // Start processing the TX queue at 10Hz
      _startTxProcessing();
    } catch (e) {
      debugPrint('CannelloniService: Failed to connect: $e');
      _resetConnectionState();
    }
  }

  void _startTxProcessing() {
    _txTimer?.cancel();
    _txTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _pumpTxQueue(),
    );
  }

  /// Sends everything libcanard has queued as one Cannelloni packet.
  void _pumpTxQueue() {
    if (_socket == null ||
        _canard == null ||
        _lastIp == null ||
        _lastPort == null ||
        _txDataBuffer == null) {
      return;
    }

    final pointer = _txDataBuffer!;
    final len = _canard!.storkCanardGenerateTxPacket(
      pointer,
      _packetBufferSize,
    );
    if (len <= 0) return;

    final packet = Uint8List.fromList(pointer.asTypedList(len));
    try {
      _socket!.send(packet, InternetAddress(_lastIp!), _lastPort!);
    } catch (e) {
      debugPrint('CannelloniService: Failed to send TX packet: $e');
    }
  }

  void _startDnaAllocation(Uint8List uniqueId) {
    _dnaHandler = DnaAllocationHandler(
      uniqueId: uniqueId,
      onBroadcast: (msg) => broadcast(msg, priority: DroneCanPriority.highest),
      onAllocated: (allocatedNodeId) {
        _nodeId = allocatedNodeId;
        _canard?.storkCanardInit(_nodeId!);
        _startNodeStatusBroadcasting();
      },
    );
    _dnaHandler?.start();
  }

  void _startNodeStatusBroadcasting() {
    _nodeStatusTimer?.cancel();
    _nodeStatusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_canard == null || _nodeId == null || _nodeId == 0) return;
      broadcast(
        NodeStatus(
          uptimeSec: appStopwatch.elapsed.inSeconds,
          health: NodeHealth.ok,
          mode: NodeMode.operational,
        ),
        priority: DroneCanPriority.low,
      );
    });
  }

  void _withNativePayload(
    Uint8List payload,
    void Function(Pointer<Uint8> pointer, int length) action,
  ) {
    final pointer = malloc.allocate<Uint8>(payload.length);
    try {
      pointer.asTypedList(payload.length).setAll(0, payload);
      action(pointer, payload.length);
    } finally {
      malloc.free(pointer);
    }
  }

  /// Sends a DroneCAN service response generically, handling native pointer allocation and cleanup.
  void respond({
    required int transferId,
    required int sourceNodeId,
    required int priority,
    required DroneCanRequestResponseMessage response,
  }) {
    if (_canard == null) return;

    _withNativePayload(response.toPayload(), (pointer, len) {
      try {
        final res = _canard!.storkCanardRespond(
          response.signature,
          response.id,
          transferId,
          sourceNodeId,
          priority,
          pointer,
          len,
        );
        if (res < 0) {
          debugPrint(
            'CannelloniService: Failed to send response (ID: ${response.id}, result: $res)',
          );
        }
      } catch (e) {
        debugPrint(
          'CannelloniService: Failed to send response (ID: ${response.id}): $e',
        );
      }
    });
  }

  /// Sends a DroneCAN service request, tracking its completion and timeout.
  ///
  /// [transferIdKey] identifies the transfer-ID counter used for the request;
  /// each request data type must use its own counter.
  Future<Uint8List> sendRequest({
    required int destinationNodeId,
    required int dataTypeId,
    required int dataTypeSignature,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 1),
    required Type transferIdKey,
  }) async {
    if (_canard == null || _socket == null || !state) {
      throw StateError('DroneCAN service is not connected.');
    }

    final completer = Completer<Uint8List>();
    final tidPtr = getTransferIdFor(transferIdKey);
    final tid = tidPtr.value;

    final key = "$destinationNodeId-$dataTypeId-$tid";

    final timeoutTimer = Timer(timeout, () {
      _pendingRequests.remove(key);
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'DroneCAN request timed out after ${timeout.inMilliseconds}ms',
          ),
        );
      }
    });

    _pendingRequests[key] = PendingRequest(
      completer: completer,
      dataTypeId: dataTypeId,
      transferId: tid,
      destinationNodeId: destinationNodeId,
      timeoutTimer: timeoutTimer,
    );

    _withNativePayload(payload, (pointer, len) {
      try {
        final res = _canard!.storkCanardRequest(
          dataTypeSignature,
          dataTypeId,
          tidPtr,
          destinationNodeId,
          DroneCanPriority.highest.value,
          pointer,
          len,
        );
        if (res < 0) {
          _pendingRequests.remove(key);
          timeoutTimer.cancel();
          completer.completeError(
            Exception('Failed to send DroneCAN request (native result: $res)'),
          );
        }
      } catch (e) {
        _pendingRequests.remove(key);
        timeoutTimer.cancel();
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Broadcasts a DroneCAN message generically, handling native pointer allocation and cleanup.
  void broadcast(
    DroneCanRequestResponseMessage message, {
    DroneCanPriority priority = DroneCanPriority.medium,
  }) {
    if (_canard == null) return;

    _withNativePayload(message.toPayload(), (pointer, len) {
      try {
        final res = _canard!.storkCanardBroadcast(
          message.signature,
          message.id,
          getTransferIdFor(message.runtimeType),
          priority.value,
          pointer,
          len,
        );
        if (res < 0) {
          debugPrint(
            'CannelloniService: Failed to enqueue broadcast (ID: ${message.id}, result: $res)',
          );
        }
      } catch (e) {
        debugPrint(
          'CannelloniService: Failed to enqueue broadcast (ID: ${message.id}): $e',
        );
      }
    });
  }

  void _updateTelemetryPressure(double pressure) {
    ref.read(telemetryProvider.notifier).updatePressure(pressure);
  }

  void _updateTelemetryGPS(Fix2 fix2) {
    // Only a real 2D/3D fix is usable as the own position. Invalid fixes are
    // dropped in [publishDroneCanFix] so they can never mark DroneCAN GPS as
    // active and suppress the phone GPS stream.
    publishDroneCanFix(fix2, ref.read(telemetryProvider.notifier));
  }

  void _updateTelemetryIceStatus(IceStatus msg) {
    if (msg.hasError) {
      debugPrint(
        '[DroneCAN] ICE Status ERROR from engine: ${msg.errorDescription} '
        '(state=${msg.state}, flags=0x${msg.flags.toRadixString(16)})',
      );
    }
    ref
        .read(telemetryProvider.notifier)
        .updateIceStatus(
          engineSpeedRpm: msg.engineSpeedRpm,
          coolantTemperature: msg.coolantTemperature,
          oilPressure: msg.oilPressure,
          oilTemperature: msg.oilTemperature,
          cylinderHeadTemperatures: msg.cylinderHeadTemperatures,
          exhaustGasTemperatures: msg.exhaustGasTemperatures,
        );
  }

  void _updateTelemetryFuelTankStatus(FuelTankStatus msg) {
    final double? volumeLiters = msg.availableFuelVolumeCm3 != null
        ? msg.availableFuelVolumeCm3! / 1000.0
        : null;
    ref
        .read(telemetryProvider.notifier)
        .updateFuelStatus(
          percent: msg.availableFuelVolumePercent.toDouble(),
          volumeLiters: volumeLiters,
        );
  }

  void _updateTelemetryStorkEngineRpm(StorkEngineRpm msg) {
    ref.read(telemetryProvider.notifier).updateEngineRPM(msg.engineSpeedRpm);
  }

  void _updateTelemetryIndicatedAirspeed(IndicatedAirspeed msg) {
    ref.read(telemetryProvider.notifier).updateAirSpeed(msg.indicatedAirspeed);
  }

  void _updateTelemetryVhfRadioFullStatus(
    VhfRadioFullStatus msg,
    int sourceNodeId,
  ) {
    ref
        .read(telemetryProvider.notifier)
        .updateVhfRadioFull(
          radioInstance: msg.radioInstance,
          activeFrequencyKhz: msg.activeFrequencyKhz,
          standbyFrequencyKhz: msg.standbyFrequencyKhz,
          flags: msg.flags,
          activeStationName: msg.activeStationName,
          standbyStationName: msg.standbyStationName,
          nodeId: sourceNodeId,
          volume: msg.volume,
          squelch: msg.squelch,
          vox: msg.vox,
          intercom: msg.intercom,
          micGain: msg.micGain,
        );
  }

  void _updateTelemetryVhfRadioFastStatus(
    VhfRadioFastStatus msg,
    int sourceNodeId,
  ) {
    ref
        .read(telemetryProvider.notifier)
        .updateVhfRadioFast(
          radioInstance: msg.radioInstance,
          flags: msg.flags,
          nodeId: sourceNodeId,
        );
  }

  void _handleNodeStatus(int sourceNodeId, Uint8List payload) {
    // Do not list this app's own DroneCAN node as a flight instrument.
    if (_nodeId != null && sourceNodeId == _nodeId) return;
    try {
      final status = NodeStatus.fromPayload(payload);
      if (!_nodeStatusController.isClosed) {
        _nodeStatusController.add(
          NodeStatusReceivedEvent(
            nodeId: sourceNodeId,
            status: status,
            receivedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'CannelloniService: Failed to parse NodeStatus from node '
        '$sourceNodeId: $e',
      );
    }
  }

  /// Requests `uavcan.protocol.GetNodeInfo` from [nodeId].
  ///
  /// Throws [StateError] when not connected and [TimeoutException] when the
  /// node does not respond within [timeout].
  @override
  Future<GetNodeInfoResponse> getNodeInfo(
    int nodeId, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final payload = await sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: GetNodeInfoResponse.messageId,
      dataTypeSignature: GetNodeInfoResponse.messageSignature,
      payload: Uint8List(0),
      timeout: timeout,
      transferIdKey: GetNodeInfoResponse,
    );
    return GetNodeInfoResponse.fromPayload(payload);
  }

  /// Requests `uavcan.protocol.RestartNode` from [nodeId].
  ///
  /// Returns `true` when the node accepted the restart. Throws [StateError]
  /// when not connected and [TimeoutException] when the node does not respond.
  @override
  Future<bool> restartNode(
    int nodeId, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final payload = await sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: RestartNode.messageId,
      dataTypeSignature: RestartNode.messageSignature,
      payload: RestartNode().toPayload(),
      timeout: timeout,
      transferIdKey: RestartNode,
    );
    return RestartNodeResponse.fromPayload(payload).ok;
  }

  /// Requests `uavcan.protocol.GetTransportStats` from [nodeId].
  @override
  Future<GetTransportStatsResponse> getTransportStats(
    int nodeId, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final payload = await sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: GetTransportStats.messageId,
      dataTypeSignature: GetTransportStats.messageSignature,
      payload: GetTransportStats().toPayload(),
      timeout: timeout,
      transferIdKey: GetTransportStats,
    );
    return GetTransportStatsResponse.fromPayload(payload);
  }

  /// Requests `uavcan.protocol.param.GetSet` from [nodeId].
  @override
  Future<GetSetResponse> getSetParameter(
    int nodeId,
    GetSetRequest request, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final payload = await sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: GetSetRequest.messageId,
      dataTypeSignature: GetSetRequest.messageSignature,
      payload: request.toPayload(),
      timeout: timeout,
      transferIdKey: GetSetRequest,
    );
    return GetSetResponse.fromPayload(payload);
  }

  /// Requests `uavcan.protocol.param.ExecuteOpcode` from [nodeId].
  @override
  Future<bool> executeParameterOpcode(
    int nodeId,
    int opcode, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final payload = await sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: ExecuteOpcodeRequest.messageId,
      dataTypeSignature: ExecuteOpcodeRequest.messageSignature,
      payload: ExecuteOpcodeRequest(opcode).toPayload(),
      timeout: timeout,
      transferIdKey: ExecuteOpcodeRequest,
    );
    return ExecuteOpcodeResponse.fromPayload(payload).ok;
  }

  /// Requests `uavcan.protocol.file.BeginFirmwareUpdate` from [nodeId].
  ///
  /// The node then pulls the image through `file.Read` requests; answers come
  /// from [fileReadHandler].
  @override
  Future<BeginFirmwareUpdateResponse> beginFirmwareUpdate(
    int nodeId,
    String path, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final payload = await sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: BeginFirmwareUpdateRequest.messageId,
      dataTypeSignature: BeginFirmwareUpdateRequest.messageSignature,
      payload: BeginFirmwareUpdateRequest(
        imageFileRemotePath: path,
      ).toPayload(),
      timeout: timeout,
      transferIdKey: BeginFirmwareUpdateRequest,
    );
    return BeginFirmwareUpdateResponse.fromPayload(payload);
  }

  DroneCanFileReadHandler? _fileReadHandler;

  @override
  set fileReadHandler(DroneCanFileReadHandler? handler) {
    _fileReadHandler = handler;
  }

  /// Answers a `file.Read` request of a node that is being updated.
  void _handleFileReadRequest({
    required int transferId,
    required int sourceNodeId,
    required int priority,
    required Uint8List payload,
  }) {
    final FileReadRequest request;
    try {
      request = FileReadRequest.fromPayload(payload);
    } catch (e) {
      debugPrint('CannelloniService: Invalid file.Read request: $e');
      return;
    }

    List<int>? data;
    try {
      data = _fileReadHandler?.call(
        sourceNodeId,
        request.path,
        request.offset,
        fileReadChunkSize,
      );
    } catch (e) {
      debugPrint(
        'CannelloniService: Failed to read file "${request.path}" at '
        '${request.offset}: $e',
      );
    }

    respond(
      transferId: transferId,
      sourceNodeId: sourceNodeId,
      priority: priority,
      response: data == null
          ? const FileReadResponse(error: FileReadResponse.errorNotFound)
          : FileReadResponse(data: data),
    );

    // A node that reads the image chunk by chunk waits for this response before
    // it asks for the next one, so the queued frames must not wait up to 100 ms
    // for the periodic pump — that would cap the upload at a few kB/s.
    // The pump writes into its own buffer, because the receive buffer is still
    // being parsed by the native transfer loop that invoked this callback.
    _pumpTxQueue();
  }

  void _handleGetNodeInfoRequest({
    required int transferId,
    required int sourceNodeId,
    required int priority,
  }) {
    _loadOrGenerateUniqueId()
        .then((uniqueId) => GetNodeInfoResponse.create(uniqueId))
        .then((response) {
          respond(
            transferId: transferId,
            sourceNodeId: sourceNodeId,
            priority: priority,
            response: response,
          );
        })
        .catchError((e) {
          debugPrint(
            'CannelloniService: Failed to generate GET_NODE_INFO response: $e',
          );
        });
  }

  @visibleForTesting
  Future<Uint8List> loadOrGenerateUniqueIdForTesting() =>
      _loadOrGenerateUniqueId();

  @visibleForTesting
  RawDatagramSocket? get socketForTesting => _socket;
  @visibleForTesting
  set socketForTesting(RawDatagramSocket? val) => _socket = val;

  @visibleForTesting
  DateTime? get lastDataReceivedTimeForTesting => _lastDataReceivedTime;
  @visibleForTesting
  set lastDataReceivedTimeForTesting(DateTime? val) =>
      _lastDataReceivedTime = val;

  @visibleForTesting
  Timer? get disconnectTimerForTesting => _disconnectTimer;

  @visibleForTesting
  void updateConnectionForTesting() => _updateConnection();
}

@pragma('vm:entry-point')
void _storkCanardLogCallback(Pointer<Char> messagePtr) {
  try {
    final message = messagePtr.cast<Utf8>().toDartString().trim();
    debugPrint('[stork_canard] $message');
  } catch (e) {
    debugPrint('Error in native log callback: $e');
  }
}

@pragma('vm:entry-point')
void _storkCanardTransferCallback(
  int timestampUsec,
  int dataTypeId,
  int transferType,
  int sourceNodeId,
  int transferId,
  int priority,
  Pointer<Uint8> payload,
  int payloadLen,
) {
  try {
    if (_activeInstance == null) return;

    // Create a view into the C memory and copy it to Dart memory
    final payloadView = payload.asTypedList(payloadLen);
    final payloadBytes = Uint8List.fromList(payloadView);

    final type = CanardTransferType.fromInt(transferType);

    if (type == CanardTransferType.response) {
      final key = "$sourceNodeId-$dataTypeId-$transferId";
      final pending = _activeInstance!._pendingRequests.remove(key);
      if (pending != null) {
        pending.timeoutTimer.cancel();
        pending.completer.complete(payloadBytes);
      }
      return;
    }

    if (dataTypeId == DynamicNodeIdAllocation.messageId &&
        type == CanardTransferType.broadcast) {
      final allocation = DynamicNodeIdAllocation.fromPayload(payloadBytes);
      _activeInstance!._dnaHandler?.handleAllocationMessage(allocation);
    } else if (dataTypeId == NodeStatus.messageId &&
        type == CanardTransferType.broadcast) {
      _activeInstance!._handleNodeStatus(sourceNodeId, payloadBytes);
    } else if (dataTypeId == StaticPressure.messageId) {
      final staticPressureMsg = StaticPressure.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryPressure(
        staticPressureMsg.staticPressure,
      );
    } else if (dataTypeId == GetNodeInfoResponse.messageId &&
        type == CanardTransferType.request) {
      _activeInstance!._handleGetNodeInfoRequest(
        transferId: transferId,
        sourceNodeId: sourceNodeId,
        priority: priority,
      );
    } else if (dataTypeId == FileReadRequest.messageId &&
        type == CanardTransferType.request) {
      _activeInstance!._handleFileReadRequest(
        transferId: transferId,
        sourceNodeId: sourceNodeId,
        priority: priority,
        payload: payloadBytes,
      );
    } else if (dataTypeId == Fix2.messageId) {
      final fix2Msg = Fix2.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryGPS(fix2Msg);
    } else if (dataTypeId == IceStatus.messageId) {
      final iceMsg = IceStatus.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryIceStatus(iceMsg);
    } else if (dataTypeId == FuelTankStatus.messageId) {
      final fuelMsg = FuelTankStatus.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryFuelTankStatus(fuelMsg);
    } else if (dataTypeId == StorkEngineRpm.messageId) {
      final rpmMsg = StorkEngineRpm.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryStorkEngineRpm(rpmMsg);
    } else if (dataTypeId == IndicatedAirspeed.messageId) {
      final iasMsg = IndicatedAirspeed.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryIndicatedAirspeed(iasMsg);
    } else if (dataTypeId == VhfRadioFullStatus.messageId) {
      final radioFullMsg = VhfRadioFullStatus.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryVhfRadioFullStatus(
        radioFullMsg,
        sourceNodeId,
      );
    } else if (dataTypeId == VhfRadioFastStatus.messageId) {
      final radioFastMsg = VhfRadioFastStatus.fromPayload(payloadBytes);
      _activeInstance!._updateTelemetryVhfRadioFastStatus(
        radioFastMsg,
        sourceNodeId,
      );
    }
  } catch (e) {
    debugPrint('Error in native transfer callback: $e');
  }
}

@pragma('vm:entry-point')
int _storkCanardShouldAcceptCallback(
  int dataTypeId,
  int transferType,
  int sourceNodeId,
  Pointer<Uint64> outDataTypeSignature,
) {
  try {
    final signature = droneCanSignatureForTransfer(
      dataTypeId,
      CanardTransferType.fromInt(transferType),
    );
    if (signature == null) return 0; // Reject transfers not relevant to us

    outDataTypeSignature.value = signature;
    return 1;
  } catch (e) {
    debugPrint('Error in native should accept callback: $e');
    return 0; // Reject on error
  }
}
