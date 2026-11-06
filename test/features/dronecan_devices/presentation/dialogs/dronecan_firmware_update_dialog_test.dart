import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/data/services/firmware_file_picker.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_failure.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_progress.dart';
import 'package:stork/features/dronecan_devices/domain/models/transport_statistics.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node_info_refresh.dart';
import 'package:stork/features/dronecan_devices/domain/repositories/dronecan_node_repository.dart';
import 'package:stork/features/dronecan_devices/presentation/dialogs/dronecan_firmware_update_dialog.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_firmware_update_provider.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_nodes_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _FakeRepository implements DroneCanNodeRepository {
  StreamController<FirmwareUpdateProgress>? controller;
  int uploads = 0;

  @override
  Stream<FirmwareUpdateProgress> updateFirmware(
    int nodeId,
    String fileName,
    Uint8List firmware,
  ) {
    uploads++;
    return (controller ??= StreamController<FirmwareUpdateProgress>()).stream;
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

  @override
  Future<PickedFirmwareFile?> pick() async => result;
}

final _node = DroneCanNode(
  nodeId: 42,
  name: 'com.example.ahrs',
  health: DroneCanNodeHealth.ok,
  mode: DroneCanNodeMode.operational,
  uptimeSec: 100,
  lastSeen: DateTime(2026, 1, 1, 12),
);

