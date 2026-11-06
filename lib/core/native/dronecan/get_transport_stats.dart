import 'dart:typed_data';

import 'bit_reader.dart';
import 'dronecan_message.dart';
import 'tail_array.dart';

/// `uavcan.protocol.GetTransportStats` request (empty payload).
class GetTransportStats implements DroneCanRequestResponseMessage {
  static const int messageId = 4;
  static const int messageSignature = 0xBE6F76A7EC312B04;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  @override
  Uint8List toPayload() => Uint8List(0);
}

/// Statistics of a single CAN interface (`uavcan.protocol.CANIfaceStats`).
class CanIfaceStats {
  const CanIfaceStats({
    required this.framesTx,
    required this.framesRx,
    required this.errors,
  });

  final int framesTx;
  final int framesRx;
  final int errors;

  /// Serialized size of one interface record in bytes (3 x uint48).
  static const int payloadSize = 18;
}

/// `uavcan.protocol.GetTransportStats` response.
class GetTransportStatsResponse implements DroneCanMessage {
  static const int messageId = GetTransportStats.messageId;
  static const int messageSignature = GetTransportStats.messageSignature;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final int transfersTx;
  final int transfersRx;
  final int transferErrors;
  final List<CanIfaceStats> canIfaceStats;

  const GetTransportStatsResponse({
    required this.transfersTx,
    required this.transfersRx,
    required this.transferErrors,
    required this.canIfaceStats,
  });

  /// Fixed part of the payload: 3 x uint48.
  static const int _fixedPayloadSize = 18;

  factory GetTransportStatsResponse.fromPayload(Uint8List payload) {
    if (payload.length < _fixedPayloadSize) {
      throw FormatException(
        'Payload too short for GetTransportStatsResponse: '
        '${payload.length} < $_fixedPayloadSize bytes',
      );
    }

    final reader = BitReader(payload);
    final transfersTx = reader.readUint(48);
    final transfersRx = reader.readUint(48);
    final transferErrors = reader.readUint(48);

    final ifaces = _decodeInterfaces(payload);

    return GetTransportStatsResponse(
      transfersTx: transfersTx,
      transfersRx: transfersRx,
      transferErrors: transferErrors,
      canIfaceStats: ifaces,
    );
  }

  /// `can_iface_stats` is the last field, so classic-CAN transfers use the
  /// tail-array optimization (no length prefix). A length-prefixed variant is
  /// handled as well for robustness.
  static List<CanIfaceStats> _decodeInterfaces(Uint8List payload) {
    var dataOffsetBits = _fixedPayloadSize * 8;
    final trailingBits = payload.length * 8 - dataOffsetBits;
    if (trailingBits <= 0) return const [];

    final int count;
    if (trailingBits % _interfaceBits == 0) {
      // Tail-array form: the remaining bits are the records.
      count = trailingBits ~/ _interfaceBits;
    } else {
      // Length-prefixed form: the count precedes the records.
      final prefixBits = lengthPrefixBits(_maxInterfaces);
      final reader = BitReader(payload)..skip(dataOffsetBits);
      final declared = reader.readUint(prefixBits);
      final dataBits = declared * _interfaceBits;
      if (dataBits > trailingBits - prefixBits ||
          trailingBits - prefixBits - dataBits >= 8) {
        throw FormatException(
          'Invalid GetTransportStatsResponse interface statistics: '
          '$trailingBits trailing bits',
        );
      }
      count = declared;
      dataOffsetBits += prefixBits;
    }

    if (count > _maxInterfaces) {
      throw FormatException(
        'GetTransportStatsResponse reports $count CAN interfaces, '
        'at most $_maxInterfaces are possible',
      );
    }

    final reader = BitReader(payload)..skip(dataOffsetBits);
    return List<CanIfaceStats>.generate(
      count,
      (_) => CanIfaceStats(
        framesTx: reader.readUint(48),
        framesRx: reader.readUint(48),
        errors: reader.readUint(48),
      ),
      growable: false,
    );
  }

  /// `CANIfaceStats[<=3]`.
  static const int _maxInterfaces = 3;

  /// Serialized size of one interface record in bits (3 x uint48).
  static const int _interfaceBits = CanIfaceStats.payloadSize * 8;
}
