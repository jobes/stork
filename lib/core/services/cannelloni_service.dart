import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

part 'cannelloni_service.g.dart';

@Riverpod(keepAlive: true)
class CannelloniService extends _$CannelloniService {
  RawDatagramSocket? _socket;
  String? _lastIp;
  int? _lastPort;
  Timer? _heartbeatTimer;

  @override
  void build() {
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
    });
  }

  void _disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

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
      // Header: Version(1), OpCode(0=DATA), SeqNo(0,0), Count(0)
      final initPacket = Uint8List(5);
      initPacket[0] = 1; // Version
      initPacket[1] = 0; // OpCode DATA
      initPacket[2] = 0; // SeqNo high
      initPacket[3] = 0; // SeqNo low
      initPacket[4] = 0; // Count 0

      _socket?.send(initPacket, remoteAddress, port);
      debugPrint(
        'CannelloniService: Initial registration packet sent to $ip:$port',
      );

      // Start periodic heartbeats to keep the connection alive
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _sendHeartbeat(ip, port);
      });
    } catch (e) {
      debugPrint('CannelloniService: Failed to connect: $e');
    }
  }

  void _sendHeartbeat(String ip, int port) {
    if (_socket == null) return;

    final heartbeat = Uint8List(5);
    heartbeat[0] = 2; // Version
    heartbeat[1] = 0; // OpCode DATA
    heartbeat[2] = 0; // SeqNo high
    heartbeat[3] = 0; // SeqNo low
    heartbeat[4] = 0; // Count 0

    try {
      final remoteAddress = InternetAddress(ip);
      _socket?.send(heartbeat, remoteAddress, port);
      // debugPrint('CannelloniService: Heartbeat sent to $ip:$port');
    } catch (e) {
      debugPrint('CannelloniService: Failed to send heartbeat: $e');
    }
  }

  void _processPacket(Uint8List data, InternetAddress address, int port) {
    if (data.length < 5) {
      debugPrint(
        'CannelloniService: Received too short packet (${data.length} bytes) from $address:$port',
      );
      return;
    }

    final version = data[0];
    final opCode = data[1];
    // SeqNo is at index 2, 3 (16-bit)
    final count = data[4];

    debugPrint(
      'Cannelloni Packet: v$version, op:$opCode, frames:$count, total_bytes:${data.length} from $address:$port',
    );

    // Log the first few bytes for debugging
    // debugPrint('Data: ${data.sublist(0, data.length > 16 ? 16 : data.length)}');
  }
}
