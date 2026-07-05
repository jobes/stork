import 'dart:convert';
import 'dart:typed_data';
import 'dronecan_message.dart';

class BitWriter {
  final List<int> _bits = [];

  void writeBits(int value, int bitCount) {
    final lastByteIdx = bitCount ~/ 8;
    final rem = bitCount % 8;

    for (int i = 0; i < bitCount; i++) {
      final fByteIdx = i ~/ 8;
      final fBitInByteIdx = i % 8;
      final fBitsInThisByte = (fByteIdx == lastByteIdx) && (rem != 0) ? rem : 8;
      final destBitPos = 8 * fByteIdx + (fBitsInThisByte - 1 - fBitInByteIdx);
      final bitVal = (value >> destBitPos) & 1;
      _bits.add(bitVal);
    }
  }

  Uint8List toBytes() {
    final numBytes = (_bits.length + 7) ~/ 8;
    final bytes = Uint8List(numBytes);
    for (int i = 0; i < _bits.length; i++) {
      final byteIndex = i ~/ 8;
      final bitInByte = 7 - (i % 8);
      if (_bits[i] == 1) {
        bytes[byteIndex] |= (1 << bitInByte);
      }
    }
    return bytes;
  }
}

class VhfRadioControlRequest implements DroneCanRequestResponseMessage {
  static const int messageId = 221;
  static const int messageSignature = 0xB15B04E1F5473B6C;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  // Actions
  static const int actionFlip = 1;
  static const int actionDualToggle = 2;
  static const int actionPttOn = 3;
  static const int actionPttOff = 4;
  static const int actionSetStandbyFreq = 5;
  static const int actionSetActiveFreq = 6;
  static const int actionSetVolume = 7;
  static const int actionSetSquelch = 8;
  static const int actionSetVox = 9;
  static const int actionSetIntercom = 10;
  static const int actionSetMicGain = 11;

  final int radioInstance;
  final int action;
  final int level;
  final int index;
  final int frequencyKhz;
  final String frequencyName;

  const VhfRadioControlRequest({
    required this.radioInstance,
    required this.action,
    this.level = 0,
    this.index = 0,
    this.frequencyKhz = 0,
    this.frequencyName = '',
  });

  @override
  Uint8List toPayload() {
    final writer = BitWriter();

    // 1. radio_instance: uint2
    writer.writeBits(radioInstance, 2);
    // 2. action: uint4
    writer.writeBits(action, 4);
    // 3. level: uint7
    writer.writeBits(level, 7);
    // 4. index: uint3
    writer.writeBits(index, 3);
    // 5. frequency_khz: uint18
    writer.writeBits(frequencyKhz, 18);

    // 6. frequency_name: uint8[<=20] (TAO - tail array optimization, no length prefix)
    final nameBytes = ascii.encode(frequencyName);
    final limit = nameBytes.length > 20 ? 20 : nameBytes.length;
    for (int i = 0; i < limit; i++) {
      writer.writeBits(nameBytes[i], 8);
    }

    return writer.toBytes();
  }
}

class VhfRadioControlResponse implements DroneCanMessage {
  static const int messageId = 221;
  static const int messageSignature = 0xB15B04E1F5473B6C;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  static const int statusOk = 0;
  static const int statusError = 1;

  final int status;

  const VhfRadioControlResponse({required this.status});

  factory VhfRadioControlResponse.fromPayload(Uint8List payload) {
    if (payload.isEmpty) {
      throw const FormatException(
        'Payload too short for VhfRadioControlResponse (got 0 bytes)',
      );
    }
    // status is uint8 at the beginning of payload (or just first byte)
    return VhfRadioControlResponse(status: payload[0]);
  }
}
