import 'dart:async';

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
}
