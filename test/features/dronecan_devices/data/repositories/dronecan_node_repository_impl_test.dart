import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/get_transport_stats.dart';
import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/node_status.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';
import 'package:stork/core/services/dronecan_node_transport.dart';
import 'package:stork/features/dronecan_devices/data/repositories/dronecan_node_repository_impl.dart';
import '../../helpers/fake_dronecan_node_transport.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_failure.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_progress.dart';

GetNodeInfoResponse _nodeInfo({
  String name = 'com.example.instrument',
  Uint8List? uniqueId,
  int swMajor = 1,
  int swMinor = 2,
  int optionalFieldFlags = 0,
  int vcsCommit = 0,
  BigInt? imageCrc,
  int hwMajor = 0,
  int hwMinor = 0,
  Uint8List? certificate,
}) {
  return GetNodeInfoResponse(
    status: NodeStatus(
      uptimeSec: 5,
      health: NodeHealth.ok,
      mode: NodeMode.operational,
    ),
    swMajor: swMajor,
    swMinor: swMinor,
    optionalFieldFlags: optionalFieldFlags,
    vcsCommit: vcsCommit,
    imageCrc: imageCrc,
    hwMajor: hwMajor,
    hwMinor: hwMinor,
    uniqueId: uniqueId ?? Uint8List.fromList(List.generate(16, (i) => i + 1)),
    name: Uint8List.fromList(utf8.encode(name)),
    certificateOfAuthenticity: certificate,
  );
}

NodeStatusReceivedEvent _heartbeat(
  int nodeId, {
  int uptimeSec = 42,
  NodeHealth health = NodeHealth.ok,
  NodeMode mode = NodeMode.operational,
  int vendorSpecificStatusCode = 0,
  DateTime? receivedAt,
}) {
  return NodeStatusReceivedEvent(
    nodeId: nodeId,
    status: NodeStatus(
      uptimeSec: uptimeSec,
      health: health,
      mode: mode,
      vendorSpecificStatusCode: vendorSpecificStatusCode,
    ),
    receivedAt: receivedAt ?? DateTime(2026, 1, 1, 12, 0, 0),
  );
}

