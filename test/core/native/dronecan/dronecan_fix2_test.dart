import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/fix2.dart';

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

  void writeUint(int value, int bitCount) => writeBits(value, bitCount);
  void writeInt(int value, int bitCount) => writeBits(value, bitCount);

  void writeFloat32(double value) {
    final buffer = Uint8List(4);
    final byteData = ByteData.sublistView(buffer);
    byteData.setFloat32(0, value, Endian.little);
    final bits = byteData.getUint32(0, Endian.little);
    writeUint(bits, 32);
  }

  void writeFloat16(double value) {
    int bits = 0;
    if (value == 0.0) {
      bits = 0;
    } else if (value.isInfinite) {
      bits = 0x7C00 | (value.isNegative ? 0x8000 : 0);
    } else if (value.isNaN) {
      bits = 0x7C00 | 0x0200;
    } else {
      final sign = value.isNegative ? 0x8000 : 0;
      final absVal = value.abs();
      int exponent = (math.log(absVal) / math.ln2).floor() + 15;
      if (exponent >= 31) {
        bits = sign | 0x7C00;
      } else if (exponent <= 0) {
        final fraction = (absVal / math.pow(2, -14) * 1024.0).round();
        bits = sign | fraction;
      } else {
        final fraction = ((absVal / math.pow(2, exponent - 15) - 1.0) * 1024.0)
            .round();
        bits = sign | ((exponent & 0x1F) << 10) | (fraction & 0x03FF);
      }
    }
    writeUint(bits, 16);
  }

  Uint8List toBytes() {
    final numBytes = (_bits.length + 7) ~/ 8;
    final bytes = Uint8List(numBytes);
    for (int i = 0; i < _bits.length; i++) {
      final byteIndex = i ~/ 8;
      final bitInByte = 7 - (i % 8);
      bytes[byteIndex] |= (_bits[i] << bitInByte);
    }
    return bytes;
  }
}

