import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_source_health_provider.dart';

void main() {
  final now = DateTime.utc(2026, 11, 11, 12);

  bool evaluate({
    bool enabled = true,
    bool anyOnline = false,
    bool everOnline = true,
    bool isFlying = true,
    Duration offlineFor = const Duration(minutes: 1),
  }) {
    return evaluateTrafficSourceUnavailable(
      now: now,
      enabled: enabled,
      anyOnline: anyOnline,
      everOnline: everOnline,
      isFlying: isFlying,
      offlineSince: now.subtract(offlineFor),
    );
  }

  group('evaluateTrafficSourceUnavailable', () {
    test('reports nothing while a source is online', () {
      expect(evaluate(anyOnline: true), isFalse);
    });

    test('reports nothing when no source was ever online', () {
      // A traffic receiver the pilot never configured must not raise a
      // permanent warning.
      expect(evaluate(everOnline: false), isFalse);
    });

    test('reports nothing when all sources are disabled', () {
      expect(evaluate(enabled: false), isFalse);
    });

    test('reports nothing on the ground', () {
      expect(evaluate(isFlying: false), isFalse);
    });

    test('waits for the grace period before reporting', () {
      expect(evaluate(offlineFor: const Duration(seconds: 10)), isFalse);
      expect(evaluate(offlineFor: TrafficSourceHealth.offlineGrace), isTrue);
    });

    test('reports nothing without an offline timestamp', () {
      expect(
        evaluateTrafficSourceUnavailable(
          now: now,
          enabled: true,
          anyOnline: false,
          everOnline: true,
          isFlying: true,
          offlineSince: null,
        ),
        isFalse,
      );
    });
  });
}
