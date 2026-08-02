import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/gdl90_service.dart';

part 'gdl90_provider.g.dart';

/// Applies [settings] to the GDL90 [service], routing the first application
/// through [Gdl90Service.start] and every subsequent one through
/// [Gdl90Service.updateConfig]. Keeping this decision in a plain function makes
/// the start-once-vs-update orchestration unit-testable without binding a UDP
/// socket.
///
/// Pass [alreadyStarted] = whether the service has been started before.
Future<void> applyGdl90Settings(
  Gdl90Service service,
  AppSettings settings, {
  required bool alreadyStarted,
}) async {
  if (!alreadyStarted) {
    // First application must go through start(): unlike updateConfig it always
    // schedules the expiry timer and binds the socket, even when the loaded
    // settings equal the service defaults.
    await service.start(
      enabled: settings.gdl90Enabled,
      host: settings.gdl90BindIp,
      port: settings.gdl90UdpPort,
      expirySeconds: settings.gdl90TargetExpirySeconds,
    );
  } else {
    await service.updateConfig(
      enabled: settings.gdl90Enabled,
      host: settings.gdl90BindIp,
      port: settings.gdl90UdpPort,
      expirySeconds: settings.gdl90TargetExpirySeconds,
    );
  }
}

@Riverpod(keepAlive: true)
Gdl90Service gdl90Service(Ref ref) {
  final service = Gdl90Service();

  // Tracks whether the service has already been started. Safe to keep as a
  // closure-local: this provider is keepAlive with no watched dependencies, so
  // build() runs exactly once for the app's lifetime. If it ever gains
  // dependencies, this flag must move into a Notifier to survive rebuilds.
  var started = false;

  Future<void> apply(AsyncValue<AppSettings> settingsAsync) async {
    final s = settingsAsync.value;
    if (s == null) return;

    await applyGdl90Settings(service, s, alreadyStarted: started);
    started = true;
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

  // Bridge the two event sources — a periodic poll (isHeartbeatActive decays
  // to false 10 s after the last heartbeat) and immediate re-emission on each
  // heartbeat — through a single broadcast controller forwarded to the
  // provider stream.
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

  yield* controller.stream;
}
