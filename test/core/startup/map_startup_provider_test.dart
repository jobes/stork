import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/startup/map_startup_provider.dart';

void main() {
  test('both preparation and render stalls end with a retryable failure', () {
    fakeAsync((time) {
      final container = ProviderContainer();
      final gate = container.read(mapStartupProvider.notifier);
      gate.start();
      time.elapse(MapStartup.preparationBudget);
      expect(container.read(mapStartupProvider).failed, isTrue);
      gate.start();
      final attempt = container.read(mapStartupProvider).attempt;
      gate.rendering(attempt);
      time.elapse(MapStartup.renderingBudget);
      expect(container.read(mapStartupProvider).failed, isTrue);
      gate.ready(attempt);
      expect(container.read(mapStartupProvider).failed, isTrue);
      container.dispose();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('late callbacks cannot fail or release a newer attempt', () {
    fakeAsync((time) {
      final container = ProviderContainer();
      final gate = container.read(mapStartupProvider.notifier);
      gate.start();
      final old = container.read(mapStartupProvider).attempt;
      gate.start();
      final current = container.read(mapStartupProvider).attempt;
      gate.ready(old);
      gate.fail(old, StateError('old map'));
      expect(
        container.read(mapStartupProvider).phase,
        MapStartupPhase.preparing,
      );
      gate.rendering(current);
      gate.ready(current);
      gate.fail(current, StateError('late tile error'));
      time.elapse(const Duration(minutes: 1));
      expect(container.read(mapStartupProvider).ready, isTrue);
      container.dispose();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('a rendered frame lets the rendering deadline reveal the map', () {
    fakeAsync((time) {
      final container = ProviderContainer();
      final gate = container.read(mapStartupProvider.notifier);
      gate.start();
      final attempt = container.read(mapStartupProvider).attempt;
      gate.rendering(attempt);
      gate.frameRendered(attempt);
      time.elapse(MapStartup.renderingBudget);
      final state = container.read(mapStartupProvider);
      expect(state.ready, isTrue);
      expect(state.failed, isFalse);
      container.dispose();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('a frame cannot skip the preparation deadline', () {
    fakeAsync((time) {
      final container = ProviderContainer();
      final gate = container.read(mapStartupProvider.notifier);
      gate.start();
      gate.frameRendered(container.read(mapStartupProvider).attempt);
      time.elapse(MapStartup.preparationBudget);
      expect(container.read(mapStartupProvider).failed, isTrue);
      container.dispose();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('a frame from an older attempt cannot reveal a newer attempt', () {
    fakeAsync((time) {
      final container = ProviderContainer();
      final gate = container.read(mapStartupProvider.notifier);
      gate.start();
      final old = container.read(mapStartupProvider).attempt;
      gate.start();
      final current = container.read(mapStartupProvider).attempt;
      gate.rendering(current);
      gate.frameRendered(old);
      time.elapse(MapStartup.renderingBudget);
      expect(container.read(mapStartupProvider).failed, isTrue);
      container.dispose();
      expect(time.pendingTimers, isEmpty);
    });
  });
}
