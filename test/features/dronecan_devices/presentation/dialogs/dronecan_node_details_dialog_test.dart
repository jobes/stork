import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_progress.dart';
import 'package:stork/features/dronecan_devices/domain/models/transport_statistics.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node_info_refresh.dart';
import 'package:stork/features/dronecan_devices/domain/repositories/dronecan_node_repository.dart';
import 'package:stork/features/dronecan_devices/presentation/dialogs/dronecan_node_details_dialog.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_nodes_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _FakeRepository implements DroneCanNodeRepository {
  final List<int> restartRequests = [];
  final List<int> statsRequests = [];
  bool restartAccepted = true;
  TransportStatistics stats = const TransportStatistics(
    transfersTx: 12,
    transfersRx: 34,
    transferErrors: 0,
    canInterfaces: [
      CanInterfaceStatistics(framesTx: 100, framesRx: 200, errors: 0),
    ],
  );
  Object? statsError;

  /// Parameters served by [getParameterByIndex], keyed by index.
  final Map<int, DroneCanParameter> parameters = {};
  final List<({String name, DroneCanParamValue value})> setRequests = [];
  int storeRequests = 0;
  int eraseRequests = 0;
  bool storeAccepted = true;
  bool eraseAccepted = true;

  /// Optional sequence of samples returned by consecutive calls; the last one
  /// is repeated afterwards.
  List<TransportStatistics> statsSamples = const [];

  /// Node snapshots pushed to the details dialog.
  final StreamController<List<DroneCanNode>> nodes =
      StreamController<List<DroneCanNode>>.broadcast();

  @override
  Stream<List<DroneCanNode>> watchNodes() => nodes.stream;

  @override
  Future<DroneCanNodeInfoRefresh> refreshNodeInfo() async =>
      const DroneCanNodeInfoRefresh(requested: 0, answered: 0);

  @override
  Future<bool> restartNode(int nodeId) async {
    restartRequests.add(nodeId);
    return restartAccepted;
  }

  @override
  Future<TransportStatistics> getTransportStats(int nodeId) async {
    statsRequests.add(nodeId);
    final error = statsError;
    if (error != null) throw error;
    if (statsSamples.isEmpty) return stats;
    final index = statsRequests.length - 1;
    return statsSamples[index < statsSamples.length
        ? index
        : statsSamples.length - 1];
  }

  @override
  Future<DroneCanParameter?> getParameterByIndex(int nodeId, int index) async {
    return parameters[index];
  }

  @override
  Stream<List<DroneCanParameter>> watchParameters(int nodeId) async* {
    final read = <DroneCanParameter>[];
    yield const <DroneCanParameter>[];

    for (var index = 0; parameters.containsKey(index); index++) {
      read.add(parameters[index]!);
      yield List<DroneCanParameter>.unmodifiable(read);
    }
  }

  @override
  Future<DroneCanParameter> setParameterValue(
    int nodeId,
    DroneCanParameter parameter,
    DroneCanParamValue value,
  ) async {
    setRequests.add((name: parameter.name, value: value));
    return parameter.withValue(value);
  }

  @override
  Future<bool> storeParameters(int nodeId) async {
    storeRequests++;
    return storeAccepted;
  }

  @override
  Future<bool> eraseParameters(int nodeId) async {
    eraseRequests++;
    return eraseAccepted;
  }

  final List<({String fileName, int size})> firmwareUpdates = [];

  @override
  Stream<FirmwareUpdateProgress> updateFirmware(
    int nodeId,
    String fileName,
    Uint8List firmware,
  ) async* {
    firmwareUpdates.add((fileName: fileName, size: firmware.length));
    yield FirmwareUpdateProgress(
      phase: FirmwareUpdatePhase.completed,
      bytesServed: firmware.length,
      totalBytes: firmware.length,
    );
  }

  @override
  void dispose() {}
}

class _ConnectedCannelloniService extends CannelloniService {
  @override
  bool build() => true;
}

final _node = DroneCanNode(
  nodeId: 42,
  name: 'com.example.ahrs',
  uniqueId: '0102030405060708090A0B0C0D0E0F10',
  health: DroneCanNodeHealth.ok,
  mode: DroneCanNodeMode.operational,
  uptimeSec: 100,
  lastSeen: DateTime(2026, 1, 1, 12),
  swMajor: 1,
  swMinor: 2,
  hwMajor: 3,
  hwMinor: 4,
  vendorSpecificStatusCode: 0x1A2B,
);

