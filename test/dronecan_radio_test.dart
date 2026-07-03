import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/vhf_radio_full_status.dart';
import 'package:stork/core/native/dronecan/vhf_radio_fast_status.dart';

void main() {
  group('DroneCAN VHF Radio parsing tests', () {
    test('FastStatus decoding test', () {
      // Let's construct a payload for FastStatus:
      // Field 1: uint2 radio_instance
      // Field 2: uint8 flags
      // Total bits: 10 bits -> 2 bytes (16 bits)
      // If payload is [0x40, 0xC0]:
      // bit 0: (0x40 >> 7) & 1 = 0
      // bit 1: (0x40 >> 6) & 1 = 1
      // -> radio_instance = 01 binary = 1.
      // bit 2: (0x40 >> 5) & 1 = 0
      // bit 3: (0x40 >> 4) & 1 = 0
      // bit 4: (0x40 >> 3) & 1 = 0
      // bit 5: (0x40 >> 2) & 1 = 0
      // bit 6: (0x40 >> 1) & 1 = 0
      // bit 7: (0x40 >> 0) & 1 = 0
      // bit 8: (0xC0 >> 7) & 1 = 1
      // bit 9: (0xC0 >> 6) & 1 = 1
      // -> flags read as 8 bits:
      //    i = 0 (bit 2): destBitPos = 7 -> bit 7 of flags = 0
      //    i = 1 (bit 3): destBitPos = 6 -> bit 6 of flags = 0
      //    i = 2 (bit 4): destBitPos = 5 -> bit 5 of flags = 0
      //    i = 3 (bit 5): destBitPos = 4 -> bit 4 of flags = 0
      //    i = 4 (bit 6): destBitPos = 3 -> bit 3 of flags = 0
      //    i = 5 (bit 7): destBitPos = 2 -> bit 2 of flags = 0
      //    i = 6 (bit 8): destBitPos = 1 -> bit 1 of flags = 1
      //    i = 7 (bit 9): destBitPos = 0 -> bit 0 of flags = 1
      //    -> flags = 3 (binary 00000011)
      final payload = Uint8List.fromList([0x40, 0xC0]);
      final msg = VhfRadioFastStatus.fromPayload(payload);

      expect(msg.radioInstance, equals(1));
      expect(msg.flags, equals(3));
      expect(msg.isTxActive, isTrue);
      expect(msg.isRxActive, isTrue);
      expect(msg.isDualActive, isFalse);
      expect(msg.hasGeneralError, isFalse);
    });

    test('FullStatus decoding test', () {
      final List<int> bits = [];

      void addUavcanBits(int value, int bitCount) {
        final bytesCount = (bitCount + 7) ~/ 8;
        final rem = bitCount % 8;
        for (int byteIdx = 0; byteIdx < bytesCount; byteIdx++) {
          final bitsInThisByte = (byteIdx == bytesCount - 1) && (rem != 0) ? rem : 8;
          final startBitOfByte = byteIdx * 8;
          for (int bitInByteIdx = bitsInThisByte - 1; bitInByteIdx >= 0; bitInByteIdx--) {
            final bitPos = startBitOfByte + bitInByteIdx;
            bits.add((value >> bitPos) & 1);
          }
        }
      }

      addUavcanBits(2, 2);      // radio_instance = 2
      addUavcanBits(118500, 18); // active_frequency_khz = 118.5 MHz
      addUavcanBits(121900, 18); // standby_frequency_khz = 121.9 MHz
      addUavcanBits(12, 8);      // flags = 12 (flagDualActive | flagGeneralError)
      addUavcanBits(80, 7);      // volume = 80
      addUavcanBits(50, 7);      // squelch = 50
      addUavcanBits(0, 7);       // vox = 0
      addUavcanBits(30, 7);      // intercom = 30

      // mic_gain: uint7[<=8]
      addUavcanBits(2, 4);       // len = 2
      addUavcanBits(90, 7);      // element 0 = 90
      addUavcanBits(85, 7);      // element 1 = 85

      // active_station_name: uint8[<=20]
      final activeName = "KOSH TWR";
      addUavcanBits(activeName.length, 5); // len = 8
      for (var code in activeName.codeUnits) {
        addUavcanBits(code, 8);
      }

      // standby_station_name: uint8[<=20] (TAO - no length prefix)
      final standbyName = "KLAX GND";
      for (var code in standbyName.codeUnits) {
        addUavcanBits(code, 8);
      }

      // Convert bits to bytes
      final numBytes = (bits.length + 7) ~/ 8;
      final payload = Uint8List(numBytes);
      for (int i = 0; i < bits.length; i++) {
        final byteIndex = i ~/ 8;
        final bitInByte = 7 - (i % 8);
        if (bits[i] == 1) {
          payload[byteIndex] |= (1 << bitInByte);
        }
      }

      final msg = VhfRadioFullStatus.fromPayload(payload);

      expect(msg.radioInstance, equals(2));
      expect(msg.activeFrequencyKhz, equals(118500));
      expect(msg.standbyFrequencyKhz, equals(121900));
      expect(msg.flags, equals(12));
      expect(msg.isTxActive, isFalse);
      expect(msg.isRxActive, isFalse);
      expect(msg.isDualActive, isTrue);
      expect(msg.hasGeneralError, isTrue);
      expect(msg.volume, equals(80));
      expect(msg.squelch, equals(50));
      expect(msg.vox, equals(0));
      expect(msg.intercom, equals(30));
      expect(msg.micGain, equals([90, 85]));
      expect(msg.activeStationName, equals("KOSH TWR"));
      expect(msg.standbyStationName, equals("KLAX GND"));
    });
  });
}
