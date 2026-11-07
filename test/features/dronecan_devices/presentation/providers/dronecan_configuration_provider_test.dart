import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/domain/models/firmware_update_progress.dart';
import 'package:stork/features/dronecan_devices/domain/models/transport_statistics.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node_info_refresh.dart';
import 'package:stork/features/dronecan_devices/domain/repositories/dronecan_node_repository.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_configuration_provider.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_nodes_provider.dart';

class _FakeRepository implements DroneCanNodeRepository {
  /// Parameters served by [watchParameters], in index order.
  List<DroneCanParameter> parameters = [];

  /// Index from which the parameter scan fails.
  int? failFromIndex;

  /// Number of parameter scans started by the notifier.
  int scanRequests = 0;
  final List<({String name, DroneCanParamValue value})> setRequests = [];
  Object? setError;

  int storeRequests = 0;
  int eraseRequests = 0;
  bool storeAccepted = true;
  bool eraseAccepted = true;

  @override
  Future<DroneCanParameter?> getParameterByIndex(int nodeId, int index) async =>
      index < parameters.length ? parameters[index] : null;

  @override
  Stream<List<DroneCanParameter>> watchParameters(int nodeId) async* {
    scanRequests++;
    final read = <DroneCanParameter>[];
    yield const <DroneCanParameter>[];

    for (var index = 0; ; index++) {
      final failingFrom = failFromIndex;
      if (failingFrom != null && index >= failingFrom) {
        throw StateError('index $index unavailable');
      }
      if (index >= parameters.length) return;

      read.add(parameters[index]);
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
    final error = setError;
    if (error != null) throw error;
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

  @override
  Future<DroneCanNodeInfoRefresh> refreshNodeInfo() async =>
      const DroneCanNodeInfoRefresh(requested: 0, answered: 0);

  @override
  Stream<List<DroneCanNode>> watchNodes() => const Stream.empty();

  @override
  Future<bool> restartNode(int nodeId) async => true;

  @override
  Future<TransportStatistics> getTransportStats(int nodeId) async {
    throw UnimplementedError();
  }

  @override
  Stream<FirmwareUpdateProgress> updateFirmware(
    int nodeId,
    String fileName,
    Uint8List firmware,
  ) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}

const _parameter = DroneCanParameter(
  index: 3,
  name: 'ESC_INDEX',
  value: DroneCanParamValue.integer(2),
  defaultValue: DroneCanParamValue.integer(3),
  minValue: 0,
  maxValue: 10,
);

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;

  DroneCanConfigurationState stateOf() =>
      container.read(droneCanConfigurationProvider(7));

  DroneCanConfigurationNotifier notifierOf() =>
      container.read(droneCanConfigurationProvider(7).notifier);

  setUp(() {
    repository = _FakeRepository();
    container = ProviderContainer(
      overrides: [droneCanNodeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    // Keep the auto-dispose provider alive for the whole test.
    container.listen(droneCanConfigurationProvider(7), (_, _) {});
  });

  test('scans parameters until the node reports no further one', () async {
    repository.parameters = const [
      DroneCanParameter(
        index: 0,
        name: 'A',
        value: DroneCanParamValue.integer(1),
      ),
      _parameter,
    ];

    await notifierOf().refresh();

    expect(repository.scanRequests, equals(1));
    final state = stateOf();
    expect(state.status, equals(DroneCanConfigurationStatus.ready));
    expect(
      state.parameters.map((parameter) => parameter.name),
      equals(['A', 'ESC_INDEX']),
    );
    expect(state.parameters.last.isModified, isTrue);
    expect(state.error, isNull);
  });

  test('keeps the parameters read before a scan failure', () async {
    repository.parameters = const [
      DroneCanParameter(
        index: 0,
        name: 'A',
        value: DroneCanParamValue.integer(1),
      ),
      _parameter,
    ];
    repository.failFromIndex = 1;

    await notifierOf().refresh();

    final state = stateOf();
    expect(state.parameters.map((parameter) => parameter.name), equals(['A']));
    expect(state.status, equals(DroneCanConfigurationStatus.ready));
    expect(state.error, isNotNull);
  });

  test('fails when the first parameter cannot be read', () async {
    repository.failFromIndex = 0;

    await notifierOf().refresh();

    final state = stateOf();
    expect(state.status, equals(DroneCanConfigurationStatus.failed));
    expect(state.hasFailed, isTrue);
    expect(state.parameters, isEmpty);
  });

  test('applies a new value and keeps the node metadata', () async {
    repository.parameters = const [_parameter];
    await notifierOf().refresh();

    final updated = await notifierOf().setParameterValue(
      stateOf().parameters.single,
      const DroneCanParamValue.integer(7),
    );

    expect(updated.isSuccess, isTrue);
    expect(repository.setRequests.single.name, equals('ESC_INDEX'));
    expect(
      repository.setRequests.single.value,
      equals(const DroneCanParamValue.integer(7)),
    );

    final parameter = stateOf().parameters.single;
    expect(parameter.value, equals(const DroneCanParamValue.integer(7)));
    expect(parameter.defaultValue, equals(const DroneCanParamValue.integer(3)));
    expect(parameter.minValue, equals(0));
    expect(parameter.maxValue, equals(10));
    expect(parameter.isModified, isTrue);
  });

  test('keeps the previous value when the node rejects it', () async {
    repository.parameters = const [_parameter];
    await notifierOf().refresh();
    repository.setError = StateError('rejected');

    final updated = await notifierOf().setParameterValue(
      stateOf().parameters.single,
      const DroneCanParamValue.integer(7),
    );

    expect(updated.isSuccess, isFalse);
    expect(
      stateOf().parameters.single.value,
      equals(const DroneCanParamValue.integer(2)),
    );
    expect(stateOf().error, isNotNull);
    expect(stateOf().busy, isFalse);
  });

  test('stores and erases the configuration', () async {
    repository.parameters = const [_parameter];
    await notifierOf().refresh();

    expect((await notifierOf().storeAll()).isSuccess, isTrue);
    expect(repository.storeRequests, equals(1));

    repository.eraseAccepted = false;
    expect((await notifierOf().eraseAll()).isSuccess, isFalse);
    expect(stateOf().busy, isFalse);

    repository.eraseAccepted = true;
    final scansBefore = repository.scanRequests;
    expect((await notifierOf().eraseAll()).isSuccess, isTrue);
    expect(repository.eraseRequests, equals(2));
    // Parameter values are re-read after the erase.
    expect(repository.scanRequests, greaterThan(scansBefore));
    expect(stateOf().parameters, hasLength(1));
  });
}
