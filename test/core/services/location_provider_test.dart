import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stork/core/services/location_provider.dart';

import '../../helpers/fake_geolocator_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<Position> controller;
  late FakeGeolocatorPlatform fakePlatform;

  setUp(() {
    controller = StreamController<Position>.broadcast();
    fakePlatform = FakeGeolocatorPlatform(controller);
    GeolocatorPlatform.instance = fakePlatform;
  });

  tearDown(() async {
    await controller.close();
  });

  test('geolocatorStreamProvider starts once and exposes one persistent stream '
      'that keeps delivering positions', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Before start() the native stream is not created (lazy start).
    expect(fakePlatform.getPositionStreamCallCount, 0);

    container.read(geolocatorStreamProvider.notifier).start();
    expect(fakePlatform.getPositionStreamCallCount, 1);

    final stream1 = container.read(geolocatorStreamProvider).stream;
    final received = <Position>[];
    final sub = stream1.listen(received.add);
    addTearDown(sub.cancel);

    controller.add(makePosition(lat: 48.0, lon: 17.0));
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1));
    expect(received.single.latitude, 48.0);
    expect(received.single.longitude, 17.0);

    // Re-reading the provider must return the SAME underlying stream and
    // must NOT re-create the native geolocator stream. (Re-creating it on
    // map-state changes is what used to silently kill the phone GPS.)
    final stream2 = container.read(geolocatorStreamProvider).stream;
    expect(identical(stream1, stream2), isTrue);
    expect(fakePlatform.getPositionStreamCallCount, 1);

    // start() is idempotent.
    container.read(geolocatorStreamProvider.notifier).start();
    expect(fakePlatform.getPositionStreamCallCount, 1);

    // Positions keep flowing on the same stream.
    controller.add(makePosition(lat: 48.1, lon: 17.1));
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(2));
    expect(received.last.latitude, 48.1);
  });

  test('setDroneCanActive switches between high-accuracy and low-power modes '
      'and positions keep flowing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(geolocatorStreamProvider.notifier);

    // Switching mode before start() is remembered but creates no stream.
    await notifier.setDroneCanActive(true);
    expect(fakePlatform.getPositionStreamCallCount, 0);

    // start() applies the remembered low-power (DroneCAN) mode.
    notifier.start();
    expect(fakePlatform.getPositionStreamCallCount, 1);
    expect(fakePlatform.settingsLog.single!.accuracy, LocationAccuracy.lowest);
    expect(fakePlatform.settingsLog.single!.distanceFilter, 100000);

    final received = <Position>[];
    final sub = container
        .read(geolocatorStreamProvider)
        .stream
        .listen(received.add);
    addTearDown(sub.cancel);
    controller.add(makePosition(lat: 48.0, lon: 17.0));
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1));

    // Switch back to high-accuracy phone mode -> restart with new settings.
    await notifier.setDroneCanActive(false);
    expect(fakePlatform.getPositionStreamCallCount, 2);
    expect(
      fakePlatform.settingsLog.last!.accuracy,
      LocationAccuracy.bestForNavigation,
    );
    expect(fakePlatform.settingsLog.last!.distanceFilter, 0);

    // Positions keep flowing after the restart.
    controller.add(makePosition(lat: 48.1, lon: 17.1));
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(2));
    expect(received.last.latitude, 48.1);

    // Rapid double switch is serialised and ends in the last requested mode.
    final f1 = notifier.setDroneCanActive(true);
    final f2 = notifier.setDroneCanActive(false);
    await Future.wait([f1, f2]);
    expect(fakePlatform.getPositionStreamCallCount, 4);
    expect(
      fakePlatform.settingsLog.last!.accuracy,
      LocationAccuracy.bestForNavigation,
    );
  });

  test('an OS stream failure is exposed through the provider and a restart '
      'clears it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(geolocatorStreamProvider.notifier);

    notifier.start();
    expect(fakePlatform.getPositionStreamCallCount, 1);
    expect(
      container.read(geolocatorStreamProvider).status,
      isA<GeolocatorStreamOk>(),
    );

    // The OS stream dies: the failure must be exposed through the contract.
    controller.addError(Exception('location service lost'), StackTrace.current);
    await Future<void>.delayed(Duration.zero);
    final failed = container.read(geolocatorStreamProvider).status;
    expect(failed, isA<GeolocatorStreamFailed>());
    expect((failed as GeolocatorStreamFailed).error, isA<Exception>());

    // A restart (e.g. a GPS mode switch) re-subscribes; a fresh position
    // proves the stream delivers again and the healthy status is restored.
    await notifier.setDroneCanActive(true);
    expect(fakePlatform.getPositionStreamCallCount, 2);

    final received = <Position>[];
    final sub = container
        .read(geolocatorStreamProvider)
        .stream
        .listen(received.add);
    addTearDown(sub.cancel);
    controller.add(makePosition(lat: 48.0, lon: 17.0));
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(geolocatorStreamProvider).status,
      isA<GeolocatorStreamOk>(),
    );
    expect(received, hasLength(1));
    expect(received.single.latitude, 48.0);
  });

  test('an OS stream error auto-retries after 5 s and recovers', () {
    fakeAsync((async) {
      // Controller and platform are created inside the fake zone so event
      // delivery and the retry timer are controlled by fakeAsync.
      final ctrl = StreamController<Position>.broadcast();
      addTearDown(ctrl.close);
      final platform = FakeGeolocatorPlatform(ctrl);
      GeolocatorPlatform.instance = platform;

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(geolocatorStreamProvider.notifier);

      notifier.start();
      expect(platform.getPositionStreamCallCount, 1);

      // The OS stream dies: the failure is exposed and a retry is scheduled.
      ctrl.addError(Exception('location lost'), StackTrace.current);
      async.flushMicrotasks();
      expect(
        container.read(geolocatorStreamProvider).status,
        isA<GeolocatorStreamFailed>(),
      );

      // After the 5 s delay the notifier re-subscribes on its own.
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(platform.getPositionStreamCallCount, 2);

      // A fresh position restores the healthy status.
      ctrl.add(makePosition(lat: 48.0, lon: 17.0));
      async.flushMicrotasks();
      expect(
        container.read(geolocatorStreamProvider).status,
        isA<GeolocatorStreamOk>(),
      );
    });
  });
}
