import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../domain/models/gdl90_target.dart';
import 'gdl90_decoder.dart';

/// UDP Network Listener & Service for GDL90 Traffic Broadcasts
class Gdl90Service {
  final Gdl90Decoder _decoder = Gdl90Decoder();
  final Map<String, Gdl90Target> _targets = {};
  final StreamController<List<Gdl90Target>> _targetStreamController =
      StreamController<List<Gdl90Target>>.broadcast();
  final StreamController<DateTime> _heartbeatStreamController =
      StreamController<DateTime>.broadcast();

  DateTime? _lastHeartbeatTime;

  RawDatagramSocket? _socket;
  Timer? _expiryTimer;

  bool _enabled = true;
  String _bindHost = '0.0.0.0';
  int _bindPort = 4000;
  int _expirySeconds = 60;
  bool _isBinding = false;

  /// Stream of active GDL90 targets
  Stream<List<Gdl90Target>> get targetStream => _targetStreamController.stream;

  /// Stream emitted whenever a GDL90 heartbeat/message is received
  Stream<DateTime> get heartbeatStream => _heartbeatStreamController.stream;

  /// Timestamp of the last received GDL90 heartbeat/message
  DateTime? get lastHeartbeatTime => _lastHeartbeatTime;

  /// Whether a heartbeat was received within the last 10 seconds
  bool get isHeartbeatActive {
    if (_lastHeartbeatTime == null) return false;
    return DateTime.now().difference(_lastHeartbeatTime!) <=
        const Duration(seconds: 10);
  }

  /// Unmodifiable list of active GDL90 targets
  List<Gdl90Target> get targets => List.unmodifiable(_targets.values);

  /// Current bind status
  bool get isListening => _socket != null;

  /// Initialize service with initial configuration
  Future<void> start({
    bool enabled = true,
    String host = '0.0.0.0',
    int port = 4000,
    int expirySeconds = 60,
  }) async {
    _enabled = enabled;
    _bindHost = host;
    _bindPort = port;
    _expirySeconds = expirySeconds;

    debugPrint(
      '[Gdl90Service] Starting service (enabled: $_enabled, host: $_bindHost, port: $_bindPort, expiry: ${_expirySeconds}s)',
    );

    _startExpiryTimer();

    if (_enabled) {
      await _bindSocket();
    }
  }

  /// Update runtime configuration (rebinds socket if parameters change)
  Future<void> updateConfig({
    required bool enabled,
    required String host,
    required int port,
    required int expirySeconds,
  }) async {
    final needsRebind =
        _enabled != enabled || _bindHost != host || _bindPort != port;

    debugPrint(
      '[Gdl90Service] Updating config (enabled: $enabled, host: $host, port: $port, expiry: ${expirySeconds}s, needsRebind: $needsRebind)',
    );

    _enabled = enabled;
    _bindHost = host;
    _bindPort = port;
    _expirySeconds = expirySeconds;

    if (needsRebind) {
      await _closeSocket();
      if (_enabled) {
        await _bindSocket();
      }
    }
  }

