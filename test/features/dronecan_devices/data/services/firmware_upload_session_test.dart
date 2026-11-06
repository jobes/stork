import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/features/dronecan_devices/data/services/firmware_upload_session.dart';
import '../../helpers/fake_dronecan_node_transport.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_failure.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_progress.dart';

void main() {
  group('FirmwareUploadSession', () {
    late FakeDroneCanNodeTransport transport;
    late List<int> image;

    setUp(() {
      transport = FakeDroneCanNodeTransport();
      image = List<int>.generate(300, (index) => index & 0xFF);
    });

    test('rejects an empty image', () {
      expect(
        () => FirmwareUploadSession(
          transport: transport,
          nodeId: 7,
          fileName: 'fw.bin',
          firmware: Uint8List(0),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reports preparing before the node asks for data', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList(image),
      );
      final progress = <FirmwareUpdateProgress>[];
      final subscription = session.start().listen(progress.add);

      await Future<void>.delayed(Duration.zero);
      expect(transport.beginFirmwareRequests, hasLength(1));
      expect(progress.single.phase, equals(FirmwareUpdatePhase.preparing));
      expect(progress.single.totalBytes, equals(300));

      await subscription.cancel();
    });

    test('serves full chunks and a short final chunk', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList(image),
      );
      final served = <int>[];
      final lengths = <int>[];
      final progress = <FirmwareUpdateProgress>[];
      session.start().listen(progress.add);
      await Future<void>.delayed(Duration.zero);

      var offset = 0;
      while (true) {
        final chunk = transport.fileReadHandler!(
          7,
          'fw.bin',
          offset,
          fileReadChunkSize,
        )!;
        lengths.add(chunk.length);
        served.addAll(chunk);
        if (chunk.length < fileReadChunkSize) break;
        offset += chunk.length;
      }

      // Progress events are delivered asynchronously.
      await Future<void>.delayed(Duration.zero);

      expect(served, equals(image));
      expect(lengths, equals([256, 44]));
      expect(progress.last.phase, equals(FirmwareUpdatePhase.completed));
      expect(progress.last.fraction, equals(1));
    });

    test('keeps serving during the grace period', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList([1, 2, 3]),
        gracePeriod: const Duration(milliseconds: 40),
      );
      final done = Completer<void>();
      session.start().listen((_) {}, onDone: done.complete);
      await Future<void>.delayed(Duration.zero);

      expect(
        transport.fileReadHandler!(7, 'fw.bin', 0, 256),
        equals([1, 2, 3]),
      );
      // A retry of the last chunk is still answered.
      expect(
        transport.fileReadHandler!(7, 'fw.bin', 0, 256),
        equals([1, 2, 3]),
      );
      expect(transport.fileReadHandler, isNotNull);

      await done.future;
      expect(transport.fileReadHandler, isNull);
    });

    test('answers requests past the end with an empty chunk', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList([1, 2, 3]),
      );
      final subscription = session.start().listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(transport.fileReadHandler!(7, 'fw.bin', 300, 256), isEmpty);

      await subscription.cancel();
    });

    test('fails when the node never asks for the image', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList(image),
        firstRequestTimeout: const Duration(milliseconds: 30),
      );
      final progress = <FirmwareUpdateProgress>[];
      final done = Completer<void>();
      session.start().listen(progress.add, onDone: done.complete);

      await done.future;

      expect(progress.last.phase, equals(FirmwareUpdatePhase.failed));
      expect(progress.last.error, isA<FirmwareUpdateTimeout>());
      expect(transport.fileReadHandler, isNull);
    });

    test('fails when the node stops reading mid image', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList(image),
        stallTimeout: const Duration(milliseconds: 30),
      );
      final progress = <FirmwareUpdateProgress>[];
      final done = Completer<void>();
      session.start().listen(progress.add, onDone: done.complete);
      await Future<void>.delayed(Duration.zero);

      transport.fileReadHandler!(7, 'fw.bin', 0, fileReadChunkSize);
      await done.future;

      expect(progress.last.phase, equals(FirmwareUpdatePhase.failed));
      expect(progress.last.error, isA<FirmwareUpdateTimeout>());
      expect(progress.last.bytesServed, equals(fileReadChunkSize));
    });

    test('fails when the node rejects the update', () async {
      transport.beginFirmwareResponse = const BeginFirmwareUpdateResponse(
        error: BeginFirmwareUpdateResponse.errorInProgress,
      );
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList([1, 2, 3]),
      );
      final progress = <FirmwareUpdateProgress>[];
      final done = Completer<void>();
      session.start().listen(progress.add, onDone: done.complete);

      await done.future;

      expect(progress.last.phase, equals(FirmwareUpdatePhase.failed));
      expect(
        (progress.last.error! as FirmwareUpdateRejected).code,
        equals(BeginFirmwareUpdateResponse.errorInProgress),
      );
    });

    test('stops serving when the subscription is cancelled', () async {
      final session = FirmwareUploadSession(
        transport: transport,
        nodeId: 7,
        fileName: 'fw.bin',
        firmware: Uint8List.fromList(image),
      );
      final subscription = session.start().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(transport.fileReadHandler, isNotNull);

      await subscription.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(transport.fileReadHandler, isNull);
    });

    group('image size is an exact multiple of the chunk size', () {
      List<int> exactImage() =>
          List<int>.generate(fileReadChunkSize * 2, (index) => index & 0xFF);

      test(
        'serves full chunks and ends with an empty probe response',
        () async {
          final session = FirmwareUploadSession(
            transport: transport,
            nodeId: 7,
            fileName: 'fw.bin',
            firmware: Uint8List.fromList(exactImage()),
          );
          final lengths = <int>[];
          final progress = <FirmwareUpdateProgress>[];
          session.start().listen(progress.add);
          await Future<void>.delayed(Duration.zero);

          var offset = 0;
          while (true) {
            final chunk = transport.fileReadHandler!(
              7,
              'fw.bin',
              offset,
              fileReadChunkSize,
            )!;
            lengths.add(chunk.length);
            offset += chunk.length;
            // A full chunk means "more data", so keep reading; an empty one is
            // the end of the file.
            if (chunk.isEmpty) break;
          }
          await Future<void>.delayed(Duration.zero);

          expect(lengths, equals([256, 256, 0]));
          expect(progress.last.phase, equals(FirmwareUpdatePhase.completed));
          expect(progress.last.bytesServed, equals(2 * fileReadChunkSize));
          expect(progress.last.fraction, equals(1));
          // The handler stays registered for the end-of-file probe.
          expect(transport.fileReadHandler, isNotNull);

          session.cancel();
        },
      );

      test('keeps answering the probe after the last full chunk', () async {
        final session = FirmwareUploadSession(
          transport: transport,
          nodeId: 7,
          fileName: 'fw.bin',
          firmware: Uint8List.fromList(exactImage()),
          gracePeriod: const Duration(milliseconds: 40),
          eofProbeTimeout: const Duration(milliseconds: 200),
        );
        final done = Completer<void>();
        session.start().listen((_) {}, onDone: done.complete);
        await Future<void>.delayed(Duration.zero);

        // Both full chunks.
        for (final offset in [0, fileReadChunkSize]) {
          expect(
            transport.fileReadHandler!(7, 'fw.bin', offset, fileReadChunkSize),
            hasLength(fileReadChunkSize),
          );
        }

        // The probe is still answered although the image is complete.
        expect(
          transport.fileReadHandler!(
            7,
            'fw.bin',
            fileReadChunkSize * 2,
            fileReadChunkSize,
          ),
          isEmpty,
        );

        await done.future;
        expect(transport.fileReadHandler, isNull);
      });

      test('stops serving when the node never probes', () async {
        final session = FirmwareUploadSession(
          transport: transport,
          nodeId: 7,
          fileName: 'fw.bin',
          firmware: Uint8List.fromList(exactImage()),
          gracePeriod: const Duration(milliseconds: 20),
          eofProbeTimeout: const Duration(milliseconds: 60),
        );
        final done = Completer<void>();
        session.start().listen((_) {}, onDone: done.complete);
        await Future<void>.delayed(Duration.zero);

        for (final offset in [0, fileReadChunkSize]) {
          transport.fileReadHandler!(7, 'fw.bin', offset, fileReadChunkSize);
        }
        expect(transport.fileReadHandler, isNotNull);

        await done.future;
        expect(transport.fileReadHandler, isNull);
      });
    });
  });
}
