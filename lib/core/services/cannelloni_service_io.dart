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
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/core/native/dronecan/dronecan_transfer_ids.dart';

part 'cannelloni_service_io.g.dart';

CannelloniService? _activeInstance;

@Riverpod(keepAlive: true)
class CannelloniService extends _$CannelloniService {
  RawDatagramSocket? _socket;
  String? _lastIp;
  int? _lastPort;
  Timer? _heartbeatTimer;
  CanardBindings? _canard;
  Pointer<Uint8>? _packetDataBuffer;

  int? _nodeId;
  DnaAllocationHandler? _dnaHandler;
  Timer? _nodeStatusTimer;
  Timer? _txTimer;

  @override
  void build() {
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

    _packetDataBuffer = malloc.allocate<Uint8>(
      4096,
    ); // Preallocated buffer for Cannelloni packets

    ref.listen(
      appSettingsProvider,
      (previous, next) {
        next.whenData((settings) {
          final device = settings.selectedDevice;

          if (device == null) {
            _disconnect();
            return;
          }

          if (device.ip != _lastIp || device.port != _lastPort) {
            debugPrint(
              'CannelloniService: Settings changed, reconnecting to ${device.ip}:${device.port}',
            );
            _connect(device.ip, device.port);
          }
        });
      },
      fireImmediately: true,
    );

    ref.onDispose(() {
      _activeInstance = null;
      _disconnect();
      if (_packetDataBuffer != null) {
        malloc.free(_packetDataBuffer!);
      }
      disposeAllTransferIds();
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

    // Clear DroneCAN and remove Node ID (0 is anonymous)
    _canard?.storkCanardInit(0);
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
            final data = datagram.data;
            final len = data.length;
            final copyLen = len > 4096 ? 4096 : len;

            // Copy data into the native buffer efficiently
            final bufferList = _packetDataBuffer!.asTypedList(4096);
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
    );
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

      // Start the DNA allocation process
      _startDnaAllocation(uniqueId);

      // Start processing the TX queue at 50Hz
      _startTxProcessing();
    } catch (e) {
      debugPrint('CannelloniService: Failed to connect: $e');
      _resetConnectionState();
    }
  }

  void _startTxProcessing() {
    _txTimer?.cancel();
    _txTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_socket == null ||
          _canard == null ||
          _lastIp == null ||
          _lastPort == null) {
        return;
      }

      final pointer = _packetDataBuffer!;
      final len = _canard!.storkCanardGenerateTxPacket(pointer, 4096);
      if (len > 0) {
        final data = pointer.asTypedList(len);
        final packet = Uint8List.fromList(data);
        try {
          _socket!.send(packet, InternetAddress(_lastIp!), _lastPort!);
        } catch (e) {
          debugPrint('CannelloniService: Failed to send TX packet: $e');
        }
      }
    });
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

    if (dataTypeId == DynamicNodeIdAllocation.messageId &&
        type == CanardTransferType.broadcast) {
      final allocation = DynamicNodeIdAllocation.fromPayload(payloadBytes);
      _activeInstance!._dnaHandler?.handleAllocationMessage(allocation);
    } else if (dataTypeId == NodeStatus.messageId) {
      // final nodeStatus = NodeStatus.fromPayload(payloadBytes);
      // debugPrint('[DroneCAN] NodeStatus from Node $sourceNodeId: $nodeStatus');
    } else if (dataTypeId == StaticPressure.messageId) {
      final staticPressureMsg = StaticPressure.fromPayload(payloadBytes);
      _activeInstance!.ref
          .read(telemetryProvider.notifier)
          .updatePressure(staticPressureMsg.staticPressure);
    } else if (dataTypeId == GetNodeInfoResponse.messageId &&
        type == CanardTransferType.request) {
      _activeInstance!._handleGetNodeInfoRequest(
        transferId: transferId,
        sourceNodeId: sourceNodeId,
        priority: priority,
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
    final type = CanardTransferType.fromInt(transferType);
    final bool isSvc = type != CanardTransferType.broadcast;

    if (!isSvc) {
      // Broadcast messages
      if (dataTypeId == DynamicNodeIdAllocation.messageId) {
        outDataTypeSignature.value = DynamicNodeIdAllocation.messageSignature;
        return 1;
      }
      if (dataTypeId == StaticPressure.messageId) {
        outDataTypeSignature.value = StaticPressure.messageSignature;
        return 1;
      }
    } else {
      // Service messages
      if (dataTypeId == GetNodeInfoResponse.messageId) {
        // We only accept request transfers for GET_NODE_INFO
        if (type == CanardTransferType.request) {
          outDataTypeSignature.value = GetNodeInfoResponse.messageSignature;
          return 1;
        }
      }
    }
    return 0; // Reject all other transfers
  } catch (e) {
    debugPrint('Error in native should accept callback: $e');
    return 0; // Reject on error
  }
}
