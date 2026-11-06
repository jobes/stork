import 'dart:typed_data';

import 'dronecan_message.dart';

/// `uavcan.protocol.RestartNode` request.
///
/// The request carries a magic number so a node can reject accidental restarts.
class RestartNode implements DroneCanRequestResponseMessage {
  static const int messageId = 5;
  static const int messageSignature = 0x569E05394A3017F0;
  static const bool messageIsService = true;

  /// `MAGIC_NUMBER` from the DSDL definition.
  static const int magicNumber = 0xACCE551B1E;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  @override
  Uint8List toPayload() {
    final payload = Uint8List(5);
    final data = ByteData.sublistView(payload);
    // uint40 little endian.
    data.setUint32(0, magicNumber & 0xFFFFFFFF, Endian.little);
    data.setUint8(4, (magicNumber >> 32) & 0xFF);
    return payload;
  }
}

/// `uavcan.protocol.RestartNode` response.
class RestartNodeResponse implements DroneCanMessage {
  static const int messageId = RestartNode.messageId;
  static const int messageSignature = RestartNode.messageSignature;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final bool ok;

  const RestartNodeResponse({required this.ok});

  factory RestartNodeResponse.fromPayload(Uint8List payload) {
    if (payload.isEmpty) {
      throw FormatException('Payload too short for RestartNodeResponse');
    }
    // `ok` is a single bit at the start of the payload.
    return RestartNodeResponse(ok: (payload[0] & 0x80) != 0);
  }
}
