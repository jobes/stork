import 'dart:async';

import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';
import 'package:stork/core/services/dronecan_node_transport.dart';

/// Configurable [DroneCanNodeTransport] used by the DroneCAN device tests.
///
/// Unset response callbacks make the matching request time out, which is what
/// a node that does not answer looks like.
class FakeDroneCanNodeTransport implements DroneCanNodeTransport {
  final StreamController<NodeStatusEvent> _controller =
      StreamController<NodeStatusEvent>.broadcast();

  final List<int> infoRequests = [];
  GetNodeInfoResponse Function(int nodeId)? infoResponse;

  final List<int> restartRequests = [];
  bool restartAccepted = true;

  final List<GetSetRequest> parameterRequests = [];
  GetSetResponse Function(GetSetRequest request)? parameterResponse;

  final List<int> opcodeRequests = [];
  bool opcodeAccepted = true;

  final List<int> statsRequests = [];
  GetTransportStatsResponse statsResponse = const GetTransportStatsResponse(
    transfersTx: 0,
    transfersRx: 0,
    transferErrors: 0,
    canIfaceStats: [],
  );

  final List<({int nodeId, String path})> beginFirmwareRequests = [];
  BeginFirmwareUpdateResponse beginFirmwareResponse =
      const BeginFirmwareUpdateResponse(
        error: BeginFirmwareUpdateResponse.errorOk,
      );
  Object? beginFirmwareError;

  @override
  DroneCanFileReadHandler? fileReadHandler;

  @override
  Stream<NodeStatusEvent> get nodeStatusEvents => _controller.stream;

  @override
  Future<GetNodeInfoResponse> getNodeInfo(
    int nodeId, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    infoRequests.add(nodeId);
    final response = infoResponse;
    if (response == null) {
      throw TimeoutException('No fake node info');
    }
    return response(nodeId);
  }

  @override
  Future<bool> restartNode(
    int nodeId, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    restartRequests.add(nodeId);
    return restartAccepted;
  }

  @override
  Future<GetTransportStatsResponse> getTransportStats(
    int nodeId, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    statsRequests.add(nodeId);
    return statsResponse;
  }

  @override
  Future<GetSetResponse> getSetParameter(
    int nodeId,
    GetSetRequest request, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    parameterRequests.add(request);
    final response = parameterResponse;
    if (response == null) {
      throw TimeoutException('No fake parameter response');
    }
    return response(request);
  }

  @override
  Future<bool> executeParameterOpcode(
    int nodeId,
    int opcode, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    opcodeRequests.add(opcode);
    return opcodeAccepted;
  }

  @override
  Future<BeginFirmwareUpdateResponse> beginFirmwareUpdate(
    int nodeId,
    String path, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    beginFirmwareRequests.add((nodeId: nodeId, path: path));
    final error = beginFirmwareError;
    if (error != null) throw error;
    return beginFirmwareResponse;
  }

  void addEvent(NodeStatusEvent event) => _controller.add(event);

  Future<void> close() => _controller.close();
}
