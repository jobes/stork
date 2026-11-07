import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/data/services/firmware_file_picker.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_failure.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_progress.dart';
import 'package:stork/features/dronecan_devices/domain/models/transport_statistics.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node_info_refresh.dart';
import 'package:stork/features/dronecan_devices/domain/repositories/dronecan_node_repository.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_firmware_update_provider.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_nodes_provider.dart';

class _FakeRepository implements DroneCanNodeRepository {
  final List<({String fileName, int size})> uploads = [];
  Object? uploadError;
  StreamController<FirmwareUpdateProgress>? uploadStream;
  Uint8List? lastImage;

  @override
  Stream<FirmwareUpdateProgress> updateFirmware(
    int nodeId,
    String fileName,
    Uint8List firmware,
  ) {
    uploads.add((fileName: fileName, size: firmware.length));
    lastImage = firmware;
    final error = uploadError;
    if (error != null) throw error;
    return (uploadStream ??= StreamController<FirmwareUpdateProgress>()).stream;
  }

  @override
  Future<DroneCanParameter?> getParameterByIndex(int nodeId, int index) async =>
      null;

  @override
  Stream<List<DroneCanParameter>> watchParameters(int nodeId) =>
      const Stream.empty();

  @override
  Future<DroneCanParameter> setParameterValue(
    int nodeId,
    DroneCanParameter parameter,
    DroneCanParamValue value,
  ) async => parameter;

  @override
  Future<bool> storeParameters(int nodeId) async => true;

  @override
  Future<bool> eraseParameters(int nodeId) async => true;

  @override
  Future<DroneCanNodeInfoRefresh> refreshNodeInfo() async =>
      const DroneCanNodeInfoRefresh(requested: 0, answered: 0);

  @override
  Stream<List<DroneCanNode>> watchNodes() => const Stream.empty();

  @override
  Future<bool> restartNode(int nodeId) async => true;

  @override
  Future<TransportStatistics> getTransportStats(int nodeId) async =>
      throw UnimplementedError();

  @override
  void dispose() {}
}

class _FakePicker implements FirmwareFilePicker {
  PickedFirmwareFile? result;
  Object? error;
  int calls = 0;

  @override
  Future<PickedFirmwareFile?> pick() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

PickedFirmwareFile _file({int size = 512}) => PickedFirmwareFile(
  name: 'AP_Periph.bin',
  bytes: Uint8List.fromList(List<int>.generate(size, (index) => index & 0xFF)),
);

void main() {
  late _FakeRepository repository;
  late _FakePicker picker;
  late ProviderContainer container;

  DroneCanFirmwareUpdateState stateOf() =>
      container.read(droneCanFirmwareUpdateProvider(7));

  DroneCanFirmwareUpdateNotifier notifierOf() =>
      container.read(droneCanFirmwareUpdateProvider(7).notifier);

  setUp(() {
    repository = _FakeRepository();
    picker = _FakePicker();
    container = ProviderContainer(
      overrides: [
        droneCanNodeRepositoryProvider.overrideWithValue(repository),
        firmwareFilePickerProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(container.dispose);
    container.listen(droneCanFirmwareUpdateProvider(7), (_, _) {});
  });

  test('starts empty', () {
    expect(stateOf().file, isNull);
    expect(stateOf().canStart, isFalse);
    expect(stateOf().progress.phase, equals(FirmwareUpdatePhase.idle));
  });

  test('remembers the selected file', () async {
    picker.result = _file();

    await notifierOf().selectFirmware();

    expect(picker.calls, equals(1));
    expect(stateOf().file?.name, equals('AP_Periph.bin'));
    expect(stateOf().file?.size, equals(512));
    expect(stateOf().canStart, isTrue);
  });

  test('keeps the previous file when the dialog is cancelled', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    picker.result = null;
    await notifierOf().selectFirmware();

    expect(stateOf().file?.name, equals('AP_Periph.bin'));
  });

  test('reports a picker failure', () async {
    picker.error = StateError('no dialog');

    await notifierOf().selectFirmware();

    expect(stateOf().pickError, isA<StateError>());
    expect(stateOf().file, isNull);
    expect(stateOf().isPicking, isFalse);
  });

  test('uploads the selected image and follows the progress', () async {
    picker.result = _file(size: 600);
    await notifierOf().selectFirmware();

    final upload = notifierOf().upload();
    final controller = repository.uploadStream!;
    controller.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.uploading,
        bytesServed: 256,
        totalBytes: 600,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.uploads.single.fileName, equals('AP_Periph.bin'));
    expect(repository.uploads.single.size, equals(600));
    expect(stateOf().isRunning, isTrue);
    expect(stateOf().progress.fraction, closeTo(256 / 600, 1e-9));

    controller.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.completed,
        bytesServed: 600,
        totalBytes: 600,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    // The session still answers the node after the last chunk, so the upload
    // is not finished yet.
    expect(stateOf().isCompleted, isTrue);
    expect(stateOf().uploadFinished, isFalse);
    expect(stateOf().isBusy, isTrue);
    expect(stateOf().canStart, isFalse);

    await controller.close();
    await upload;

    expect(stateOf().isCompleted, isTrue);
    expect(stateOf().uploadFinished, isTrue);
    expect(stateOf().isBusy, isFalse);
    expect(stateOf().progress.fraction, equals(1));
  });

  test('does not mark a failed upload as finished', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    final upload = notifierOf().upload();
    final controller = repository.uploadStream!;
    controller.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.failed,
        totalBytes: 512,
        error: FirmwareUpdateRejected(code: 2),
      ),
    );
    await controller.close();
    await upload;

