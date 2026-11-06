import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';
import 'package:stork/core/services/dronecan_node_transport.dart';

part 'cannelloni_service_stub.g.dart';

@Riverpod(keepAlive: true)
class CannelloniService extends _$CannelloniService
    implements DroneCanNodeTransport {
  /// There is no CAN transport on this platform, so no node status is emitted.
  @override
  Stream<NodeStatusEvent> get nodeStatusEvents => const Stream.empty();

  @override
  bool build() {
    // Stub implementation for web/unsupported platforms
    return false;
  }

  /// Node discovery requires a native DroneCAN transport.
  @override
  Future<GetNodeInfoResponse> getNodeInfo(
    int nodeId, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    throw UnsupportedError(
      'DroneCAN node discovery is not supported on this platform.',
    );
  }

  @override
  Future<bool> restartNode(
    int nodeId, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    throw UnsupportedError(
      'DroneCAN node management is not supported on this platform.',
    );
  }

  @override
  Future<GetTransportStatsResponse> getTransportStats(
    int nodeId, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    throw UnsupportedError(
      'DroneCAN node management is not supported on this platform.',
    );
  }

  @override
  Future<GetSetResponse> getSetParameter(
    int nodeId,
    GetSetRequest request, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    throw UnsupportedError(
      'DroneCAN node configuration is not supported on this platform.',
    );
  }

  @override
  Future<bool> executeParameterOpcode(
    int nodeId,
    int opcode, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    throw UnsupportedError(
      'DroneCAN node configuration is not supported on this platform.',
    );
  }

  @override
  Future<BeginFirmwareUpdateResponse> beginFirmwareUpdate(
    int nodeId,
    String path, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    throw UnsupportedError(
      'DroneCAN firmware update is not supported on this platform.',
    );
  }

  @override
  set fileReadHandler(DroneCanFileReadHandler? handler) {}

  @visibleForTesting
  Future<Uint8List> loadOrGenerateUniqueIdForTesting() async {
    return Uint8List(16);
  }
}
