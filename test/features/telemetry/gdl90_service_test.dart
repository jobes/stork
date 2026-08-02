import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/data/gdl90_decoder.dart';
import 'package:stork/features/telemetry/data/gdl90_service.dart';
import 'package:stork/features/telemetry/domain/models/gdl90_target.dart';

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

/// Builds a valid framed GDL90 Traffic Report (msg ID 0x14) datagram.
Uint8List buildTrafficFrame({
  int icao = 0x484000,
  String callsign = 'OKSIA',
  int emitterCategory = 7,
}) {
  final payload = List<int>.filled(28, 0);
  payload[0] = 0x14; // Traffic Report
  // Bytes [2..4]: 24-bit ICAO address
  payload[2] = (icao >> 16) & 0xFF;
  payload[3] = (icao >> 8) & 0xFF;
  payload[4] = icao & 0xFF;
  // Byte [18]: emitter category
  payload[18] = emitterCategory;
  // Bytes [19..26]: callsign (space padded)
  for (var i = 0; i < callsign.length && i < 8; i++) {
    payload[19 + i] = callsign.codeUnitAt(i);
  }
  return createFrame(payload);
}

/// Builds a valid framed GDL90 Heartbeat (msg ID 0x00) datagram with the GPS
/// position-valid bit set.
Uint8List buildHeartbeatFrame() {
  final payload = <int>[0x00, 0x80, 0x00, 0x00, 0x00];
  return createFrame(payload);
}

/// Builds a valid framed GDL90 Ownship Report (msg ID 0x0A) datagram. The own
/// aircraft must never appear as a traffic target on the map.
Uint8List buildOwnshipFrame() {
  final payload = List<int>.filled(28, 0);
  payload[0] = 0x0A; // Ownship Report
  return createFrame(payload);
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

  group('Gdl90Service - Datagram processing', () {
    late Gdl90Service service;

    setUp(() {
      service = Gdl90Service();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('valid traffic report datagram adds a target', () {
      service.handleDatagram(buildTrafficFrame());

      expect(service.targets, hasLength(1));
      final target = service.targets.first;
      expect(target.id, equals('484000'));
      expect(target.callsign, equals('OKSIA'));
      expect(target.emitterCategory, equals(7));
    });

    test('heartbeat datagram marks the receiver active', () {
      expect(service.isHeartbeatActive, isFalse);

      service.handleDatagram(buildHeartbeatFrame());

      expect(service.lastHeartbeatTime, isNotNull);
      expect(service.isHeartbeatActive, isTrue);
    });

    test('heartbeat datagram does not add traffic targets', () {
      service.handleDatagram(buildHeartbeatFrame());

      expect(service.targets, isEmpty);
    });

    test('ownship report does not add a traffic target', () {
      service.handleDatagram(buildOwnshipFrame());

      // The own aircraft must never be tracked as traffic, but the datagram
      // still proves the receiver is alive.
      expect(service.targets, isEmpty);
      expect(service.lastHeartbeatTime, isNotNull);
    });

    test('datagram with corrupted FCS is ignored', () {
      final corrupted = Uint8List.fromList(buildTrafficFrame());
      // Corrupt an ICAO payload byte so the FCS no longer matches.
      corrupted[5] = corrupted[5] ^ 0xFF;

      service.handleDatagram(corrupted);

      expect(service.targets, isEmpty);
      expect(service.lastHeartbeatTime, isNull);
    });

    test(
      'target stream emits the full target list after a traffic report',
      () async {
        final emitted = <List<Gdl90Target>>[];
        final sub = service.targetStream.listen(emitted.add);

        service.handleDatagram(buildTrafficFrame());
        await Future<void>.delayed(Duration.zero);

        expect(emitted, isNotEmpty);
        expect(emitted.last, hasLength(1));
        expect(emitted.last.first.id, equals('484000'));

        await sub.cancel();
      },
    );

    test('dispose closes the target stream', () async {
      final done = Completer<void>();
      service.targetStream.listen(null, onDone: done.complete);

      await service.dispose();

      expect(done.isCompleted, isTrue);
    });
  });

  group('Gdl90Service - injectable clock', () {
    test('isHeartbeatActive decays after the 10s active window', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final service = Gdl90Service(now: () => now);
      addTearDown(service.dispose);

      service.handleDatagram(buildHeartbeatFrame());
      expect(service.isHeartbeatActive, isTrue);

      now = now.add(const Duration(seconds: 11));
      expect(service.isHeartbeatActive, isFalse);
    });

    test('targets are purged once they pass the expiry timeout', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final service = Gdl90Service(now: () => now);
      addTearDown(service.dispose);

      service.handleDatagram(buildTrafficFrame());
      expect(service.targets, hasLength(1));

      // Still within the default 60s expiry.
      now = now.add(const Duration(seconds: 59));
      service.purgeExpiredTargets();
      expect(service.targets, hasLength(1));

      // Past the expiry — the periodic timer uses the same purge path.
      now = now.add(const Duration(seconds: 2));
      service.purgeExpiredTargets();
      expect(service.targets, isEmpty);
    });

    test('expiry purge emits an updated target list', () async {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final service = Gdl90Service(now: () => now);
      addTearDown(service.dispose);

      final emitted = <List<Gdl90Target>>[];
      final sub = service.targetStream.listen(emitted.add);

      service.handleDatagram(buildTrafficFrame());
      await Future<void>.delayed(Duration.zero);
      expect(emitted, isNotEmpty);

      now = now.add(const Duration(seconds: 61));
      service.purgeExpiredTargets();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, isEmpty);

      await sub.cancel();
    });
  });
}
