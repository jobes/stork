import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';
import 'package:stork/core/services/dronecan_node_transport.dart';
import 'package:stork/core/utils/hex_utils.dart';

import '../../domain/models/dronecan_node.dart';
import '../../domain/models/dronecan_node_info_refresh.dart';
import '../../domain/models/dronecan_parameter.dart';
import '../../domain/models/firmware_update_progress.dart';
import '../../domain/models/transport_statistics.dart';
import '../../domain/repositories/dronecan_node_repository.dart';
import '../mappers/dronecan_protocol_mappers.dart';
import '../services/firmware_upload_session.dart';

/// Keeps an in-memory registry of DroneCAN nodes discovered from heartbeats.
///
/// Nothing is persisted: the registry lives only as long as the connection and
/// is cleared as soon as the DroneCAN link is reset.
class DroneCanNodeRepositoryImpl implements DroneCanNodeRepository {
  DroneCanNodeRepositoryImpl(this._transport);

  /// Delay before the first `GetNodeInfo` retry. It doubles with every failed
  /// attempt up to [_nodeInfoMaxRetryInterval], so a node that does not
  /// implement the service is not polled every few seconds forever.
  static const Duration _nodeInfoRetryInterval = Duration(seconds: 5);
  static const Duration _nodeInfoMaxRetryInterval = Duration(minutes: 1);

  /// Parameter round trips are short; a slow response just ends the scan.
  static const Duration _parameterTimeout = Duration(milliseconds: 500);

  /// Attempts per parameter read.
  ///
  /// A single lost CAN frame used to abort the whole index scan, so a read that
  /// timed out is retried before the scan gives up.
  static const int _parameterReadAttempts = 2;

  /// Safety stop for nodes that keep answering with parameters forever.
  static const int _maxParameterCount = 1024;

  final DroneCanNodeTransport _transport;
  final Map<int, DroneCanNode> _nodes = {};
  final Set<int> _inFlightInfoRequests = {};
  final Map<int, DateTime> _lastInfoAttempt = {};
  final Map<int, int> _infoFailures = {};
  final StreamController<List<DroneCanNode>> _controller =
      StreamController<List<DroneCanNode>>.broadcast();

  StreamSubscription<NodeStatusEvent>? _subscription;
  Timer? _ticker;
  bool _started = false;
  bool _disposed = false;
  FirmwareUploadSession? _firmwareUpload;

