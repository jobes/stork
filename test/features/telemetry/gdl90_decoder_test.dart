import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/data/gdl90_decoder.dart';

Uint8List createFrame(List<int> unescapedPayload) {
  final fcs = Gdl90Decoder.calculateFcsGdl90(
    unescapedPayload,
    0,
    unescapedPayload.length,
  );
  final fullUnescaped = [...unescapedPayload, fcs & 0xFF, (fcs >> 8) & 0xFF];

  final List<int> framed = [Gdl90Decoder.flagByte];
  for (final b in fullUnescaped) {
    if (b == Gdl90Decoder.flagByte) {
      framed.add(Gdl90Decoder.escapeByte);
      framed.add(0x5E);
    } else if (b == Gdl90Decoder.escapeByte) {
      framed.add(Gdl90Decoder.escapeByte);
      framed.add(0x5D);
    } else {
      framed.add(b);
    }
  }
  framed.add(Gdl90Decoder.flagByte);

  return Uint8List.fromList(framed);
}

void main() {
  group('Gdl90Decoder - FCS & Byte Unstuffing', () {
    test('FCS calculation & validation', () {
      final data = [0x14, 0x81, 0x01, 0x00, 0x12, 0x34];
      final fcs = Gdl90Decoder.calculateFcsGdl90(data);

      final fullData = [...data, fcs & 0xFF, (fcs >> 8) & 0xFF];
      expect(Gdl90Decoder.validateFcs(fullData), isTrue);

      final corruptData = [...data, 0xFF, 0xFF];
      expect(Gdl90Decoder.validateFcs(corruptData), isFalse);
    });

    test('Byte unstuffing of 0x7E and 0x7D', () {
      final unescaped = [0x00, 0x81, 0x7E, 0x7D, 0x12, 0x34];
      final framed = createFrame(unescaped);

      final decoder = Gdl90Decoder();
      final messages = decoder.processBytes(framed);

      expect(messages, isNotEmpty);
      expect(messages.first, isA<Gdl90HeartbeatMessage>());
    });
  });

  group('Gdl90Decoder - Heartbeat (0x00)', () {
    test('Decodes valid Heartbeat message', () {
      final payload = [0x00, 0x81, 0x01, 0x00, 0x10, 0x00];
      final framed = createFrame(payload);

      final decoder = Gdl90Decoder();
      final messages = decoder.processBytes(framed);

      expect(messages.length, equals(1));
      expect(messages.first, isA<Gdl90HeartbeatMessage>());

      final hb = messages.first as Gdl90HeartbeatMessage;
      expect(hb.gpsPositionValid, isTrue);
      expect(hb.utcTimingValid, isTrue);
    });

    test('Decodes SafeSky GDL90 Heartbeat payload', () {
      // SafeSky Heartbeat packet: 0x7E + 0x00 0x81 0x80 0x2c 0x01 0x00 0x00 0x7c 0xc3 + 0x7E
      final bytes = Uint8List.fromList([
        0x7E,
        0x00,
        0x81,
        0x80,
        0x2C,
        0x01,
        0x00,
        0x00,
        0x7C,
        0xC3,
        0x7E,
      ]);

      final decoder = Gdl90Decoder();
      final messages = decoder.processBytes(bytes);

      expect(messages.length, equals(1));
      expect(messages.first, isA<Gdl90HeartbeatMessage>());

      final hb = messages.first as Gdl90HeartbeatMessage;
      expect(hb.gpsPositionValid, isTrue);
    });
  });

  group('Gdl90Decoder - Traffic Report (0x14)', () {
    test('Decodes valid Traffic Report message correctly', () {
      // 28 bytes payload for Traffic Report 0x14 (ID 0x14 + 27 data bytes)
      final payload = List<int>.filled(28, 0);
      payload[0] = 0x14; // Message ID 20
      payload[1] = 0x00; // Alert status 0, Addr type 0 (ADS-B ICAO)

      // ICAO Address: 0x484000 (3 bytes: 0x48, 0x40, 0x00) -> "484000"
      payload[2] = 0x48;
      payload[3] = 0x40;
      payload[4] = 0x00;

      // Latitude: 48.1500 deg -> rawLat = (48.15 * 8388608 / 180) = 2244386 = 0x223F22
      const latDeg = 48.15;
      final rawLat = (latDeg * 8388608.0 / 180.0).round();
      payload[5] = (rawLat >> 16) & 0xFF;
      payload[6] = (rawLat >> 8) & 0xFF;
      payload[7] = rawLat & 0xFF;

      // Longitude: 17.1000 deg -> rawLon = (17.10 * 8388608 / 180) = 796917 = 0x0C2975
      const lonDeg = 17.10;
      final rawLon = (lonDeg * 8388608.0 / 180.0).round();
      payload[8] = (rawLon >> 16) & 0xFF;
      payload[9] = (rawLon >> 8) & 0xFF;
      payload[10] = rawLon & 0xFF;

      // Altitude: 2500 ft -> rawAlt = (2500 + 1000) / 25 = 140 = 0x08C
      // Bytes 11, 12: ((rawAlt >> 4) & 0xFF), ((rawAlt & 0x0F) << 4)
      payload[11] = (140 >> 4) & 0xFF; // 0x08
      payload[12] = (140 & 0x0F) << 4; // 0xC0

      // Speed: 120 knots -> rawSpeed = 120 = 0x078
      // Bytes 14, 15: ((rawSpeed >> 4) & 0xFF), ((rawSpeed & 0x0F) << 4)
      payload[14] = (120 >> 4) & 0xFF; // 0x07
      payload[15] =
          (120 & 0x0F) <<
          4; // 0x80 — speed LSB in high nibble, VS MSB in low nibble

      // Vertical Speed: +500 fpm -> rawVs = 500 / 64 ≈ 8 = 0x008
      // VS LSB at byte 16 (MSB=0 already set in low nibble of byte 15 above)
      payload[16] = 0x08;

      // Track: 180 deg -> rawTrack = 180 * 256 / 360 = 128 = 0x80
      payload[17] = 128;

      // Emitter Category: 8 (Glider) — SafeSky format (byte 19)
      // Standard GDL90 would use byte 18.
      payload[19] = 8;

      // Callsign: "OK-1234 " (8 bytes: indices 20..27) — SafeSky format
      // Standard GDL90 would use bytes 19..26.
      final csBytes = 'OK-1234 '.codeUnits;
      for (int i = 0; i < 8; i++) {
        payload[20 + i] = csBytes[i];
      }

      final framed = createFrame(payload);

      final decoder = Gdl90Decoder();
      final messages = decoder.processBytes(framed);

      expect(messages.length, equals(1));
      expect(messages.first, isA<Gdl90TrafficMessage>());

      final msg = messages.first as Gdl90TrafficMessage;
      final target = msg.target;

      expect(target.id, equals('484000'));
      expect(target.callsign, equals('OK-1234'));
      expect(target.latitude, closeTo(48.15, 0.001));
      expect(target.longitude, closeTo(17.10, 0.001));
      expect(target.altitudeFeet, closeTo(2500.0, 1.0));
      expect(target.speedKnots, closeTo(120.0, 1.0));
      expect(target.trackDegrees, closeTo(180.0, 1.0));
      expect(target.verticalSpeedFpm, closeTo(512.0, 64.0)); // 8 * 64
      expect(target.emitterCategory, equals(8));
    });
  });
}