  Future<void> _bindSocket() async {
    if (_isBinding) return;
    // UDP sockets are not available on Web — GDL90 requires native UDP
    if (kIsWeb) {
      debugPrint('[Gdl90Service] GDL90 UDP not supported on Web platform');
      return;
    }
    _isBinding = true;
    await _closeSocket();

    try {
      final dynamic address;
      if (_bindHost == '0.0.0.0') {
        address = InternetAddress.anyIPv4;
      } else if (_bindHost == '127.0.0.1') {
        address = InternetAddress.loopbackIPv4;
      } else {
        address = InternetAddress(_bindHost);
      }

      debugPrint(
        '[Gdl90Service] Attempting to bind UDP socket on $_bindHost:$_bindPort...',
      );

      _socket = await RawDatagramSocket.bind(
        address,
        _bindPort,
        reuseAddress: true,
        reusePort: true,
      );

      debugPrint(
        '[Gdl90Service] Successfully bound UDP socket on $_bindHost:$_bindPort (${address.address})',
      );

      _socket?.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null && datagram.data.isNotEmpty) {
              debugPrint(
                '[Gdl90Service] UDP datagram received: ${datagram.data.length} bytes from ${datagram.address.address}:${datagram.port}',
              );
              _handleDatagram(datagram.data);
            }
          }
        },
        onError: (error, stackTrace) {
          debugPrint('[Gdl90Service] UDP Socket error: $error\n$stackTrace');
        },
        onDone: () {
          debugPrint('[Gdl90Service] UDP Socket closed');
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[Gdl90Service] Failed to bind UDP socket on $_bindHost:$_bindPort: $e\n$stackTrace',
      );
    } finally {
      _isBinding = false;
    }
  }

  void _handleDatagram(Uint8List bytes) {
    try {
      final hexRaw = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      debugPrint('[Gdl90Service] RAW Datagram (${bytes.length}B): [$hexRaw]');

      final messages = _decoder.processBytes(bytes);
      if (messages.isEmpty) {
        debugPrint(
          '[Gdl90Service] Datagram received (${bytes.length} bytes) but zero valid GDL90 messages decoded',
        );
        return;
      }

      debugPrint(
        '[Gdl90Service] Decoded ${messages.length} GDL90 message(s) from datagram',
      );

      _recordHeartbeat();

      bool stateChanged = false;

      for (final msg in messages) {
        if (msg is Gdl90TrafficMessage) {
          debugPrint(
            '[Gdl90Service] GDL90 Traffic: id=${msg.target.id}, callsign=${msg.target.callsign ?? "N/A"}, lat=${msg.target.latitude}, lon=${msg.target.longitude}, alt=${msg.target.altitudeFeet}ft, speed=${msg.target.speedKnots}kts, track=${msg.target.trackDegrees}°, vsFpm=${msg.target.verticalSpeedFpm.toStringAsFixed(0)} (valid=${msg.target.verticalSpeedValid})',
          );
          _targets[msg.target.id] = msg.target;
          stateChanged = true;
        } else if (msg is Gdl90OwnshipMessage) {
          debugPrint(
            '[Gdl90Service] GDL90 Ownship: id=${msg.target.id}, callsign=${msg.target.callsign ?? "N/A"}, lat=${msg.target.latitude}, lon=${msg.target.longitude}, alt=${msg.target.altitudeFeet}ft, speed=${msg.target.speedKnots}kts, track=${msg.target.trackDegrees}°, vsFpm=${msg.target.verticalSpeedFpm.toStringAsFixed(0)} (valid=${msg.target.verticalSpeedValid})',
          );
          _targets[msg.target.id] = msg.target;
          stateChanged = true;
        } else {
          debugPrint(
            '[Gdl90Service] Other GDL90 Message parsed: ${msg.runtimeType}',
          );
        }
      }

      if (stateChanged) {
        // Notify with full target list so consumers always have the complete
        // picture (e.g., for purge-on-next-tick scenarios).
        _notifyTargets();
      }
    } catch (e, stackTrace) {
      debugPrint('[Gdl90Service] Error parsing datagram: $e\n$stackTrace');
    }
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _purgeExpiredTargets();
    });
  }

  void _purgeExpiredTargets() {
    if (_targets.isEmpty) return;

    final staleKeys = <String>[];
    for (final entry in _targets.entries) {
      if (entry.value.isExpired(_expirySeconds)) {
        staleKeys.add(entry.key);
      }
    }

    if (staleKeys.isNotEmpty) {
      for (final key in staleKeys) {
        _targets.remove(key);
      }
      debugPrint(
        '[Gdl90Service] Purged ${staleKeys.length} expired GDL90 targets',
      );
      _notifyTargets();
    }
  }

  void _recordHeartbeat() {
    _lastHeartbeatTime = DateTime.now();
    if (!_heartbeatStreamController.isClosed) {
      _heartbeatStreamController.add(_lastHeartbeatTime!);
    }
  }

  void _notifyTargets() {
    if (!_targetStreamController.isClosed) {
      _targetStreamController.add(targets);
    }
  }

  Future<void> _closeSocket() async {
    if (_socket != null) {
      debugPrint('[Gdl90Service] Closing UDP socket');
      _socket?.close();
      _socket = null;
    }
  }

  /// Stop listener and dispose all resources
  Future<void> dispose() async {
    _expiryTimer?.cancel();
    await _closeSocket();
    await _targetStreamController.close();
    await _heartbeatStreamController.close();
    _targets.clear();
  }
}
