import 'dart:typed_data';

abstract interface class DroneCanMessage {
  int get id;
  int get signature;
  bool get isService;
}

abstract interface class DroneCanRequestResponseMessage
    implements DroneCanMessage {
  Uint8List toPayload();
}

enum DroneCanPriority {
  highest(0),
  high(8),
  medium(16),
  low(24),
  lowest(31);

  final int value;
  const DroneCanPriority(this.value);
}
