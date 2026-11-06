import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/canard_bindings.dart';
import 'package:stork/core/native/dronecan/dynamic_node_id_allocation.dart';
import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/ice_status.dart';
import 'package:stork/core/native/dronecan/indicated_airspeed.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';
import 'package:stork/core/native/dronecan/restart_node.dart';
import 'package:stork/core/native/dronecan/static_pressure.dart';
import 'package:stork/core/native/dronecan/vhf_radio_control.dart';
import 'package:stork/core/services/dronecan_transfer_signature.dart';

void main() {
  group('droneCanSignatureForTransfer', () {
    test('accepts the broadcast messages used by the app', () {
      expect(
        droneCanSignatureForTransfer(
          NodeStatus.messageId,
          CanardTransferType.broadcast,
        ),
        equals(NodeStatus.messageSignature),
      );
      expect(
        droneCanSignatureForTransfer(
          DynamicNodeIdAllocation.messageId,
          CanardTransferType.broadcast,
        ),
        equals(DynamicNodeIdAllocation.messageSignature),
      );
      expect(
        droneCanSignatureForTransfer(
          StaticPressure.messageId,
          CanardTransferType.broadcast,
        ),
        equals(StaticPressure.messageSignature),
      );
      expect(
        droneCanSignatureForTransfer(
          IceStatus.messageId,
          CanardTransferType.broadcast,
        ),
        equals(IceStatus.messageSignature),
      );
      expect(
        droneCanSignatureForTransfer(
          IndicatedAirspeed.messageId,
          CanardTransferType.broadcast,
        ),
        equals(IndicatedAirspeed.messageSignature),
      );
    });

    test('rejects a service transfer for a broadcast message id', () {
      expect(
        droneCanSignatureForTransfer(
          NodeStatus.messageId,
          CanardTransferType.request,
        ),
        isNull,
      );
      expect(
        droneCanSignatureForTransfer(
          NodeStatus.messageId,
          CanardTransferType.response,
        ),
        isNull,
      );
    });

    test('accepts GetNodeInfo requests and responses', () {
      for (final type in [
        CanardTransferType.request,
        CanardTransferType.response,
      ]) {
        expect(
          droneCanSignatureForTransfer(GetNodeInfoResponse.messageId, type),
          equals(GetNodeInfoResponse.messageSignature),
          reason: 'transfer type: ${type.name}',
        );
      }
    });

    test('accepts responses of the node management services', () {
      final responses = {
        RestartNode.messageId: RestartNode.messageSignature,
        GetTransportStats.messageId: GetTransportStats.messageSignature,
        GetSetRequest.messageId: GetSetRequest.messageSignature,
        ExecuteOpcodeRequest.messageId: ExecuteOpcodeRequest.messageSignature,
        BeginFirmwareUpdateRequest.messageId:
            BeginFirmwareUpdateRequest.messageSignature,
        VhfRadioControlResponse.messageId:
            VhfRadioControlResponse.messageSignature,
      };

      responses.forEach((dataTypeId, signature) {
        expect(
          droneCanSignatureForTransfer(dataTypeId, CanardTransferType.response),
          equals(signature),
          reason: 'data type id: $dataTypeId',
        );
      });
    });

    test('accepts only the firmware image request', () {
      expect(
        droneCanSignatureForTransfer(
          FileReadRequest.messageId,
          CanardTransferType.request,
        ),
        equals(FileReadRequest.messageSignature),
      );
      expect(
        droneCanSignatureForTransfer(
          FileReadRequest.messageId,
          CanardTransferType.response,
        ),
        isNull,
      );
    });

    test('does not accept requests for services it does not serve', () {
      for (final dataTypeId in [
        RestartNode.messageId,
        GetTransportStats.messageId,
        GetSetRequest.messageId,
        ExecuteOpcodeRequest.messageId,
        BeginFirmwareUpdateRequest.messageId,
        VhfRadioControlResponse.messageId,
      ]) {
        expect(
          droneCanSignatureForTransfer(dataTypeId, CanardTransferType.request),
          isNull,
          reason: 'data type id: $dataTypeId',
        );
      }
    });

    test('rejects message ids shared with broadcasts', () {
      // ID 5 also belongs to `uavcan.protocol.Panic`.
      expect(
        droneCanSignatureForTransfer(
          RestartNode.messageId,
          CanardTransferType.broadcast,
        ),
        isNull,
      );
      // ID 4 also belongs to `uavcan.protocol.GlobalTimeSync`.
      expect(
        droneCanSignatureForTransfer(
          GetTransportStats.messageId,
          CanardTransferType.broadcast,
        ),
        isNull,
      );
    });

    test('rejects unknown message ids', () {
      expect(
        droneCanSignatureForTransfer(9999, CanardTransferType.broadcast),
        isNull,
      );
      expect(
        droneCanSignatureForTransfer(9999, CanardTransferType.response),
        isNull,
      );
    });
  });
}
