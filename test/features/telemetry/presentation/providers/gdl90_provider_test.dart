import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/telemetry/data/gdl90_service.dart';
import 'package:stork/features/telemetry/presentation/providers/gdl90_provider.dart';

/// Records how the service lifecycle is driven without binding a real UDP
/// socket (the real `start`/`updateConfig` would open one).
class _FakeGdl90Service extends Gdl90Service {
  final List<String> calls = [];
  int startCount = 0;
  int updateConfigCount = 0;

  @override
  Future<void> start({
    bool enabled = true,
    String host = '0.0.0.0',
    int port = 4000,
    int expirySeconds = 60,
  }) async {
    startCount++;
    calls.add(
      'start(enabled=$enabled,host=$host,port=$port,expiry=$expirySeconds)',
    );
  }

  @override
  Future<void> updateConfig({
    required bool enabled,
    required String host,
    required int port,
    required int expirySeconds,
  }) async {
    updateConfigCount++;
    calls.add(
      'updateConfig(enabled=$enabled,host=$host,port=$port,expiry=$expirySeconds)',
    );
  }
}

void main() {
  group('applyGdl90Settings - start once, then update config', () {
    test('first application routes through start()', () async {
      final fake = _FakeGdl90Service();

      await applyGdl90Settings(
        fake,
        const AppSettings(
          gdl90Enabled: true,
          gdl90BindIp: '0.0.0.0',
          gdl90UdpPort: 4000,
          gdl90TargetExpirySeconds: 60,
        ),
        alreadyStarted: false,
      );

      expect(fake.startCount, equals(1));
      expect(fake.updateConfigCount, equals(0));
      expect(
        fake.calls.single,
        equals('start(enabled=true,host=0.0.0.0,port=4000,expiry=60)'),
      );
    });

    test('subsequent applications route through updateConfig()', () async {
      final fake = _FakeGdl90Service();

      await applyGdl90Settings(
        fake,
        const AppSettings(gdl90Enabled: true, gdl90UdpPort: 4000),
        alreadyStarted: false,
      );
      await applyGdl90Settings(
        fake,
        const AppSettings(gdl90Enabled: true, gdl90UdpPort: 5000),
        alreadyStarted: true,
      );

      expect(
        fake.startCount,
        equals(1),
        reason: 'start() must run exactly once per service lifetime',
      );
      expect(fake.updateConfigCount, equals(1));
      expect(fake.calls.last, contains('port=5000'));
    });

    test(
      'a disabled service is still started (expiry timer must run)',
      () async {
        final fake = _FakeGdl90Service();

        await applyGdl90Settings(
          fake,
          const AppSettings(gdl90Enabled: false),
          alreadyStarted: false,
        );

        expect(fake.startCount, equals(1));
        expect(fake.calls.single, contains('enabled=false'));
      },
    );
  });

  group('gdl90HeartbeatActiveProvider', () {
    test('emits the current heartbeat state', () async {
      final fake = _FakeGdl90Service();
      final container = ProviderContainer(
        overrides: [gdl90ServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final values = <bool>[];
      final sub = container.listen(
        gdl90HeartbeatActiveProvider,
        (_, next) => values.add(next.value ?? false),
        fireImmediately: true,
      );
      await pumpEventQueue();

      // No heartbeat received yet, so the receiver is inactive.
      expect(values, isNotEmpty);
      expect(values.first, isFalse);

      sub.close();
    });
  });
}
