import 'package:flutter/foundation.dart';

/// Statistics of a single CAN interface reported by a node.
@immutable
class CanInterfaceStatistics {
  const CanInterfaceStatistics({
    required this.framesTx,
    required this.framesRx,
    required this.errors,
  });

  final int framesTx;
  final int framesRx;
  final int errors;
}

/// DroneCAN transport statistics reported by a node
/// (`uavcan.protocol.GetTransportStats`).
@immutable
class TransportStatistics {
  const TransportStatistics({
    required this.transfersTx,
    required this.transfersRx,
    required this.transferErrors,
    required this.canInterfaces,
  });

  final int transfersTx;
  final int transfersRx;
  final int transferErrors;
  final List<CanInterfaceStatistics> canInterfaces;
}
