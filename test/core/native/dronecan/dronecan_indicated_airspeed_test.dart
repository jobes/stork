import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/indicated_airspeed.dart';

void main() {
  group('DroneCAN IndicatedAirspeed', () {
    test('fromPayload decodes normal IAS and variance values', () {
      // float16(10.0) = 0x4900, stored little-endian: [0x00, 0x49]
      // float16(2.5)  = 0x4100, stored little-endian: [0x00, 0x41]
      final payload = Uint8List.fromList([0x00, 0x49, 0x00, 0x41]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed, closeTo(10.0, 0.01));
      expect(msg.indicatedAirspeedVariance, closeTo(2.5, 0.01));
      expect(msg.id, equals(1021));
      expect(msg.signature, equals(0x0A1892D72AB8945F));
      expect(msg.isService, isFalse);
    });

    test(
      'fromPayload decodes documentation example (1.0 m/s, 0.0 variance)',
      () {
        // float16(1.0) = 0x3C00, stored little-endian: [0x00, 0x3C]
        // float16(0.0) = 0x0000, stored little-endian: [0x00, 0x00]
        final payload = Uint8List.fromList([0x00, 0x3C, 0x00, 0x00]);
        final msg = IndicatedAirspeed.fromPayload(payload);

        expect(msg.indicatedAirspeed, closeTo(1.0, 0.01));
        expect(msg.indicatedAirspeedVariance, closeTo(0.0, 0.01));
      },
    );

    test('fromPayload decodes zero payload', () {
      final payload = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed, closeTo(0.0, 0.01));
      expect(msg.indicatedAirspeedVariance, closeTo(0.0, 0.01));
    });

    test('fromPayload decodes negative IAS', () {
      // float16(-5.0) = 0xC500, stored little-endian: [0x00, 0xC5]
      // float16(1.0)  = 0x3C00, stored little-endian: [0x00, 0x3C]
      final payload = Uint8List.fromList([0x00, 0xC5, 0x00, 0x3C]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed, closeTo(-5.0, 0.01));
      expect(msg.indicatedAirspeedVariance, closeTo(1.0, 0.01));
    });

    test('fromPayload decodes max finite float16 value (65504.0)', () {
      // float16(65504.0) = 0x7BFF, stored little-endian: [0xFF, 0x7B]
      final payload = Uint8List.fromList([0xFF, 0x7B, 0x00, 0x00]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed, closeTo(65504.0, 0.5));
      expect(msg.indicatedAirspeedVariance, closeTo(0.0, 0.01));
    });

    test('fromPayload handles NaN IAS', () {
      // float16 NaN (exponent=0x1F, fraction≠0) = 0x7C01, LE: [0x01, 0x7C]
      // float16(1.0) = 0x3C00, LE: [0x00, 0x3C]
      final payload = Uint8List.fromList([0x01, 0x7C, 0x00, 0x3C]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed.isNaN, isTrue);
      expect(msg.indicatedAirspeedVariance, closeTo(1.0, 0.01));
    });

    test('fromPayload handles +Infinity variance', () {
      // float16(1.0)  = 0x3C00, LE: [0x00, 0x3C]
      // float16(+Inf) = 0x7C00, LE: [0x00, 0x7C]
      final payload = Uint8List.fromList([0x00, 0x3C, 0x00, 0x7C]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed, closeTo(1.0, 0.01));
      expect(msg.indicatedAirspeedVariance.isInfinite, isTrue);
      expect(msg.indicatedAirspeedVariance.isNegative, isFalse);
    });

    test('fromPayload handles -Infinity IAS', () {
      // float16(-Inf) = 0xFC00, LE: [0x00, 0xFC]
      // float16(0.0)  = 0x0000, LE: [0x00, 0x00]
      final payload = Uint8List.fromList([0x00, 0xFC, 0x00, 0x00]);
      final msg = IndicatedAirspeed.fromPayload(payload);

      expect(msg.indicatedAirspeed.isInfinite, isTrue);
      expect(msg.indicatedAirspeed.isNegative, isTrue);
      expect(msg.indicatedAirspeedVariance, closeTo(0.0, 0.01));
    });

    test('fromPayload throws FormatException for short payload (3 bytes)', () {
      final payload = Uint8List.fromList([0x00, 0x3C, 0x00]);
      expect(
        () => IndicatedAirspeed.fromPayload(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromPayload throws FormatException for empty payload', () {
      final payload = Uint8List.fromList([]);
      expect(
        () => IndicatedAirspeed.fromPayload(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('toString formats finite values correctly', () {
      final msg = IndicatedAirspeed(
        indicatedAirspeed: 10.0,
        indicatedAirspeedVariance: 2.5,
      );
      expect(
        msg.toString(),
        equals('IndicatedAirspeed(10.00 m/s, variance=2.50)'),
      );
    });

    test('toString handles NaN without crashing', () {
      final msg = IndicatedAirspeed(
        indicatedAirspeed: double.nan,
        indicatedAirspeedVariance: 1.0,
      );
      expect(msg.toString(), contains('NaN'));
    });

    test('toString handles Infinity without crashing', () {
      final msg = IndicatedAirspeed(
        indicatedAirspeed: double.infinity,
        indicatedAirspeedVariance: 0.0,
      );
      expect(msg.toString(), contains('Infinity'));
    });
  });
}
