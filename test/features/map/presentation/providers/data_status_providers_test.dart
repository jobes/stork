import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/presentation/providers/airspace_data_status_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/ogn_connection_provider.dart';

void main() {
  group('AirspaceDataStatus', () {
    test('tracks failed FIRs and clears them on success or prune', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(airspaceDataStatusProvider.notifier);

      notifier.markFailure('LZBB');
      notifier.markFailure('LKAA');
      expect(
        container.read(airspaceDataStatusProvider).failedFirs,
        equals({'LZBB', 'LKAA'}),
      );

      notifier.markSuccess('LZBB');
      expect(
        container.read(airspaceDataStatusProvider).failedFirs,
        equals({'LKAA'}),
      );

      notifier.prune({'LZBB'});
      expect(container.read(airspaceDataStatusProvider).hasError, isFalse);
    });

    test('compares states by value so equal sets do not notify', () {
      const a = AirspaceDataStatusState(failedFirs: {'LZBB', 'LKAA'});
      const b = AirspaceDataStatusState(failedFirs: {'LKAA', 'LZBB'});

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(const AirspaceDataStatusState())));
    });
  });

  group('OgnConnected', () {
    test('starts disconnected and updates the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(ognConnectedProvider), isFalse);

      container.read(ognConnectedProvider.notifier).setConnected(true);
      expect(container.read(ognConnectedProvider), isTrue);

      container.read(ognConnectedProvider.notifier).setConnected(false);
      expect(container.read(ognConnectedProvider), isFalse);
    });
  });
}