void main() {
  group('DroneCanNodeRepositoryImpl', () {
    late FakeDroneCanNodeTransport transport;
    late DroneCanNodeRepositoryImpl repository;
    late List<List<DroneCanNode>> emissions;
    late StreamSubscription<List<DroneCanNode>> subscription;

    setUp(() {
      transport = FakeDroneCanNodeTransport();
      repository = DroneCanNodeRepositoryImpl(transport);
      emissions = [];
      subscription = repository.watchNodes().listen(emissions.add);
    });

    tearDown(() async {
      await subscription.cancel();
      repository.dispose();
      await transport.close();
    });

    test('emits an initial empty snapshot', () async {
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.first, isEmpty);
    });

    test('does not observe the bus before it is used', () async {
      final unused = DroneCanNodeRepositoryImpl(transport);
      addTearDown(unused.dispose);

      transport.addEvent(_heartbeat(9));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(await unused.watchNodes().first, isEmpty);
    });

    test('registers a node from a NodeStatus heartbeat', () async {
      transport.addEvent(
        _heartbeat(
          7,
          uptimeSec: 120,
          health: NodeHealth.warning,
          mode: NodeMode.maintenance,
          vendorSpecificStatusCode: 0x1234,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final node = emissions.last.single;
      expect(node.nodeId, equals(7));
      expect(node.uptimeSec, equals(120));
      expect(node.health, equals(DroneCanNodeHealth.warning));
      expect(node.mode, equals(DroneCanNodeMode.maintenance));
      expect(node.vendorSpecificStatusCode, equals(0x1234));
      expect(node.lastSeen, equals(DateTime(2026, 1, 1, 12, 0, 0)));
    });

    test('fetches name, IDs and GetNodeInfo details', () async {
      transport.infoResponse = (_) => _nodeInfo(
        swMajor: 3,
        swMinor: 4,
        optionalFieldFlags: 5,
        vcsCommit: 0xDEADBEEF,
        imageCrc: BigInt.parse('0123456789ABCDEF', radix: 16),
        hwMajor: 2,
        hwMinor: 7,
        certificate: Uint8List.fromList([0xAA, 0xBB]),
      );

      transport.addEvent(_heartbeat(9));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(transport.infoRequests, equals([9]));
      final node = emissions.last.single;
      expect(node.name, equals('com.example.instrument'));
      expect(node.uniqueId, equals('0102030405060708090A0B0C0D0E0F10'));
      expect(node.swMajor, equals(3));
      expect(node.swMinor, equals(4));
      expect(node.swOptionalFieldFlags, equals(5));
      expect(node.swVcsCommit, equals(0xDEADBEEF));
      expect(node.swImageCrc, equals('0123456789ABCDEF'));
      expect(node.hwMajor, equals(2));
      expect(node.hwMinor, equals(7));
      expect(node.certificateOfAuthenticity, equals('AABB'));
    });

    test('does not re-request node info once it is known', () async {
      transport.infoResponse = (_) => _nodeInfo();

      transport.addEvent(_heartbeat(9));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      transport.addEvent(_heartbeat(9, uptimeSec: 43));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(transport.infoRequests, equals([9]));
    });

    test('drops the cached node info after a restart', () async {
      transport.infoResponse = (_) => _nodeInfo(swMajor: 1);
      transport.addEvent(_heartbeat(9));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(transport.infoRequests, equals([9]));
      expect(emissions.last.single.swMajor, equals(1));

      transport.infoResponse = (_) => _nodeInfo(swMajor: 2);
      await repository.restartNode(9);
      await Future<void>.delayed(Duration.zero);

      // The node rebooted, so the old details are dropped immediately.
      expect(emissions.last.single.swMajor, isNull);

      transport.addEvent(_heartbeat(9, uptimeSec: 2));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(transport.infoRequests, equals([9, 9]));
      expect(emissions.last.single.swMajor, equals(2));
    });

    test('keeps the node visible when GetNodeInfo fails', () async {
      transport.addEvent(_heartbeat(11));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final node = emissions.last.single;
      expect(node.nodeId, equals(11));
      expect(node.name, isNull);
      expect(node.uniqueId, isNull);
    });

    test('clears all nodes on a registry reset', () async {
      transport.addEvent(_heartbeat(3));
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, hasLength(1));

      transport.addEvent(const NodeStatusRegistryClearedEvent());
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last, isEmpty);
    });

    test('sorts nodes by node ID', () async {
      transport.addEvent(_heartbeat(20));
      transport.addEvent(_heartbeat(4));
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.map((node) => node.nodeId), equals([4, 20]));
    });

    group('node info refresh', () {
      test('reports how many nodes answered', () async {
        transport.infoResponse = (_) => _nodeInfo();
        transport.addEvent(_heartbeat(1));
        transport.addEvent(_heartbeat(2));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final refresh = await repository.refreshNodeInfo();

        expect(refresh.requested, equals(2));
        expect(refresh.answered, equals(2));
        expect(refresh.isComplete, isTrue);
      });

      test('reports nodes that did not answer', () async {
        transport.infoResponse = (_) => _nodeInfo();
        transport.addEvent(_heartbeat(1));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        transport.infoResponse = null; // Any further request times out.
        final refresh = await repository.refreshNodeInfo();

        expect(refresh.requested, equals(1));
        expect(refresh.answered, equals(0));
        expect(refresh.isComplete, isFalse);
      });

      test('reports an empty refresh when no node is known', () async {
        final refresh = await repository.refreshNodeInfo();

        expect(refresh.isEmpty, isTrue);
        expect(transport.infoRequests, isEmpty);
      });
    });

    test('restarts the node through the transport', () async {
      final accepted = await repository.restartNode(12);

      expect(accepted, isTrue);
      expect(transport.restartRequests, equals([12]));
    });

    test('reports a rejected restart', () async {
      transport.restartAccepted = false;

      expect(await repository.restartNode(12), isFalse);
    });

    test('maps transport statistics to the domain model', () async {
      transport.statsResponse = const GetTransportStatsResponse(
        transfersTx: 11,
        transfersRx: 22,
        transferErrors: 3,
        canIfaceStats: [CanIfaceStats(framesTx: 100, framesRx: 200, errors: 4)],
      );

      final stats = await repository.getTransportStats(5);

      expect(transport.statsRequests, equals([5]));
      expect(stats.transfersTx, equals(11));
      expect(stats.transfersRx, equals(22));
      expect(stats.transferErrors, equals(3));
      expect(stats.canInterfaces, hasLength(1));
      expect(stats.canInterfaces.single.framesTx, equals(100));
      expect(stats.canInterfaces.single.framesRx, equals(200));
      expect(stats.canInterfaces.single.errors, equals(4));
    });

    group('parameters', () {
      test('streams the parameter list while it is read', () async {
        transport.parameterResponse = (request) => switch (request.index) {
          0 => const GetSetResponse(name: 'A', value: ParamValue.integer(1)),
          1 => const GetSetResponse(name: 'B', value: ParamValue.integer(2)),
          _ => const GetSetResponse(name: ''),
        };

        final snapshots = <List<String>>[];
        await for (final parameters in repository.watchParameters(4)) {
          snapshots.add(parameters.map((parameter) => parameter.name).toList());
        }

        expect(
          snapshots,
          equals([
            <String>[],
            ['A'],
            ['A', 'B'],
          ]),
        );
        expect(
          transport.parameterRequests.map((request) => request.index),
          equals([0, 1, 2]),
        );
      });

      test('keeps the snapshots read before a scan failure', () async {
        transport.parameterResponse = (request) => request.index == 0
            ? const GetSetResponse(name: 'A', value: ParamValue.integer(1))
            : throw TimeoutException('no response');

        final snapshots = <List<String>>[];
        await expectLater(
          repository
              .watchParameters(4)
              .forEach(
                (parameters) => snapshots.add(
                  parameters.map((parameter) => parameter.name).toList(),
                ),
              ),
          throwsA(isA<TimeoutException>()),
        );

        expect(
          snapshots,
          equals([
            <String>[],
            ['A'],
          ]),
        );
        // Index 1 is read twice: the first timeout is retried.
        expect(
          transport.parameterRequests.map((request) => request.index),
          equals([0, 1, 1]),
        );
      });

      test('retries a parameter read that timed out', () async {
        var timedOut = false;
        transport.parameterResponse = (request) {
          if (request.index == 1 && !timedOut) {
            timedOut = true;
            throw TimeoutException('lost frame');
          }
          return switch (request.index) {
            0 => const GetSetResponse(name: 'A', value: ParamValue.integer(1)),
            1 => const GetSetResponse(name: 'B', value: ParamValue.integer(2)),
            _ => const GetSetResponse(name: ''),
          };
        };

        final parameters = await repository.watchParameters(4).toList();

        expect(
          parameters.last.map((parameter) => parameter.name),
          equals(['A', 'B']),
        );
        expect(
          transport.parameterRequests.map((request) => request.index),
          equals([0, 1, 1, 2]),
        );
      });

      test('does not retry a parameter the node rejects', () async {
        transport.parameterResponse = (request) => request.index == 0
            ? const GetSetResponse(name: 'A', value: ParamValue.integer(1))
            : throw FormatException('malformed payload');

        await expectLater(
          repository.watchParameters(4).toList(),
          throwsA(isA<FormatException>()),
        );
        expect(
          transport.parameterRequests.map((request) => request.index),
          equals([0, 1]),
        );
      });

      test('reads a parameter by index', () async {
        transport.parameterResponse = (request) => request.index == 0
            ? const GetSetResponse(
                name: 'ESC_INDEX',
                value: ParamValue.integer(2),
                defaultValue: ParamValue.integer(3),
                minValue: ParamNumericValue.integer(0),
                maxValue: ParamNumericValue.integer(5),
              )
            : const GetSetResponse(name: '');

        final parameter = await repository.getParameterByIndex(4, 0);

        expect(transport.parameterRequests.single.index, equals(0));
        expect(parameter?.index, equals(0));
        expect(parameter?.name, equals('ESC_INDEX'));
        expect(parameter?.value, equals(const DroneCanParamValue.integer(2)));
        expect(
          parameter?.defaultValue,
          equals(const DroneCanParamValue.integer(3)),
        );
        expect(parameter?.minValue, equals(0));
        expect(parameter?.maxValue, equals(5));
        expect(parameter?.isModified, isTrue);
      });

      test('reports the end of the parameter list', () async {
        transport.parameterResponse = (_) => const GetSetResponse(name: '');

        expect(await repository.getParameterByIndex(4, 120), isNull);
      });

      test('sets a parameter by name and keeps the node metadata', () async {
        transport.parameterResponse = (request) => GetSetResponse(
          name: request.name,
          value: const ParamValue.integer(7),
        );

        const parameter = DroneCanParameter(
          index: 2,
          name: 'ESC_INDEX',
          value: DroneCanParamValue.integer(3),
          defaultValue: DroneCanParamValue.integer(3),
          minValue: 0,
          maxValue: 10,
        );

        final updated = await repository.setParameterValue(
          4,
          parameter,
          const DroneCanParamValue.integer(7),
        );

        final request = transport.parameterRequests.single;
        expect(request.name, equals('ESC_INDEX'));
        expect(request.value, equals(const ParamValue.integer(7)));
        expect(updated.index, equals(2));
        expect(updated.value, equals(const DroneCanParamValue.integer(7)));
        expect(
          updated.defaultValue,
          equals(const DroneCanParamValue.integer(3)),
        );
        expect(updated.minValue, equals(0));
        expect(updated.maxValue, equals(10));
        expect(updated.isModified, isTrue);
      });

      test('rejects a parameter the node does not know', () async {
        transport.parameterResponse = (_) => const GetSetResponse(name: '');

        const parameter = DroneCanParameter(
          index: 0,
          name: 'NOPE',
          value: DroneCanParamValue.integer(1),
        );

        await expectLater(
          repository.setParameterValue(
            4,
            parameter,
            const DroneCanParamValue.integer(2),
          ),
          throwsStateError,
        );
      });

      test('stores and erases the node configuration', () async {
        expect(await repository.storeParameters(4), isTrue);
        expect(await repository.eraseParameters(4), isTrue);
        expect(
          transport.opcodeRequests,
          equals([
            ExecuteOpcodeRequest.opcodeSave,
            ExecuteOpcodeRequest.opcodeErase,
          ]),
        );

        transport.opcodeAccepted = false;
        expect(await repository.eraseParameters(4), isFalse);
      });
    });

    group('firmware update', () {
      /// Serves [image] the way a node does: it asks for consecutive chunks
      /// until a short response marks the end of the file.
      Future<(List<int>, List<int>)> pullImage(
        DroneCanFileReadHandler handler,
        int nodeId,
        String path,
        int imageLength,
      ) async {
        final served = <int>[];
        final lengths = <int>[];
        var offset = 0;
        while (true) {
          final chunk =
              handler(nodeId, path, offset, fileReadChunkSize) ?? const [];
          lengths.add(chunk.length);
          served.addAll(chunk);
          if (chunk.length < fileReadChunkSize) break;
          offset += chunk.length;
          if (offset > imageLength + fileReadChunkSize) break;
        }
        return (served, lengths);
      }

      test('serves the image and reports progress', () async {
        final image = Uint8List.fromList(
          List<int>.generate(600, (index) => index & 0xFF),
        );

        final progress = <FirmwareUpdateProgress>[];
        final subscription = repository
            .updateFirmware(7, 'fw.bin', image)
            .listen(progress.add);

        await Future<void>.delayed(Duration.zero);
        expect(
          transport.beginFirmwareRequests,
          equals([(nodeId: 7, path: 'fw.bin')]),
        );

        final handler = transport.fileReadHandler;
        expect(handler, isNotNull);

        final (served, lengths) = await pullImage(handler!, 7, 'fw.bin', 600);
        expect(served, equals(image));
        // Two full chunks and a short final one that marks the end of file.
        expect(lengths, equals([256, 256, 88]));

        await Future<void>.delayed(Duration.zero);
        expect(progress.first.phase, equals(FirmwareUpdatePhase.preparing));
        expect(progress.last.phase, equals(FirmwareUpdatePhase.completed));
        expect(progress.last.bytesServed, equals(600));
        expect(progress.last.totalBytes, equals(600));
        expect(progress.last.fraction, equals(1.0));

        await subscription.cancel();
        // Cancelling stops serving the image.
        expect(transport.fileReadHandler, isNull);
      });

      test('ignores read requests of other nodes and paths', () async {
        final image = Uint8List.fromList(List<int>.filled(300, 0x5A));
        final subscription = repository
            .updateFirmware(7, 'fw.bin', image)
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);

        final handler = transport.fileReadHandler!;
        expect(handler(8, 'fw.bin', 0, fileReadChunkSize), isNull);
        expect(handler(7, 'other.bin', 0, fileReadChunkSize), isNull);
        expect(
          handler(7, 'fw.bin', 0, fileReadChunkSize),
          hasLength(fileReadChunkSize),
        );

        await subscription.cancel();
      });

      test('reports a rejected update', () async {
        transport.beginFirmwareResponse = const BeginFirmwareUpdateResponse(
          error: BeginFirmwareUpdateResponse.errorInvalidMode,
          optionalErrorMessage: 'busy',
        );

        final progress = <FirmwareUpdateProgress>[];
        final done = Completer<void>();
        repository
            .updateFirmware(7, 'fw.bin', Uint8List.fromList([1, 2, 3]))
            .listen(
              progress.add,
              onDone: () {
                if (!done.isCompleted) done.complete();
              },
            );

        await done.future;

        final failure = progress.last;
        expect(failure.phase, equals(FirmwareUpdatePhase.failed));
        expect(
          failure.error,
          isA<FirmwareUpdateRejected>()
              .having(
                (e) => e.code,
                'code',
                BeginFirmwareUpdateResponse.errorInvalidMode,
              )
              .having((e) => e.nodeMessage, 'message', 'busy'),
        );
        expect(transport.fileReadHandler, isNull);
      });

      test('reports a transport failure', () async {
        transport.beginFirmwareError = StateError('offline');

        final progress = <FirmwareUpdateProgress>[];
        final done = Completer<void>();
        repository
            .updateFirmware(7, 'fw.bin', Uint8List.fromList([1, 2, 3]))
            .listen(
              progress.add,
              onDone: () {
                if (!done.isCompleted) done.complete();
              },
            );

        await done.future;

        expect(progress.last.phase, equals(FirmwareUpdatePhase.failed));
        expect(progress.last.error, isA<StateError>());
      });

      test('drops the cached node info once the image was served', () async {
        transport.infoResponse = (_) => _nodeInfo(swMajor: 1, swMinor: 0);
        transport.addEvent(_heartbeat(7));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(emissions.last.single.name, equals('com.example.instrument'));

        final image = Uint8List.fromList(List<int>.filled(200, 0x11));
        final subscription = repository
            .updateFirmware(7, 'fw.bin', image)
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);

        await pullImage(transport.fileReadHandler!, 7, 'fw.bin', 200);
        await Future<void>.delayed(Duration.zero);

        // The version is re-read once the node reports again.
        expect(emissions.last.single.name, isNull);
        expect(emissions.last.single.swMajor, isNull);

        await subscription.cancel();
      });

      test('rejects a second concurrent update', () async {
        final subscription = repository
            .updateFirmware(7, 'fw.bin', Uint8List.fromList([1, 2, 3]))
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);

        expect(
          () => repository.updateFirmware(7, 'fw.bin', Uint8List.fromList([4])),
          throwsStateError,
        );

        await subscription.cancel();
      });
    });
  });
}