void main() {
  group('DroneCAN Fix2 Parser Tests', () {
    Uint8List generateFix2Payload({
      int timestamp = 123456789,
      int gnssTimestamp = 987654321,
      int gnssTimeStandard = 1,
      int numLeapSeconds = 18,
      double latitude = 37.7749,
      double longitude = -122.4194,
      double altitudeMsl = 100.0,
      double velN = 5.0,
      double velE = 12.0,
      double velD = -0.5,
      int satellites = 12,
      int status = 3,
      int mode = 0,
      int subMode = 0,
      List<double> covariance = const [],
      double pdop = 1.5,
    }) {
      final writer = BitWriter();
      writer.writeUint(timestamp, 56);
      writer.writeUint(gnssTimestamp, 56);
      writer.writeUint(gnssTimeStandard, 3);
      writer.writeUint(0, 13); // padding
      writer.writeUint(numLeapSeconds, 8);

      writer.writeInt((longitude * 1e8).round(), 37);
      writer.writeInt((latitude * 1e8).round(), 37);

      writer.writeInt(120000, 27); // heightEllipsoidMm (unused)
      writer.writeInt((altitudeMsl * 1000).round(), 27); // heightMslMm

      writer.writeFloat32(velN);
      writer.writeFloat32(velE);
      writer.writeFloat32(velD);

      writer.writeUint(satellites, 6);
      writer.writeUint(status, 2);

      writer.writeUint(mode, 4);
      writer.writeUint(subMode, 6);

      writer.writeUint(covariance.length, 6);
      for (final val in covariance) {
        writer.writeFloat16(val);
      }

      writer.writeFloat16(pdop);

      return writer.toBytes();
    }

    test('Throws FormatException if payload is less than 50 bytes', () {
      final fullPayload = generateFix2Payload(
        mode: 2,
        subMode: 1,
        covariance: [],
      );
      expect(fullPayload.length, equals(50));

      // 49 bytes should still throw
      final payload49 = fullPayload.sublist(0, 49);
      expect(payload49.length, equals(49));

      expect(
        () => Fix2.fromPayload(payload49),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Payload too short for Fix2 GNSS message'),
          ),
        ),
      );
    });

    test(
      'Parses empty covariance correctly (covLen = 0) with mode and subMode',
      () {
        final payload = generateFix2Payload(
          latitude: 45.12345,
          longitude: -75.54321,
          altitudeMsl: 250.5,
          mode: 2,
          subMode: 1,
          covariance: [],
          pdop: 1.5,
        );

        expect(payload.length, equals(50));

        final fix2 = Fix2.fromPayload(payload);

        expect(fix2.latitude, closeTo(45.12345, 1e-6));
        expect(fix2.longitude, closeTo(-75.54321, 1e-6));
        expect(fix2.altitude, closeTo(250.5, 0.1));
        expect(fix2.groundSpeed, closeTo(13.0, 0.01)); // sqrt(5*5 + 12*12) = 13
        expect(fix2.satellites, equals(12));
        expect(fix2.status, equals(3));
        expect(fix2.pdop, closeTo(1.5, 0.01));
        expect(fix2.mode, equals(2));
        expect(fix2.subMode, equals(1));

        expect(fix2.positionCovariance, isEmpty);
        expect(fix2.velocityCovariance, isEmpty);
        expect(fix2.horizontalAccuracy, isNull);
        expect(fix2.verticalAccuracy, isNull);
      },
    );

    test('Parses covLen = 1 covariance correctly and calculates EPH/EPV', () {
      final payload = generateFix2Payload(
        mode: 1,
        subMode: 0,
        covariance: [0.08],
        pdop: 1.5,
      );
      final fix2 = Fix2.fromPayload(payload);

      expect(fix2.mode, equals(1));
      expect(fix2.subMode, equals(0));
      expect(fix2.positionCovariance, equals([closeTo(0.08, 0.001)]));
      expect(fix2.velocityCovariance, isEmpty);

      // horAcc = sqrt(variance * 2) = sqrt(0.16) = 0.4
      expect(fix2.horizontalAccuracy, closeTo(0.4, 0.001));
      // vertAcc = sqrt(variance) = sqrt(0.08) = 0.28284
      expect(fix2.verticalAccuracy, closeTo(math.sqrt(0.08), 0.001));
    });

    test('Parses covLen = 3 covariance correctly and calculates EPH/EPV', () {
      final payload = generateFix2Payload(
        mode: 2,
        subMode: 0,
        covariance: [0.09, 0.16, 0.25],
        pdop: 1.5,
      );
      final fix2 = Fix2.fromPayload(payload);

      expect(fix2.mode, equals(2));
      expect(fix2.subMode, equals(0));
      expect(
        fix2.positionCovariance,
        equals([
          closeTo(0.09, 0.001),
          closeTo(0.16, 0.001),
          closeTo(0.25, 0.001),
        ]),
      );
      expect(fix2.velocityCovariance, isEmpty);

      // horAcc = sqrt(varN + varE) = sqrt(0.09 + 0.16) = 0.5
      expect(fix2.horizontalAccuracy, closeTo(0.5, 0.001));
      // vertAcc = sqrt(varD) = sqrt(0.25) = 0.5
      expect(fix2.verticalAccuracy, closeTo(0.5, 0.001));
    });

    test('Parses covLen = 6 covariance correctly and calculates EPH/EPV', () {
      final payload = generateFix2Payload(
        mode: 3,
        subMode: 5,
        covariance: [0.09, 9.99, 9.99, 0.16, 9.99, 0.25],
        pdop: 1.5,
      );
      final fix2 = Fix2.fromPayload(payload);

      expect(fix2.mode, equals(3));
      expect(fix2.subMode, equals(5));
      expect(fix2.positionCovariance.length, equals(6));
      expect(fix2.velocityCovariance, isEmpty);

      // horAcc = sqrt(posCov[0] + posCov[3]) = sqrt(0.09 + 0.16) = 0.5
      expect(fix2.horizontalAccuracy, closeTo(0.5, 0.001));
      // vertAcc = sqrt(posCov[5]) = sqrt(0.25) = 0.5
      expect(fix2.verticalAccuracy, closeTo(0.5, 0.001));
    });

    test(
      'Parses covLen = 18 covariance correctly, splits pos/vel, and calculates EPH/EPV',
      () {
        final payload = generateFix2Payload(
          mode: 2,
          subMode: 1,
          covariance: [
            // First 9 elements: position covariance
            0.09, // index 0 (varN)
            9.99, // index 1
            9.99, // index 2
            9.99, // index 3
            0.16, // index 4 (varE)
            9.99, // index 5
            1.0, // index 6
            2.0, // index 7
            0.25, // index 8 (varD)
            // Next 9 elements: velocity covariance
            4.0, // index 9
            5.0, // index 10
            6.0, // index 11
            7.0, // index 12
            8.0, // index 13
            9.0, // index 14
            10.0, // index 15
            11.0, // index 16
            12.0, // index 17
          ],
          pdop: 1.5,
        );
        final fix2 = Fix2.fromPayload(payload);

        expect(fix2.mode, equals(2));
        expect(fix2.subMode, equals(1));
        expect(fix2.positionCovariance.length, equals(9));
        expect(fix2.velocityCovariance.length, equals(9));

        expect(fix2.positionCovariance[0], closeTo(0.09, 0.001));
        expect(fix2.positionCovariance[4], closeTo(0.16, 0.001));
        expect(fix2.positionCovariance[8], closeTo(0.25, 0.001));

        expect(fix2.velocityCovariance[0], closeTo(4.0, 0.001));
        expect(fix2.velocityCovariance[8], closeTo(12.0, 0.001));

        // horAcc = sqrt(posCov[0] + posCov[4]) = 0.5
        expect(fix2.horizontalAccuracy, closeTo(0.5, 0.001));
        // vertAcc = sqrt(posCov[8]) = 0.5
        expect(fix2.verticalAccuracy, closeTo(0.5, 0.001));
      },
    );

    group('hasValidFix', () {
      test('is true for a 3D fix with satellites and non-zero position', () {
        final fix2 = Fix2.fromPayload(
          generateFix2Payload(status: 3, satellites: 10),
        );
        expect(fix2.hasValidFix, isTrue);
      });

      test('is true for a 2D fix with satellites and non-zero position', () {
        final fix2 = Fix2.fromPayload(
          generateFix2Payload(status: 2, satellites: 6),
        );
        expect(fix2.hasValidFix, isTrue);
      });

      test('is false when status is NO_FIX (0)', () {
        final fix2 = Fix2.fromPayload(
          generateFix2Payload(status: 0, satellites: 0),
        );
        expect(fix2.hasValidFix, isFalse);
      });

      test('is false when status is TIME_ONLY (1)', () {
        final fix2 = Fix2.fromPayload(
          generateFix2Payload(status: 1, satellites: 0),
        );
        expect(fix2.hasValidFix, isFalse);
      });

      test('is false when there are no satellites', () {
        final fix2 = Fix2.fromPayload(
          generateFix2Payload(status: 3, satellites: 0),
        );
        expect(fix2.hasValidFix, isFalse);
      });

      test('is false when position is 0,0', () {
        final fix2 = Fix2.fromPayload(
          generateFix2Payload(
            status: 3,
            satellites: 8,
            latitude: 0.0,
            longitude: 0.0,
          ),
        );
        expect(fix2.hasValidFix, isFalse);
      });
    });
  });
}
