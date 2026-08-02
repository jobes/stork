import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint, visibleForTesting;
import '../domain/models/gdl90_target.dart';
import 'gdl90_decoder.dart';

/// UDP Network Listener & Service for GDL90 Traffic Broadcasts
class Gdl90Service {
  Gdl90Service({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _decoder = Gdl90Decoder(now: now ?? DateTime.now);

  /// Injectable clock for deterministic heartbeat/expiry tests. The decoder
  /// shares the same clock so target `lastUpdated` stays consistent.
  final DateTime Function() _now;

  final Gdl90Decoder _decoder;
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

  /// The bind currently in flight, if any. Concurrent [start]/[updateConfig]
  /// calls await this future so the socket is always (re)bound to the latest
  /// host/port/enabled configuration.
  Future<void>? _pendingBind;

  /// Host/port the currently open socket was bound to (''/0 when none).
  String _boundHost = '';
  int _boundPort = 0;

  /// Stream of active GDL90 targets
  Stream<List<Gdl90Target>> get targetStream => _targetStreamController.stream;

  /// Stream emitted whenever a GDL90 heartbeat/message is received
  Stream<DateTime> get heartbeatStream => _heartbeatStreamController.stream;

  /// Timestamp of the last received GDL90 heartbeat/message
  DateTime? get lastHeartbeatTime => _lastHeartbeatTime;

  /// Whether a heartbeat was received within the last 10 seconds
  bool get isHeartbeatActive {
    if (_lastHeartbeatTime == null) return false;
    return _now().difference(_lastHeartbeatTime!) <=
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
    // Wait for any in-flight bind to settle before applying the initial
    // config, so a concurrent bind cannot clobber it.
    await _awaitPendingBind();

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
    } else {
      // A disabled start must not leave a bound socket behind (e.g. when a
      // previous bind was still in flight).
      await _closeSocket();
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

    // Apply the latest host/port/enabled state only after any in-flight bind
    // has settled, so it cannot be clobbered by a concurrent bind (and the
    // disable case always ends with a closed socket).
    await _awaitPendingBind();

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

  /// Awaits any bind currently in flight, if there is one.
  Future<void> _awaitPendingBind() async {
    final pending = _pendingBind;
    if (pending != null) {
      await pending;
    }
  }

  /// Whether the open socket is already bound to the current host/port.
  bool get _isBoundToCurrentConfig =>
      _socket != null && _boundHost == _bindHost && _boundPort == _bindPort;

  /// Binds the UDP socket to the current host/port. Concurrent calls are
  /// serialized: if a bind is already in flight, later callers await it and
  /// then re-evaluate the latest configuration, so config updates made while
  /// binding are never lost to an early return.
  Future<void> _bindSocket() async {
    // UDP sockets are not available on Web — GDL90 requires native UDP
    if (kIsWeb) {
      debugPrint('[Gdl90Service] GDL90 UDP not supported on Web platform');
      return;
    }

    while (true) {
      // Serialize: wait for any in-flight bind to settle first.
      final pending = _pendingBind;
      if (pending != null) {
        await pending;
        continue;
      }

      // Re-evaluate the current configuration: another caller may have changed
      // host/port/enabled while we were waiting.
      if (!_enabled || _isBoundToCurrentConfig) return;

      final completer = Completer<void>();
      _pendingBind = completer.future;
      try {
        final bound = await _performBind();
        completer.complete();
        // On a failed bind, stop here and let a later config change trigger a
        // new attempt (avoids a tight retry loop when e.g. the port is in use).
        if (!bound) return;
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
        rethrow;
      } finally {
        _pendingBind = null;
      }

      // The config may have changed while binding — loop to re-evaluate.
    }
  }

  /// Performs a single bind with the current host/port. Returns whether the
  /// bind succeeded (failures are logged, not thrown).
  Future<bool> _performBind() async {
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

      _boundHost = _bindHost;
      _boundPort = _bindPort;

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

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[Gdl90Service] Failed to bind UDP socket on $_bindHost:$_bindPort: $e\n$stackTrace',
      );
      return false;
    }
  }

  void _handleDatagram(Uint8List bytes) {
    try {
      final messages = _decoder.processBytes(bytes);
      if (messages.isEmpty) {
        debugPrint(
          '[Gdl90Service] Datagram received (${bytes.length} bytes) but zero valid GDL90 messages decoded',
        );
        return;
      }

      _recordHeartbeat();

      var hasTraffic = false;

      for (final msg in messages) {
        if (msg is Gdl90TrafficMessage) {
          _targets[msg.target.id] = msg.target;
          hasTraffic = true;
        }
        // Gdl90OwnshipMessage carries the receiver's OWN position — it is
        // intentionally NOT part of traffic targets (the own aircraft must
        // never appear as a traffic target on the map).
      }

      if (hasTraffic) {
        // Notify with full target list so consumers always have the complete
        // picture (e.g., for purge-on-next-tick scenarios).
        _notifyTargets();
      }
    } catch (e, stackTrace) {
      debugPrint('[Gdl90Service] Error parsing datagram: $e\n$stackTrace');
    }
  }

  /// Feeds raw UDP datagram bytes through the decoder and updates internal
  /// target/heartbeat state. Exposed for unit tests (the socket listener uses
  /// the same path).
  @visibleForTesting
  void handleDatagram(Uint8List bytes) {
    _handleDatagram(bytes);
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
      if (entry.value.isExpired(_expirySeconds, _now())) {
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

  /// Runs the expired-target purge immediately. Exposed for unit tests (the
  /// periodic expiry timer uses the same path).
  @visibleForTesting
  void purgeExpiredTargets() {
    _purgeExpiredTargets();
  }

  void _recordHeartbeat() {
    _lastHeartbeatTime = _now();
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
    _boundHost = '';
    _boundPort = 0;
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
