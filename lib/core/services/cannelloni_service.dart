import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/native/canard_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

part 'cannelloni_service.g.dart';

@Riverpod(keepAlive: true)
class CannelloniService extends _$CannelloniService {
  RawDatagramSocket? _socket;
  String? _lastIp;
  int? _lastPort;
  Timer? _heartbeatTimer;
  CanardBindings? _canard;
  Pointer<Uint8>? _packetDataBuffer;
  int _txSeqNo = 0;

  @override
  void build() {
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

    debugPrint('CannelloniService: Calling storkCanardInit(64)...');
    _canard?.storkCanardInit(64); // Default node ID, could be from settings
    debugPrint('CannelloniService: storkCanardInit executed successfully.');

    _packetDataBuffer = malloc.allocate<Uint8>(
      4096,
    ); // Preallocated buffer for Cannelloni packets

    final settingsAsync = ref.watch(appSettingsProvider);

    settingsAsync.whenData((settings) {
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

    ref.onDispose(() {
      _disconnect();
      if (_packetDataBuffer != null) {
        malloc.free(_packetDataBuffer!);
      }
    });
  }

  void _disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _txSeqNo = 0;

    if (_socket != null) {
      debugPrint('CannelloniService: Disconnecting from $_lastIp:$_lastPort');
      _socket?.close();
      _socket = null;
    }
    _lastIp = null;
    _lastPort = null;
  }

  Future<void> _connect(String ip, int port) async {
    _disconnect();

    try {
      _lastIp = ip;
      _lastPort = port;

      // Bind to any available local port
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      final remoteAddress = InternetAddress(ip);

      debugPrint(
        'CannelloniService: Connected to $ip:$port (local port: ${_socket?.port})',
      );

      _socket?.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              _processPacket(datagram.data, datagram.address, datagram.port);
            }
          }
        },
        onError: (e) {
          debugPrint('CannelloniService: Socket error: $e');
        },
      );

      // Send an initial empty Cannelloni packet to let the remote server know where to send data.
      _sendEmptyPacket(remoteAddress, port);
      debugPrint(
        'CannelloniService: Initial registration packet sent to $ip:$port (seq: ${_txSeqNo == 0 ? 255 : _txSeqNo - 1})',
      );

      // Start periodic heartbeats to keep the connection alive
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _sendEmptyPacket(remoteAddress, port);
      });
    } catch (e) {
      debugPrint('CannelloniService: Failed to connect: $e');
    }
  }

  void _sendEmptyPacket(InternetAddress remoteAddress, int port) {
    if (_socket == null) return;

    final packet = Uint8List(5);
    packet[0] = 2; // Version
    packet[1] = 0; // OpCode DATA
    packet[2] = _txSeqNo; // SeqNo
    packet[3] = 0; // Count 0
    packet[4] = 0; // Count 0

    try {
      _socket?.send(packet, remoteAddress, port);
      _txSeqNo = (_txSeqNo + 1) & 0xFF;
    } catch (e) {
      debugPrint('CannelloniService: Failed to send empty packet: $e');
    }
  }

  void _processPacket(Uint8List data, InternetAddress address, int port) {
    if (data.isEmpty) return;

    if (_canard != null && _packetDataBuffer != null) {
      final len = data.length;
      final copyLen = len > 4096 ? 4096 : len;

      // Copy data into the native buffer efficiently
      final bufferList = _packetDataBuffer!.asTypedList(4096);
      bufferList.setRange(0, copyLen, data);

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      _canard!.storkCanardProcessPacket(_packetDataBuffer!, copyLen, timestamp);
    }
  }
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
  Pointer<Uint8> payload,
  int payloadLen,
) {
  try {
    // 1. Create a view into the C memory and copy it to Dart memory
    final payloadView = payload.asTypedList(payloadLen);
    final payloadBytes = Uint8List.fromList(payloadView);

    // 2. Extract Static Pressure (Data Type ID 1028)
    if (dataTypeId == 1028 && payloadLen >= 4) {
      // Message uavcan.equipment.air_data.StaticPressure starts with a 32-bit float
      final byteData = ByteData.sublistView(payloadBytes);
      final staticPressure = byteData.getFloat32(0, Endian.little);
      debugPrint(
        '[DroneCAN] StaticPressure (1028) from Node $sourceNodeId: $staticPressure Pa',
      );
    }
  } catch (e) {
    debugPrint('Error in native transfer callback: $e');
  }
}
