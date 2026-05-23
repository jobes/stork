import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cannelloni_service_stub.g.dart';

@Riverpod(keepAlive: true)
class CannelloniService extends _$CannelloniService {
  @override
  bool build() {
    // Stub implementation for web/unsupported platforms
    return false;
  }

  @visibleForTesting
  Future<Uint8List> loadOrGenerateUniqueIdForTesting() async {
    return Uint8List(16);
  }
}
