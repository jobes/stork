import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/bit_writer.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/tail_array.dart';

void main() {
  group('GetTransportStats', () {
    test('request has an empty payload', () {
      expect(GetTransportStats().toPayload(), isEmpty);
    });

    test('decodes transfer statistics and TAO interface array', () {
      final payload = Uint8List(18 + 2 * CanIfaceStats.payloadSize);
      final data = ByteData.sublistView(payload);

      void putUint48(int offset, int value) {
        data.setUint32(offset, value & 0xFFFFFFFF, Endian.little);
        data.setUint16(offset + 4, (value >> 32) & 0xFFFF, Endian.little);
      }

      putUint48(0, 100); // transfers_tx
      putUint48(6, 200); // transfers_rx
      putUint48(12, 3); // transfer_errors

      // Interface 0
      putUint48(18, 1000);
      putUint48(24, 2000);
      putUint48(30, 1);
      // Interface 1
      putUint48(36, 3000);
      putUint48(42, 4000);
      putUint48(48, 2);

      final stats = GetTransportStatsResponse.fromPayload(payload);

      expect(stats.transfersTx, equals(100));
      expect(stats.transfersRx, equals(200));
      expect(stats.transferErrors, equals(3));
      expect(stats.canIfaceStats, hasLength(2));
      expect(stats.canIfaceStats[0].framesTx, equals(1000));
      expect(stats.canIfaceStats[0].framesRx, equals(2000));
      expect(stats.canIfaceStats[0].errors, equals(1));
      expect(stats.canIfaceStats[1].framesTx, equals(3000));
      expect(stats.canIfaceStats[1].framesRx, equals(4000));
      expect(stats.canIfaceStats[1].errors, equals(2));
    });

    test('decodes a length-prefixed interface array', () {
      // `CANIfaceStats[<=3]` is prefixed with a 2-bit length, so the records
      // are not byte aligned.
      final header = Uint8List(18);
      final headerData = ByteData.sublistView(header);

      void putHeaderUint48(int offset, int value) {
        headerData.setUint32(offset, value & 0xFFFFFFFF, Endian.little);
        headerData.setUint16(offset + 4, (value >> 32) & 0xFFFF, Endian.little);
      }

      putHeaderUint48(0, 1); // transfers_tx
      putHeaderUint48(6, 2); // transfers_rx
      putHeaderUint48(12, 0); // transfer_errors

      final trailing = BitWriter(Uint8List(1 + 3 * CanIfaceStats.payloadSize));
      trailing.writeUint(1, lengthPrefixBits(3)); // array length
      trailing.writeUint(7, 48);
      trailing.writeUint(8, 48);
      trailing.writeUint(9, 48);

      final payload = Uint8List.fromList([...header, ...trailing.toPayload()]);

      final stats = GetTransportStatsResponse.fromPayload(payload);

      expect(stats.canIfaceStats, hasLength(1));
      expect(stats.canIfaceStats.single.framesTx, equals(7));
      expect(stats.canIfaceStats.single.framesRx, equals(8));
      expect(stats.canIfaceStats.single.errors, equals(9));
    });

    test('rejects more interfaces than the protocol allows', () {
      final payload = Uint8List(18 + 4 * CanIfaceStats.payloadSize);

      expect(
        () => GetTransportStatsResponse.fromPayload(payload),
        throwsFormatException,
      );
    });

    test('decodes an empty interface array', () {
      final stats = GetTransportStatsResponse.fromPayload(Uint8List(18));

      expect(stats.transfersTx, equals(0));
      expect(stats.canIfaceStats, isEmpty);
    });

    test('rejects a truncated payload', () {
      expect(
        () => GetTransportStatsResponse.fromPayload(Uint8List(10)),
        throwsFormatException,
      );
    });
  });
}
