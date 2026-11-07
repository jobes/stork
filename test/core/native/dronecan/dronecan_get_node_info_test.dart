import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/vhf_radio_control.dart'
    show BitWriter;

void main() {
  group('GetNodeInfoResponse', () {
    final validUniqueId = Uint8List.fromList(List.generate(16, (i) => i + 1));
    final invalidUniqueIdTooShort = Uint8List.fromList(
      List.generate(15, (i) => i + 1),
    );
    final invalidUniqueIdTooLong = Uint8List.fromList(
      List.generate(17, (i) => i + 1),
    );

    test('Constructing and serializing with valid 16-byte uniqueId works', () {
      final response = GetNodeInfoResponse(
        status: NodeStatus(
          uptimeSec: 100,
          health: NodeHealth.ok,
          mode: NodeMode.operational,
        ),
        swMajor: 1,
        swMinor: 2,
        uniqueId: validUniqueId,
        name: Uint8List.fromList(utf8.encode('test.node')),
      );

      expect(response.uniqueId.length, equals(16));
      final payload = response.toPayload();
      expect(payload, isNotNull);
      expect(payload.isNotEmpty, isTrue);
    });

    test('Constructing with invalid uniqueId length throws ArgumentError', () {
      expect(
        () => GetNodeInfoResponse(
          status: NodeStatus(
            uptimeSec: 100,
            health: NodeHealth.ok,
            mode: NodeMode.operational,
          ),
          swMajor: 1,
          swMinor: 2,
          uniqueId: invalidUniqueIdTooShort,
          name: Uint8List.fromList(utf8.encode('test.node')),
        ),
        throwsArgumentError,
      );

      expect(
        () => GetNodeInfoResponse(
          status: NodeStatus(
            uptimeSec: 100,
            health: NodeHealth.ok,
            mode: NodeMode.operational,
          ),
          swMajor: 1,
          swMinor: 2,
          uniqueId: invalidUniqueIdTooLong,
          name: Uint8List.fromList(utf8.encode('test.node')),
        ),
        throwsArgumentError,
      );
    });

    test(
      'Async factory create works with valid uniqueId and fails with invalid length',
      () async {
        final response = await GetNodeInfoResponse.create(validUniqueId);
        expect(response.uniqueId, equals(validUniqueId));

        await expectLater(
          GetNodeInfoResponse.create(invalidUniqueIdTooShort),
          throwsArgumentError,
        );
      },
    );

    test('fromPayload decodes a serialized response', () {
      final response = GetNodeInfoResponse(
        status: NodeStatus(
          uptimeSec: 12345,
          health: NodeHealth.warning,
          mode: NodeMode.maintenance,
        ),
        swMajor: 3,
        swMinor: 7,
        uniqueId: validUniqueId,
        name: Uint8List.fromList(utf8.encode('com.example.instrument')),
      );

      final decoded = GetNodeInfoResponse.fromPayload(response.toPayload());

      expect(decoded.status.uptimeSec, equals(12345));
      expect(decoded.status.health, equals(NodeHealth.warning));
      expect(decoded.status.mode, equals(NodeMode.maintenance));
      expect(decoded.swMajor, equals(3));
      expect(decoded.swMinor, equals(7));
      expect(decoded.uniqueId, equals(validUniqueId));
      expect(utf8.decode(decoded.name), equals('com.example.instrument'));
    });

    test('fromPayload decodes software, hardware and certificate details', () {
      final certificate = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
      final response = GetNodeInfoResponse(
        status: NodeStatus(
          uptimeSec: 5,
          health: NodeHealth.ok,
          mode: NodeMode.operational,
        ),
        swMajor: 2,
        swMinor: 9,
        optionalFieldFlags: 0x05,
        vcsCommit: 0xDEADBEEF,
        imageCrc: BigInt.parse('F123456789ABCDEF', radix: 16),
        hwMajor: 3,
        hwMinor: 4,
        uniqueId: validUniqueId,
        name: Uint8List.fromList(utf8.encode('node.with.cert')),
        certificateOfAuthenticity: certificate,
      );

      final decoded = GetNodeInfoResponse.fromPayload(response.toPayload());

      expect(decoded.optionalFieldFlags, equals(0x05));
      expect(decoded.vcsCommit, equals(0xDEADBEEF));
      expect(
        decoded.imageCrc,
        equals(BigInt.parse('F123456789ABCDEF', radix: 16)),
      );
      expect(decoded.hwMajor, equals(3));
      expect(decoded.hwMinor, equals(4));
      expect(decoded.certificateOfAuthenticity, equals(certificate));
      // The name offset depends on the certificate length.
      expect(utf8.decode(decoded.name), equals('node.with.cert'));
    });

    test('fromPayload rejects a truncated payload', () {
      expect(
        () => GetNodeInfoResponse.fromPayload(Uint8List(10)),
        throwsFormatException,
      );
    });

    test('fromPayload rejects a payload with an oversized name', () {
      final response = GetNodeInfoResponse(
        status: NodeStatus(
          uptimeSec: 1,
          health: NodeHealth.ok,
          mode: NodeMode.operational,
        ),
        swMajor: 1,
        swMinor: 0,
        uniqueId: validUniqueId,
        name: Uint8List.fromList(utf8.encode('node')),
      );
      final payload = response.toPayload();

      // TAO payload with 81 name bytes exceeds the 80-byte DroneCAN limit.
      expect(
        () => GetNodeInfoResponse.fromPayload(
          Uint8List.fromList([...payload, ...List.filled(81, 0x41)]),
        ),
        throwsFormatException,
      );
    });

    test('fromPayload decodes a non-TAO payload with a 7-bit length', () {
      final name = utf8.encode('com.example.instrument');
      final writer = BitWriter();

      final header = Uint8List(41);
      final headerData = ByteData.sublistView(header);
      headerData.setUint32(0, 777, Endian.little); // uptime
      headerData.setUint8(
        4,
        0x80,
      ); // health = error (bits 7-6), mode = operational
      headerData.setUint8(7, 4); // sw major
      headerData.setUint8(8, 2); // sw minor
      header.setRange(24, 40, validUniqueId); // unique_id
      for (final byte in header) {
        writer.writeBits(byte, 8);
      }

      writer.writeBits(name.length, 7);
      for (final byte in name) {
        writer.writeBits(byte, 8);
      }

      final decoded = GetNodeInfoResponse.fromPayload(writer.toBytes());

      expect(decoded.status.uptimeSec, equals(777));
      expect(decoded.status.health, equals(NodeHealth.error));
      expect(decoded.status.mode, equals(NodeMode.operational));
      expect(decoded.swMajor, equals(4));
      expect(decoded.swMinor, equals(2));
      expect(decoded.uniqueId, equals(validUniqueId));
      expect(utf8.decode(decoded.name), equals('com.example.instrument'));
    });

    test('fromPayload prefers TAO when the length check is ambiguous', () {
      // A 50-byte name starting with 'c' makes the first byte of the TAO name
      // (0x63 >> 1 == 49) match the non-TAO length check (50 - 1).
      final name = utf8.encode('c${'o' * 49}');
      final response = GetNodeInfoResponse(
        status: NodeStatus(
          uptimeSec: 1,
          health: NodeHealth.ok,
          mode: NodeMode.operational,
        ),
        swMajor: 1,
        swMinor: 0,
        uniqueId: validUniqueId,
        name: Uint8List.fromList(name),
      );

      final decoded = GetNodeInfoResponse.fromPayload(response.toPayload());

      expect(decoded.name, equals(name));
    });
  });
}
