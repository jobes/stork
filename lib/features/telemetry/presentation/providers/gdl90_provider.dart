import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/gdl90_service.dart';

part 'gdl90_provider.g.dart';

@Riverpod(keepAlive: true)
Gdl90Service gdl90Service(Ref ref) {
  final service = Gdl90Service();
  var started = false;

  Future<void> apply(AsyncValue<AppSettings> settingsAsync) async {
    final s = settingsAsync.value;
    if (s == null) return;

    if (!started) {
      // First application must go through start(): unlike updateConfig it
      // always schedules the expiry timer and binds the socket, even when
      // the loaded settings equal the service defaults.
      started = true;
      await service.start(
        enabled: s.gdl90Enabled,
        host: s.gdl90BindIp,
        port: s.gdl90UdpPort,
        expirySeconds: s.gdl90TargetExpirySeconds,
      );
    } else {
      await service.updateConfig(
        enabled: s.gdl90Enabled,
        host: s.gdl90BindIp,
        port: s.gdl90UdpPort,
        expirySeconds: s.gdl90TargetExpirySeconds,
      );
    }
  }

  // fireImmediately applies settings that are already loaded; if they are
  // still loading, the loading→data transition fires the listener as well,
  // so the service always starts exactly once.
  ref.listen(appSettingsProvider, (prev, next) {
    apply(next).catchError((e, st) {
      debugPrint('[Gdl90Provider] apply failed: $e\n$st');
    });
  }, fireImmediately: true);

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