Future<void> _openDialog(
  WidgetTester tester, {
  required _FakeRepository repository,
  required _FakePicker picker,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        droneCanNodeRepositoryProvider.overrideWithValue(repository),
        firmwareFilePickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDroneCanFirmwareUpdateDialog(context, _node),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('shows the empty state and the risks', (tester) async {
    await _openDialog(
      tester,
      repository: _FakeRepository(),
      picker: _FakePicker(),
    );

    expect(find.text('Firmware update'), findsOneWidget);
    expect(find.text('No firmware file selected'), findsOneWidget);
    expect(
      find.text(
        'Never update firmware in flight. The node is unavailable while it '
        'updates.',
      ),
      findsOneWidget,
    );
    // Nothing to upload yet.
    final upload = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Upload firmware'),
    );
    expect(upload.onPressed, isNull);
  });

  testWidgets('selects a file and uploads it', (tester) async {
    final repository = _FakeRepository();
    final picker = _FakePicker()
      ..result = PickedFirmwareFile(
        name: 'AP_Periph.bin',
        bytes: Uint8List.fromList(List<int>.filled(600, 0xAA)),
      );

    await _openDialog(tester, repository: repository, picker: picker);
    await _tap(tester, find.text('Choose file'));
    await tester.pumpAndSettle();

    expect(find.text('AP_Periph.bin'), findsOneWidget);
    expect(find.text('600 B'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'Upload firmware'));
    await tester.pump();

    expect(repository.uploads, equals(1));
    expect(
      find.text('Waiting for the node to request the image…'),
      findsOneWidget,
    );

    repository.controller!.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.uploading,
        bytesServed: 300,
        totalBytes: 600,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Uploading firmware…'), findsOneWidget);
    expect(find.text('50 % (300 B of 600 B)'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.5, 1e-9));

    repository.controller!.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.completed,
        bytesServed: 600,
        totalBytes: 600,
      ),
    );
    await tester.pump();

    // The image is served, but the session still answers the node (end-of-file
    // probe and retries), so the dialog stays open.
    expect(find.text('Firmware update'), findsOneWidget);
    expect(
      find.text(
        'Firmware uploaded. The node verifies the image and restarts with the '
        'new version.',
      ),
      findsOneWidget,
    );

    await repository.controller!.close();
    await tester.pumpAndSettle();

    // The dialog closes once the upload session has finished and the result is
    // reported outside of it.
    expect(find.text('Firmware update'), findsNothing);
    expect(
      find.text(
        'Firmware uploaded. The node verifies the image and restarts with the '
        'new version.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the rejection reason from the node', (tester) async {
    final repository = _FakeRepository();
    final picker = _FakePicker()
      ..result = PickedFirmwareFile(
        name: 'fw.bin',
        bytes: Uint8List.fromList(List<int>.filled(64, 0)),
      );

    await _openDialog(tester, repository: repository, picker: picker);
    await _tap(tester, find.text('Choose file'));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(FilledButton, 'Upload firmware'));
    await tester.pump();

    repository.controller!.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.failed,
        error: FirmwareUpdateRejected(code: 1, nodeMessage: 'node is busy'),
      ),
    );
    await tester.pump();

    expect(find.text('The firmware update failed.'), findsOneWidget);
    expect(
      find.text('The node refused the update: node is busy'),
      findsOneWidget,
    );
  });

  testWidgets('shows a generic message for a timeout', (tester) async {
    final repository = _FakeRepository();
    final picker = _FakePicker()
      ..result = PickedFirmwareFile(
        name: 'fw.bin',
        bytes: Uint8List.fromList(List<int>.filled(64, 0)),
      );

    await _openDialog(tester, repository: repository, picker: picker);
    await _tap(tester, find.text('Choose file'));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(FilledButton, 'Upload firmware'));
    await tester.pump();

    repository.controller!.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.failed,
        error: FirmwareUpdateTimeout('no data'),
      ),
    );
    await tester.pump();

    expect(
      find.text('The node stopped requesting firmware data.'),
      findsOneWidget,
    );
  });

  testWidgets('cannot be dismissed while uploading', (tester) async {
    final repository = _FakeRepository();
    final picker = _FakePicker()
      ..result = PickedFirmwareFile(
        name: 'fw.bin',
        bytes: Uint8List.fromList(List<int>.filled(64, 0)),
      );

    await _openDialog(tester, repository: repository, picker: picker);
    await _tap(tester, find.text('Choose file'));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(FilledButton, 'Upload firmware'));
    await tester.pump();

    final closeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close),
    );
    expect(closeButton.onPressed, isNull);
    // Cancelling is offered instead.
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    await _tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();

    expect(find.text('No firmware file selected'), findsNothing);
    expect(find.text('fw.bin'), findsOneWidget);
  });

  testWidgets('tapping outside closes the dialog when no upload runs', (
    tester,
  ) async {
    await _openDialog(
      tester,
      repository: _FakeRepository(),
      picker: _FakePicker(),
    );

    // Well outside the dialog: the modal barrier.
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(find.text('Firmware update'), findsNothing);
  });

  testWidgets('tapping outside is ignored while uploading', (tester) async {
    final repository = _FakeRepository();
    final picker = _FakePicker()
      ..result = PickedFirmwareFile(
        name: 'fw.bin',
        bytes: Uint8List.fromList(List<int>.filled(64, 0)),
      );

    await _openDialog(tester, repository: repository, picker: picker);
    await _tap(tester, find.text('Choose file'));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(FilledButton, 'Upload firmware'));
    await tester.pump();

    await tester.tapAt(const Offset(2, 2));
    // The indeterminate progress bar never settles, so pump a fixed frame.
    await tester.pump(const Duration(milliseconds: 300));

    // Closing would abort the transfer and could leave the node in its
    // bootloader, so the dialog stays and the upload keeps running.
    expect(find.text('Firmware update'), findsOneWidget);
    expect(find.text('Uploading firmware…'), findsNothing);
    expect(
      find.text('Waiting for the node to request the image…'),
      findsOneWidget,
    );

    repository.controller!.add(
      const FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.completed,
        bytesServed: 64,
        totalBytes: 64,
      ),
    );
    await tester.pump();

    // The session still serves the node, so the dialog must not be dismissed
    // yet either.
    expect(find.text('Firmware update'), findsOneWidget);
    final closeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close),
    );
    expect(closeButton.onPressed, isNull);

    await repository.controller!.close();
    await tester.pumpAndSettle();

    // A finished upload closes the dialog on its own.
    expect(find.text('Firmware update'), findsNothing);
  });
}
