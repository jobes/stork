import 'package:stork/core/native/dronecan/node_status.dart' as protocol;
import 'package:stork/core/native/dronecan/param_get_set.dart' as protocol;

import '../../domain/models/dronecan_node.dart';
import '../../domain/models/dronecan_parameter.dart';

/// Maps a `NodeStatus` health to the domain enum.
DroneCanNodeHealth droneCanNodeHealthFromProtocol(protocol.NodeHealth health) {
  return switch (health) {
    protocol.NodeHealth.ok => DroneCanNodeHealth.ok,
    protocol.NodeHealth.warning => DroneCanNodeHealth.warning,
    protocol.NodeHealth.error => DroneCanNodeHealth.error,
    protocol.NodeHealth.critical => DroneCanNodeHealth.critical,
  };
}

/// Maps a `NodeStatus` mode to the domain enum.
DroneCanNodeMode droneCanNodeModeFromProtocol(protocol.NodeMode mode) {
  return switch (mode) {
    protocol.NodeMode.operational => DroneCanNodeMode.operational,
    protocol.NodeMode.initialization => DroneCanNodeMode.initialization,
    protocol.NodeMode.maintenance => DroneCanNodeMode.maintenance,
    protocol.NodeMode.softwareUpdate => DroneCanNodeMode.softwareUpdate,
    protocol.NodeMode.offline => DroneCanNodeMode.offline,
  };
}

/// Maps a `param.GetSet` value to the domain value.
DroneCanParamValue droneCanParamValueFromProtocol(protocol.ParamValue value) {
  return switch (value.type) {
    protocol.ParamValueType.empty => const DroneCanParamValue.empty(),
    protocol.ParamValueType.integer => DroneCanParamValue.integer(
      value.integerValue!,
    ),
    protocol.ParamValueType.real => DroneCanParamValue.real(value.realValue!),
    protocol.ParamValueType.boolean => DroneCanParamValue.boolean(
      value.booleanValue!,
    ),
    protocol.ParamValueType.string => DroneCanParamValue.string(
      value.stringValue!,
    ),
  };
}

/// Maps a domain value to its `param.GetSet` wire form.
protocol.ParamValue droneCanParamValueToProtocol(DroneCanParamValue value) {
  return switch (value) {
    DroneCanParamEmptyValue() => const protocol.ParamValue.empty(),
    DroneCanParamIntegerValue(:final value) => protocol.ParamValue.integer(
      value,
    ),
    DroneCanParamRealValue(:final value) => protocol.ParamValue.real(value),
    DroneCanParamBooleanValue(:final value) => protocol.ParamValue.boolean(
      value,
    ),
    DroneCanParamStringValue(:final value) => protocol.ParamValue.string(value),
  };
}
