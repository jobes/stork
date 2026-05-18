import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

abstract interface class DroneCanMessage {
  int get id;
  int get signature;
  bool get isService;
}

abstract interface class DroneCanRequestResponseMessage
    implements DroneCanMessage {
  Uint8List toPayload();
}

final Map<Type, Pointer<Uint8>> _transferIdRegistry = {};

/// Lazily allocates or retrieves the native `uint8_t` transfer ID pointer for a message Type.
Pointer<Uint8> getTransferIdFor(Type type) {
  return _transferIdRegistry.putIfAbsent(
    type,
    () => malloc.allocate<Uint8>(1)..value = 0,
  );
}

/// Safely frees all allocated transfer ID pointers.
void disposeAllTransferIds() {
  for (final ptr in _transferIdRegistry.values) {
    malloc.free(ptr);
  }
  _transferIdRegistry.clear();
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
