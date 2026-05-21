import 'dart:ffi';
import 'package:ffi/ffi.dart';

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
