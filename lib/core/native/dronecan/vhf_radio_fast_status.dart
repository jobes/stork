import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

/// Parsed representation of stork.equipment.vhf_radio.FastStatus (ID 20122).
///
/// DSDL bit layout (little-endian, LSB first per UAVCAN v0 encoding):
///   uint2 radio_instance         # 0 = COM1, 1 = COM2...
///   uint8 flags                  # Bitmask of active flags
class VhfRadioFastStatus implements DroneCanMessage {
  static const int messageId = 20122;
  static const int messageSignature = 0x5C070F2D19DBC8F1;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  // Flag constants
  static const int flagTx = 1;
  static const int flagRx = 2;
  static const int flagDualActive = 4;
  static const int flagGeneralError = 8;

  final int radioInstance;
  final int flags;

  const VhfRadioFastStatus({required this.radioInstance, required this.flags});

  bool get isTxActive => (flags & flagTx) != 0;
  bool get isRxActive => (flags & flagRx) != 0;
  bool get isDualActive => (flags & flagDualActive) != 0;
  bool get hasGeneralError => (flags & flagGeneralError) != 0;

  factory VhfRadioFastStatus.fromPayload(Uint8List payload) {
    if (payload.length < 2) {
      throw FormatException(
        'Payload too short for VhfRadioFastStatus message (got ${payload.length} bytes, expected at least 2)',
      );
    }

    final reader = BitReader(payload);

    final radioInstance = reader.readUint(2);
    final flags = reader.readUint(8);

    return VhfRadioFastStatus(radioInstance: radioInstance, flags: flags);
  }

  @override
  String toString() {
    return 'VhfRadioFastStatus(instance: $radioInstance, flags: $flags)';
  }
}
