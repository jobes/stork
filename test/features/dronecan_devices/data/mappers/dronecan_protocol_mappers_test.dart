import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/node_status.dart' as protocol;
import 'package:stork/features/dronecan_devices/data/mappers/dronecan_protocol_mappers.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';

void main() {
  test('maps every node health', () {
    expect(
      droneCanNodeHealthFromProtocol(protocol.NodeHealth.ok),
      equals(DroneCanNodeHealth.ok),
    );
    expect(
      droneCanNodeHealthFromProtocol(protocol.NodeHealth.warning),
      equals(DroneCanNodeHealth.warning),
    );
    expect(
      droneCanNodeHealthFromProtocol(protocol.NodeHealth.error),
      equals(DroneCanNodeHealth.error),
    );
    expect(
      droneCanNodeHealthFromProtocol(protocol.NodeHealth.critical),
      equals(DroneCanNodeHealth.critical),
    );
  });

  test('maps every node mode', () {
    expect(
      droneCanNodeModeFromProtocol(protocol.NodeMode.operational),
      equals(DroneCanNodeMode.operational),
    );
    expect(
      droneCanNodeModeFromProtocol(protocol.NodeMode.initialization),
      equals(DroneCanNodeMode.initialization),
    );
    expect(
      droneCanNodeModeFromProtocol(protocol.NodeMode.maintenance),
      equals(DroneCanNodeMode.maintenance),
    );
    expect(
      droneCanNodeModeFromProtocol(protocol.NodeMode.softwareUpdate),
      equals(DroneCanNodeMode.softwareUpdate),
    );
    expect(
      droneCanNodeModeFromProtocol(protocol.NodeMode.offline),
      equals(DroneCanNodeMode.offline),
    );
  });

  test('round-trips every parameter value kind', () {
    const values = <DroneCanParamValue>[
      DroneCanParamValue.empty(),
      DroneCanParamValue.integer(-7),
      DroneCanParamValue.real(1.5),
      DroneCanParamValue.boolean(true),
      DroneCanParamValue.string('GPS'),
    ];

    for (final value in values) {
      expect(
        droneCanParamValueFromProtocol(droneCanParamValueToProtocol(value)),
        equals(value),
      );
    }
  });
}
