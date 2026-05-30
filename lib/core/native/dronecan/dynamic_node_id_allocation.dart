import 'package:flutter/foundation.dart';

import 'dronecan_message.dart';

class DynamicNodeIdAllocation implements DroneCanRequestResponseMessage {
  static const int messageId = 1;
  static const int messageSignature = 0xb2a812620a11d40;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final int nodeId;
  final bool firstPartOfUniqueId;
  final Uint8List uniqueId;

  DynamicNodeIdAllocation({
    required this.nodeId,
    required this.firstPartOfUniqueId,
    required this.uniqueId,
  });

  factory DynamicNodeIdAllocation.fromPayload(Uint8List payload) {
    if (payload.isEmpty) {
      throw FormatException('Payload too short for DynamicNodeIdAllocation');
    }
    // dronecane answer should send firstPart always as false as first part is request, therefore no need to read it
    final firstPart = false;
    final id = payload[0] >> 1;
    final uniqueIdBytes = payload.sublist(1);

    debugPrint('nodeId : $id,  uniqueIdBytes : ${uniqueIdBytes.toString()}');

    return DynamicNodeIdAllocation(
      nodeId: id,
      firstPartOfUniqueId: firstPart,
      uniqueId: uniqueIdBytes,
    );
  }

  @override
  Uint8List toPayload() {
    if (nodeId < 0 || nodeId > 127) {
      throw RangeError(
        'nodeId must be between 0 and 127 (inclusive), got $nodeId',
      );
    }
    final payload = Uint8List(1 + uniqueId.length);
    payload[0] = (nodeId << 1) | (firstPartOfUniqueId ? 0x01 : 0x00);
    payload.setRange(1, payload.length, uniqueId);
    debugPrint(
      'sendNodeId : $nodeId, firstPartOfUniqueId : $firstPartOfUniqueId, uniqueId : ${uniqueId.toString()}, payload: ${payload.toString()}',
    );
    return payload;
  }
}
