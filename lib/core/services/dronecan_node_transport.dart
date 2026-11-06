import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';

/// Answers a `uavcan.protocol.file.Read` request received from [nodeId].
///
/// Returns at most [maxLength] bytes starting at [offset], an empty list at or
/// past the end of the file, or `null` when [path] is not served.
typedef DroneCanFileReadHandler =
    List<int>? Function(int nodeId, String path, int offset, int maxLength);

/// Transport-level operations required for DroneCAN node management.
///
/// Implemented by the platform-specific [CannelloniService] so higher layers can
/// consume node data without depending on the underlying transport.
abstract interface class DroneCanNodeTransport {
  /// Stream of node status heartbeats and registry resets.
  Stream<NodeStatusEvent> get nodeStatusEvents;

  /// Requests `uavcan.protocol.GetNodeInfo` from [nodeId].
  Future<GetNodeInfoResponse> getNodeInfo(int nodeId, {Duration timeout});

  /// Requests `uavcan.protocol.RestartNode` from [nodeId].
  ///
  /// Returns `true` when the node accepted the restart.
  Future<bool> restartNode(int nodeId, {Duration timeout});

  /// Requests `uavcan.protocol.GetTransportStats` from [nodeId].
  Future<GetTransportStatsResponse> getTransportStats(
    int nodeId, {
    Duration timeout,
  });

  /// Sends `uavcan.protocol.param.GetSet` to [nodeId].
  ///
  /// [request] either asks for the parameter at an index (index scan) or for a
  /// parameter by name, optionally assigning a new value first.
  Future<GetSetResponse> getSetParameter(
    int nodeId,
    GetSetRequest request, {
    Duration timeout,
  });

  /// Sends `uavcan.protocol.param.ExecuteOpcode` to [nodeId].
  ///
  /// Returns `true` when the node performed the operation.
  Future<bool> executeParameterOpcode(
    int nodeId,
    int opcode, {
    Duration timeout,
  });

  /// Sends `uavcan.protocol.file.BeginFirmwareUpdate` to [nodeId].
  ///
  /// The node then fetches the image through `uavcan.protocol.file.Read`
  /// requests, which are answered by the registered [fileReadHandler].
  Future<BeginFirmwareUpdateResponse> beginFirmwareUpdate(
    int nodeId,
    String path, {
    Duration timeout,
  });

  /// Registers the handler that serves `uavcan.protocol.file.Read` requests.
  ///
  /// Set to `null` to stop serving files.
  set fileReadHandler(DroneCanFileReadHandler? handler);
}
