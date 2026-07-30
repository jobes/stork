import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/gdl90_service.dart';

part 'gdl90_provider.g.dart';

@Riverpod(keepAlive: true)
Gdl90Service gdl90Service(Ref ref) {
  final service = Gdl90Service();

  final settings = ref.read(appSettingsProvider).value;
  if (settings != null) {
    // Fire-and-forget start; errors are logged inside the service
    service.start(
      enabled: settings.gdl90Enabled,
      host: settings.gdl90BindIp,
      port: settings.gdl90UdpPort,
      expirySeconds: settings.gdl90TargetExpirySeconds,
    );
  }

  ref.listen(appSettingsProvider, (prev, next) {
    final s = next.value;
    if (s != null) {
      // Fire-and-forget with error logging; ref.listen callback cannot be async
      service
          .updateConfig(
            enabled: s.gdl90Enabled,
            host: s.gdl90BindIp,
            port: s.gdl90UdpPort,
            expirySeconds: s.gdl90TargetExpirySeconds,
          )
          .catchError((e, st) {
            debugPrint('[Gdl90Provider] updateConfig failed: $e\n$st');
          });
    }
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

@riverpod
Stream<bool> gdl90HeartbeatActive(Ref ref) async* {
  final service = ref.watch(gdl90ServiceProvider);

  yield service.isHeartbeatActive;

  final controller = StreamController<bool>();

  void checkAndEmit() {
    if (!controller.isClosed) {
      controller.add(service.isHeartbeatActive);
    }
  }

  final timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => checkAndEmit(),
  );
  final sub = service.heartbeatStream.listen((_) => checkAndEmit());

  ref.onDispose(() {
    timer.cancel();
    sub.cancel();
    controller.close();
  });

  await for (final status in controller.stream) {
    yield status;
  }
}