/// Taps an action button, scrolling it into view first because the dialog body
/// may be taller than the test surface.
Future<void> _tapAction(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps a control inside a dialog, scrolling it into view first.
Future<void> _tapInDialog(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens the transport statistics dialog and lets the first sample arrive.
Future<void> _openTransportStats(WidgetTester tester) async {
  final finder = find.text('Transport stats');
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _openDialog(WidgetTester tester, _FakeRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        droneCanNodeRepositoryProvider.overrideWithValue(repo),
        cannelloniServiceProvider.overrideWith(_ConnectedCannelloniService.new),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDroneCanNodeDetailsDialog(context, _node),
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

/// Opens the configuration dialog of the node details dialog.
Future<void> _openConfiguration(WidgetTester tester) async {
  final finder = find.text('Configuration');
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Pushes [nodes] to the registry the way the repository does: a fresh
/// snapshot on every tick, so a listener that subscribes late still gets one.
Future<void> _publishNodes(
  WidgetTester tester,
  _FakeRepository repo,
  List<DroneCanNode> nodes,
) async {
  repo.nodes.add(nodes);
  await tester.pump();
  repo.nodes.add(nodes);
  await tester.pump();
}

void main() {
  testWidgets('shows all node action buttons', (tester) async {
    await _openDialog(tester, _FakeRepository());

    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Transport stats'), findsOneWidget);
    expect(find.text('Update firmware'), findsOneWidget);
    expect(find.text('Configuration'), findsOneWidget);
  });

  testWidgets('restart asks for confirmation and calls the repository', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _openDialog(tester, repo);

    await _tapAction(tester, 'Restart');

    expect(find.text('Restart node'), findsOneWidget);
    expect(repo.restartRequests, isEmpty);

    expect(
      find.text(
        'The node stops sending data for several seconds and everything it '
        'provides is unavailable meanwhile.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Any unsaved node configuration will be lost.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Never restart a node in flight. It can take away instruments you '
        'rely on.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'If the restart fails, the node may stay offline until the CAN bus is '
        'power-cycled.',
      ),
      findsOneWidget,
    );

    await _tapInDialog(
      tester,
      find.widgetWithText(FilledButton, 'Restart anyway'),
    );

    expect(repo.restartRequests, equals([42]));
    expect(find.text('Restart command accepted'), findsOneWidget);
  });

  testWidgets('restart is skipped when the confirmation is cancelled', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _openDialog(tester, repo);

    await _tapAction(tester, 'Restart');
    await _tapInDialog(tester, find.text('Cancel'));

    expect(repo.restartRequests, isEmpty);
    // The confirmation dialog is closed again.
    expect(find.text('Restart anyway'), findsNothing);
  });

  testWidgets('transport stats dialog shows values with deltas', (
    tester,
  ) async {
    final repo = _FakeRepository()
      ..statsSamples = const [
        TransportStatistics(
          transfersTx: 12,
          transfersRx: 34,
          transferErrors: 0,
          canInterfaces: [
            CanInterfaceStatistics(framesTx: 100, framesRx: 200, errors: 0),
          ],
        ),
        TransportStatistics(
          transfersTx: 15,
          transfersRx: 40,
          transferErrors: 2,
          canInterfaces: [
            CanInterfaceStatistics(framesTx: 180, framesRx: 250, errors: 1),
          ],
        ),
      ];
    await _openDialog(tester, repo);
    await _openTransportStats(tester);

    expect(repo.statsRequests, equals([42]));
    expect(find.text('Transport statistics · 42'), findsOneWidget);
    expect(find.text('Transfers TX'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('(---)'), findsWidgets);

    // One second later a new sample arrives with the change in brackets.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(repo.statsRequests, equals([42, 42]));
    expect(find.text('15'), findsOneWidget);
    expect(find.text('(+3)'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('(+6)'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('(+80)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('transport stats show no delta after a counter reset', (
    tester,
  ) async {
    final repo = _FakeRepository()
      ..statsSamples = const [
        TransportStatistics(
          transfersTx: 100,
          transfersRx: 100,
          transferErrors: 0,
          canInterfaces: [],
        ),
        TransportStatistics(
          transfersTx: 5,
          transfersRx: 7,
          transferErrors: 0,
          canInterfaces: [],
        ),
      ];
    await _openDialog(tester, repo);
    await _openTransportStats(tester);

    expect(find.text('100'), findsNWidgets(2));
    expect(find.text('(---)'), findsNWidgets(3));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    // Counters that went backwards show no delta; errors stayed at zero.
    expect(find.text('(---)'), findsNWidgets(2));
    expect(find.text('(+0)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('transport stats failure shows a message', (tester) async {
    final repo = _FakeRepository()..statsError = StateError('offline');
    await _openDialog(tester, repo);
    await _openTransportStats(tester);

    expect(
      find.text('Request failed. Check the DroneCAN connection.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('update firmware opens the firmware update dialog', (
    tester,
  ) async {
    await _openDialog(tester, _FakeRepository());

    await _tapAction(tester, 'Update firmware');

    expect(find.text('Firmware update'), findsOneWidget);
    expect(find.text('No firmware file selected'), findsOneWidget);
    expect(find.text('Choose file'), findsOneWidget);
  });

  testWidgets('configuration dialog lists all node parameters', (tester) async {
    final repo = _FakeRepository()
      ..parameters[0] = const DroneCanParameter(
        index: 0,
        name: 'ESC_INDEX',
        value: DroneCanParamValue.integer(2),
        defaultValue: DroneCanParamValue.integer(3),
        minValue: 0,
        maxValue: 5,
      )
      ..parameters[1] = const DroneCanParameter(
        index: 1,
        name: 'ESC_DIRECTION',
        value: DroneCanParamValue.integer(1),
        defaultValue: DroneCanParamValue.integer(1),
      );

    await _openDialog(tester, repo);
    await _openConfiguration(tester);

    expect(find.text('ESC_INDEX'), findsOneWidget);
    expect(find.text('ESC_DIRECTION'), findsOneWidget);
    expect(find.text('Integer'), findsNWidgets(2));
    // A value that differs from the default is highlighted, and the default is
    // spelled out next to it.
    expect(find.text('default 3'), findsOneWidget);
  });

  testWidgets('configuration dialog writes an edited value to the node', (
    tester,
  ) async {
    final repo = _FakeRepository()
      ..parameters[0] = const DroneCanParameter(
        index: 0,
        name: 'ESC_INDEX',
        value: DroneCanParamValue.integer(2),
        defaultValue: DroneCanParamValue.integer(3),
        minValue: 0,
        maxValue: 5,
      );

    await _openDialog(tester, repo);
    await _openConfiguration(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit parameter'), findsOneWidget);
    expect(find.text('Min'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repo.setRequests.single.name, equals('ESC_INDEX'));
    expect(
      repo.setRequests.single.value,
      equals(const DroneCanParamValue.integer(4)),
    );
    expect(find.text('Parameter ESC_INDEX updated'), findsOneWidget);
  });

  testWidgets('configuration dialog rejects values outside the bounds', (
    tester,
  ) async {
    final repo = _FakeRepository()
      ..parameters[0] = const DroneCanParameter(
        index: 0,
        name: 'ESC_INDEX',
        value: DroneCanParamValue.integer(2),
        minValue: 0,
        maxValue: 5,
      );

    await _openDialog(tester, repo);
    await _openConfiguration(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Value must be between 0 and 5.'), findsOneWidget);
    expect(repo.setRequests, isEmpty);
    // The edit dialog stays open so the value can be corrected.
    expect(find.text('Edit parameter'), findsOneWidget);
  });

  testWidgets('configuration dialog stores the configuration', (tester) async {
    final repo = _FakeRepository()
      ..parameters[0] = const DroneCanParameter(
        index: 0,
        name: 'ESC_INDEX',
        value: DroneCanParamValue.integer(2),
      );

    await _openDialog(tester, repo);
    await _openConfiguration(tester);

    await _tapAction(tester, 'Store all');

    expect(repo.storeRequests, equals(1));
    expect(find.text('Configuration stored to the node'), findsOneWidget);
  });

  testWidgets(
    'configuration dialog erases the configuration after confirming',
    (tester) async {
      final repo = _FakeRepository()
        ..parameters[0] = const DroneCanParameter(
          index: 0,
          name: 'ESC_INDEX',
          value: DroneCanParamValue.integer(2),
        );

      await _openDialog(tester, repo);
      await _openConfiguration(tester);

      await _tapAction(tester, 'Erase all');

      expect(find.text('Erase configuration'), findsOneWidget);
      expect(repo.eraseRequests, equals(0));

      await _tapInDialog(tester, find.widgetWithText(FilledButton, 'Erase'));

      expect(repo.eraseRequests, equals(1));
      expect(find.text('Configuration erased'), findsOneWidget);
    },
  );

  testWidgets('follows the node registry while it is open', (tester) async {
    final repo = _FakeRepository();
    await _openDialog(tester, repo);
    expect(find.text('1.2'), findsOneWidget);

    // The node was updated and restarted with the new firmware.
    await _publishNodes(tester, repo, [_node.copyWith(swMajor: 2, swMinor: 0)]);

    expect(find.text('2.0'), findsOneWidget);
    expect(find.text('1.2'), findsNothing);
  });

  testWidgets('shows the details as unavailable after the node rebooted', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _openDialog(tester, repo);

    // A firmware upload drops the cached GetNodeInfo; the node is rebooting.
    await _publishNodes(tester, repo, [
      DroneCanNode(
        nodeId: _node.nodeId,
        health: _node.health,
        mode: DroneCanNodeMode.softwareUpdate,
        uptimeSec: 0,
        lastSeen: _node.lastSeen,
      ),
    ]);

    expect(find.text('Details are not available yet.'), findsOneWidget);
  });
}