    expect(stateOf().isFailed, isTrue);
    expect(stateOf().uploadFinished, isFalse);
    expect(stateOf().isBusy, isFalse);
  });

  test('reports a rejected update', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    final upload = notifierOf().upload();
    final controller = repository.uploadStream!;
    controller.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.failed,
        totalBytes: 512,
        error: FirmwareUpdateRejected(code: 1, nodeMessage: 'busy'),
      ),
    );
    await controller.close();
    await upload;

    expect(stateOf().isFailed, isTrue);
    expect(stateOf().progress.error, isA<FirmwareUpdateRejected>());
  });

  test('reports a stream error', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    final upload = notifierOf().upload();
    final controller = repository.uploadStream!;
    controller.addError(StateError('offline'));
    await controller.close();
    await upload;

    expect(stateOf().isFailed, isTrue);
    expect(stateOf().progress.error, isA<StateError>());
  });

  test('reports a synchronous repository failure', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();
    repository.uploadError = StateError('already running');

    await notifierOf().upload();

    expect(stateOf().isFailed, isTrue);
    expect(stateOf().progress.error, isA<StateError>());
  });

  test('refuses an empty image', () async {
    picker.result = _file(size: 0);
    await notifierOf().selectFirmware();

    await notifierOf().upload();

    expect(repository.uploads, isEmpty);
    expect(stateOf().isFailed, isTrue);
    expect(stateOf().progress.error, isA<FirmwareUpdateInvalidImage>());
  });

  test('cancel stops listening', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    final upload = notifierOf().upload();
    await Future<void>.delayed(Duration.zero);
    expect(stateOf().isRunning, isTrue);

    notifierOf().cancel();
    await upload;

    expect(stateOf().progress.phase, equals(FirmwareUpdatePhase.idle));
  });

  test('clears the selected image', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    notifierOf().clearFirmware();

    expect(stateOf().file, isNull);
    expect(stateOf().canStart, isFalse);
  });

  test('disposing the provider ends a running upload', () async {
    picker.result = _file();
    await notifierOf().selectFirmware();

    final upload = notifierOf().upload();
    await Future<void>.delayed(Duration.zero);
    expect(stateOf().isRunning, isTrue);

    // The dialog was closed, so the provider is disposed.
    container.dispose();
    await upload;
  });
}
