import 'package:stork/core/native/canard_bindings.dart';
import 'package:stork/core/native/dronecan/dynamic_node_id_allocation.dart';
import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/fix2.dart';
import 'package:stork/core/native/dronecan/fuel_tank_status.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/ice_status.dart';
import 'package:stork/core/native/dronecan/indicated_airspeed.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';
import 'package:stork/core/native/dronecan/restart_node.dart';
import 'package:stork/core/native/dronecan/static_pressure.dart';
import 'package:stork/core/native/dronecan/stork_engine_rpm.dart';
import 'package:stork/core/native/dronecan/vhf_radio_control.dart';
import 'package:stork/core/native/dronecan/vhf_radio_fast_status.dart';
import 'package:stork/core/native/dronecan/vhf_radio_full_status.dart';

/// Data type signature the app accepts for an incoming transfer, or `null`
/// when the transfer is not relevant to the app.
///
/// Some message IDs are shared between a service and a broadcast (`Panic` vs
/// `RestartNode`, `GlobalTimeSync` vs `GetTransportStats`), so both the ID and
/// the transfer type have to match.
int? droneCanSignatureForTransfer(
  int dataTypeId,
  CanardTransferType transferType,
) {
  if (transferType == CanardTransferType.broadcast) {
    return _broadcastSignature(dataTypeId);
  }

  return _serviceSignature(dataTypeId, transferType);
}

int? _broadcastSignature(int dataTypeId) {
  return switch (dataTypeId) {
    DynamicNodeIdAllocation.messageId =>
      DynamicNodeIdAllocation.messageSignature,
    NodeStatus.messageId => NodeStatus.messageSignature,
    StaticPressure.messageId => StaticPressure.messageSignature,
    Fix2.messageId => Fix2.messageSignature,
    IceStatus.messageId => IceStatus.messageSignature,
    FuelTankStatus.messageId => FuelTankStatus.messageSignature,
    StorkEngineRpm.messageId => StorkEngineRpm.messageSignature,
    IndicatedAirspeed.messageId => IndicatedAirspeed.messageSignature,
    VhfRadioFullStatus.messageId => VhfRadioFullStatus.messageSignature,
    VhfRadioFastStatus.messageId => VhfRadioFastStatus.messageSignature,
    _ => null,
  };
}

int? _serviceSignature(int dataTypeId, CanardTransferType transferType) {
  // Requests are only expected for the services the app itself serves
  // (GetNodeInfo and the firmware image); everything else is a response to a
  // request sent by the app.
  return switch (dataTypeId) {
    GetNodeInfoResponse.messageId =>
      transferType == CanardTransferType.request ||
              transferType == CanardTransferType.response
          ? GetNodeInfoResponse.messageSignature
          : null,
    VhfRadioControlResponse.messageId =>
      transferType == CanardTransferType.response
          ? VhfRadioControlResponse.messageSignature
          : null,
    RestartNode.messageId =>
      transferType == CanardTransferType.response
          ? RestartNode.messageSignature
          : null,
    GetTransportStats.messageId =>
      transferType == CanardTransferType.response
          ? GetTransportStats.messageSignature
          : null,
    GetSetRequest.messageId =>
      transferType == CanardTransferType.response
          ? GetSetRequest.messageSignature
          : null,
    ExecuteOpcodeRequest.messageId =>
      transferType == CanardTransferType.response
          ? ExecuteOpcodeRequest.messageSignature
          : null,
    FileReadRequest.messageId =>
      transferType == CanardTransferType.request
          ? FileReadRequest.messageSignature
          : null,
    BeginFirmwareUpdateRequest.messageId =>
      transferType == CanardTransferType.response
          ? BeginFirmwareUpdateRequest.messageSignature
          : null,
    _ => null,
  };
}
