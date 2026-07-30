import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/data/gdl90_decoder.dart';
import 'package:stork/features/telemetry/data/gdl90_service.dart';

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
  group('Gdl90Service - Heartbeat tracking', () {
    late Gdl90Service service;

    setUp(() {
      service = Gdl90Service();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('isHeartbeatActive returns false initially', () {
      expect(service.lastHeartbeatTime, isNull);
      expect(service.isHeartbeatActive, isFalse);
    });
  });
}