  @override
  Stream<List<DroneCanNode>> watchNodes() {
    _start();
    // Subscribing before the snapshot is emitted means no heartbeat can slip
    // between the initial list and the live updates.
    return Stream<List<DroneCanNode>>.multi((controller) {
      controller.add(_snapshot());
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  /// Starts listening to the bus on first use, so constructing the repository
  /// has no side effects.
  void _start() {
    if (_started || _disposed) return;
    _started = true;
    _subscription = _transport.nodeStatusEvents.listen(_handleEvent);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
  }

  @override
  Stream<List<DroneCanParameter>> watchParameters(int nodeId) async* {
    final parameters = <DroneCanParameter>[];
    yield const <DroneCanParameter>[];

    for (var index = 0; index < _maxParameterCount; index++) {
      final parameter = await getParameterByIndex(nodeId, index);
      if (_disposed) return;
      if (parameter == null) return;

      parameters.add(parameter);
      yield List<DroneCanParameter>.unmodifiable(parameters);
    }
  }

  @override
  Future<DroneCanNodeInfoRefresh> refreshNodeInfo() async {
    _start();
    _lastInfoAttempt.clear();
    _infoFailures.clear();

    final nodeIds = _nodes.keys.toList();
    if (nodeIds.isEmpty) {
      return const DroneCanNodeInfoRefresh(requested: 0, answered: 0);
    }

    final answers = await Future.wait(
      nodeIds.map((nodeId) => _fetchNodeInfo(nodeId, force: true)),
    );

    return DroneCanNodeInfoRefresh(
      requested: nodeIds.length,
      answered: answers.where((answered) => answered).length,
    );
  }

  @override
  Future<bool> restartNode(int nodeId) async {
    final accepted = await _transport.restartNode(nodeId);
    if (accepted) {
      // The node reboots, so its cached GetNodeInfo data is stale and has to
      // be read again once it is back.
      _forgetNodeInfo(nodeId);
    }
    return accepted;
  }

  @override
  Future<TransportStatistics> getTransportStats(int nodeId) async {
    final stats = await _transport.getTransportStats(nodeId);
    return TransportStatistics(
      transfersTx: stats.transfersTx,
      transfersRx: stats.transfersRx,
      transferErrors: stats.transferErrors,
      canInterfaces: List<CanInterfaceStatistics>.unmodifiable(
        stats.canIfaceStats.map(
          (iface) => CanInterfaceStatistics(
            framesTx: iface.framesTx,
            framesRx: iface.framesRx,
            errors: iface.errors,
          ),
        ),
      ),
    );
  }

  @override
  Future<DroneCanParameter?> getParameterByIndex(int nodeId, int index) async {
    final response = await _getSetParameterWithRetry(
      nodeId,
      GetSetRequest.byIndex(index),
    );
    if (!response.isKnown) return null;

    return DroneCanParameter(
      index: index,
      name: response.name,
      value: droneCanParamValueFromProtocol(response.value!),
      defaultValue: response.defaultValue == null
          ? null
          : droneCanParamValueFromProtocol(response.defaultValue!),
      minValue: response.minValue?.value,
      maxValue: response.maxValue?.value,
    );
  }

  /// Reads a parameter, retrying a timed-out request.
  ///
  /// Only timeouts are retried: a node that answers with an error or with a
  /// malformed payload must not be asked again.
  Future<GetSetResponse> _getSetParameterWithRetry(
    int nodeId,
    GetSetRequest request,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _transport.getSetParameter(
          nodeId,
          request,
          timeout: _parameterTimeout,
        );
      } on TimeoutException {
        if (attempt >= _parameterReadAttempts) rethrow;
        final label = request.name.isEmpty
            ? 'parameter at index ${request.index}'
            : 'parameter "${request.name}"';
        debugPrint(
          'DroneCAN $label of node $nodeId timed out, retrying '
          '(attempt ${attempt + 1}/$_parameterReadAttempts)',
        );
      }
    }
  }

  @override
  Future<DroneCanParameter> setParameterValue(
    int nodeId,
    DroneCanParameter parameter,
    DroneCanParamValue value,
  ) async {
    final response = await _transport.getSetParameter(
      nodeId,
      GetSetRequest.byName(
        parameter.name,
        value: droneCanParamValueToProtocol(value),
      ),
      timeout: _parameterTimeout,
    );
    if (!response.isKnown) {
      throw StateError(
        'Node $nodeId does not accept the parameter "${parameter.name}".',
      );
    }

    return parameter.merge(
      DroneCanParameter(
        index: parameter.index,
        name: response.name,
        value: droneCanParamValueFromProtocol(response.value!),
        defaultValue: response.defaultValue == null
            ? null
            : droneCanParamValueFromProtocol(response.defaultValue!),
        minValue: response.minValue?.value,
        maxValue: response.maxValue?.value,
      ),
    );
  }

  @override
  Future<bool> storeParameters(int nodeId) {
    return _transport.executeParameterOpcode(
      nodeId,
      ExecuteOpcodeRequest.opcodeSave,
    );
  }

  @override
  Future<bool> eraseParameters(int nodeId) {
    return _transport.executeParameterOpcode(
      nodeId,
      ExecuteOpcodeRequest.opcodeErase,
    );
  }

  @override
  Stream<FirmwareUpdateProgress> updateFirmware(
    int nodeId,
    String fileName,
    Uint8List firmware,
  ) {
    if (_firmwareUpload != null) {
      throw StateError('A firmware update is already in progress.');
    }

    final session = FirmwareUploadSession(
      transport: _transport,
      nodeId: nodeId,
      fileName: fileName,
      firmware: firmware,
      // The node reboots with the new firmware, so its version must be re-read.
      onImageServed: () => _forgetNodeInfo(nodeId),
      onFinished: () => _firmwareUpload = null,
    );
    _firmwareUpload = session;
    return session.start();
  }

  /// Drops the cached `GetNodeInfo` data of [nodeId] so it is read again, e.g.
  /// after the node was updated and restarted.
  void _forgetNodeInfo(int nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    _nodes[nodeId] = node.copyWith(
      name: null,
      uniqueId: null,
      swMajor: null,
      swMinor: null,
      swOptionalFieldFlags: null,
      swVcsCommit: null,
      swImageCrc: null,
      hwMajor: null,
      hwMinor: null,
      certificateOfAuthenticity: null,
    );
    _lastInfoAttempt.remove(nodeId);
    _infoFailures.remove(nodeId);
    _emit();
  }

  void _handleEvent(NodeStatusEvent event) {
    switch (event) {
      case NodeStatusRegistryClearedEvent():
        _nodes.clear();
        _lastInfoAttempt.clear();
        _infoFailures.clear();
        _emit();
      case NodeStatusReceivedEvent(
        :final nodeId,
        :final status,
        :final receivedAt,
      ):
        final existing =
            _nodes[nodeId] ??
            DroneCanNode(
              nodeId: nodeId,
              health: droneCanNodeHealthFromProtocol(status.health),
              mode: droneCanNodeModeFromProtocol(status.mode),
              uptimeSec: status.uptimeSec,
              lastSeen: receivedAt,
            );
        _nodes[nodeId] = existing.copyWith(
          health: droneCanNodeHealthFromProtocol(status.health),
          mode: droneCanNodeModeFromProtocol(status.mode),
          uptimeSec: status.uptimeSec,
          lastSeen: receivedAt,
          vendorSpecificStatusCode: status.vendorSpecificStatusCode,
        );
        unawaited(_fetchNodeInfo(nodeId));
        _emit();
    }
  }

  /// Reads and caches `GetNodeInfo` of [nodeId].
  ///
  /// Returns `true` when the node answered, `false` when the request was
  /// skipped (nothing to read, already in flight, backing off) or failed.
  Future<bool> _fetchNodeInfo(int nodeId, {bool force = false}) async {
    if (_disposed) return false;

    final node = _nodes[nodeId];
    if (node == null) return false;
    if (!force && node.name != null && node.uniqueId != null) return false;
    if (_inFlightInfoRequests.contains(nodeId)) return false;

    final lastAttempt = _lastInfoAttempt[nodeId];
    final now = DateTime.now();
    if (!force &&
        lastAttempt != null &&
        now.difference(lastAttempt) < _retryDelay(_infoFailures[nodeId] ?? 0)) {
      return false;
    }
    _lastInfoAttempt[nodeId] = now;
    _inFlightInfoRequests.add(nodeId);

    try {
      final info = await _transport.getNodeInfo(nodeId);
      if (_disposed) return false;

      final current = _nodes[nodeId];
      if (current == null) return false;
      _infoFailures.remove(nodeId);

      final name = utf8.decode(info.name, allowMalformed: true).trim();
      _nodes[nodeId] = current.copyWith(
        name: name.isEmpty ? null : name,
        uniqueId: formatHexBytes(info.uniqueId),
        swMajor: info.swMajor,
        swMinor: info.swMinor,
        swOptionalFieldFlags: info.optionalFieldFlags,
        swVcsCommit: info.vcsCommit,
        swImageCrc: formatHexBigInt(info.imageCrc, digits: 16),
        hwMajor: info.hwMajor,
        hwMinor: info.hwMinor,
        certificateOfAuthenticity: info.certificateOfAuthenticity.isEmpty
            ? null
            : formatHexBytes(info.certificateOfAuthenticity),
      );
      _emit();
      return true;
    } catch (e) {
      debugPrint('DroneCAN node $nodeId GetNodeInfo failed: $e');
      _infoFailures[nodeId] = (_infoFailures[nodeId] ?? 0) + 1;
      return false;
    } finally {
      _inFlightInfoRequests.remove(nodeId);
    }
  }

  /// Backs off the `GetNodeInfo` retries of a node that already failed
  /// [failedAttempts] times, capped at [_nodeInfoMaxRetryInterval].
  static Duration _retryDelay(int failedAttempts) {
    var delay = _nodeInfoRetryInterval;
    for (var i = 1; i < failedAttempts; i++) {
      if (delay >= _nodeInfoMaxRetryInterval) break;
      delay *= 2;
    }
    return delay > _nodeInfoMaxRetryInterval
        ? _nodeInfoMaxRetryInterval
        : delay;
  }

  List<DroneCanNode> _snapshot() {
    final nodes = _nodes.values.toList()
      ..sort((a, b) => a.nodeId.compareTo(b.nodeId));
    return List<DroneCanNode>.unmodifiable(nodes);
  }

  void _emit() {
    if (_disposed) return;
    _controller.add(_snapshot());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _firmwareUpload?.cancel();
    _firmwareUpload = null;
    _ticker?.cancel();
    _subscription?.cancel();
    _controller.close();
  }
}
