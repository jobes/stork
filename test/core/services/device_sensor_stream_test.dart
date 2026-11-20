import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/device_sensor_stream.dart';
import 'package:stork/core/services/location_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('absent device, removal, closed stream and reconnection all retry', () {
    fakeAsync((time) {
      StreamController<int>? device;
      var attempts = 0;
      final source = RecoveringSensorStream<int>(() {
        attempts++;
        final available = device;
        if (available == null) throw MissingPluginException('Not connected');
        return available.stream;
      });
      final values = <int?>[];
      source.stream.listen(values.add);
      time.flushMicrotasks();
      expect(values.last, isNull);
      expect(attempts, 1);
      device = StreamController<int>();
      time.elapse(const Duration(seconds: 5));
      device.add(7);
      time.flushMicrotasks();
      expect(values.last, 7);
      device.addError(PlatformException(code: 'disconnected'));
      time.flushMicrotasks();
      expect(values.last, isNull);
      device.close();
      device = StreamController<int>();
      time.elapse(const Duration(seconds: 5));
      device.add(8);
      time.flushMicrotasks();
      expect(values.last, 8);
      device.close();
      time.flushMicrotasks();
      expect(values.last, isNull);
      device = StreamController<int>();
      time.elapse(const Duration(seconds: 5));
      device.add(9);
      time.flushMicrotasks();
      expect(values.last, 9);
      source.dispose();
      device.close();
      time.flushMicrotasks();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test(
    'silent source expires, reconnects, and stops probing without listeners',
    () {
      fakeAsync((time) {
        final devices = <StreamController<int>>[];
        final source = RecoveringSensorStream<int>(() {
          final device = StreamController<int>();
          devices.add(device);
          return device.stream;
        });
        final values = <int?>[];
        final subscription = source.stream.listen(values.add);
        time.flushMicrotasks();
        devices.single.add(1);
        time.flushMicrotasks();
        time.elapse(const Duration(seconds: 10));
        expect(values.last, isNull);
        time.elapse(const Duration(seconds: 5));
        expect(devices, hasLength(2));
        devices.first.add(999); // Old source cannot overwrite the current one.
        devices.last.add(2);
        time.flushMicrotasks();
        expect(values.last, 2);
        subscription.cancel();
        time.flushMicrotasks();
        time.elapse(const Duration(minutes: 1));
        expect(devices, hasLength(2));
        source.dispose();
        for (final device in devices) {
          device.close();
        }
        time.flushMicrotasks();
        expect(time.pendingTimers, isEmpty);
      });
    },
  );

  test('retries asynchronous initialization stream failures', () {
    fakeAsync((time) {
      var attempts = 0;
      final source = RecoveringSensorStream<int>(() {
        attempts++;
        return Stream.error(MissingPluginException('Initialization'));
      });
      source.stream.listen((_) {});
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 5));
      expect(attempts, 2);
      source.dispose();
      time.flushMicrotasks();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('a removed device cannot hold reconnection in cancellation forever', () {
    fakeAsync((time) {
      final cancellation = Completer<void>();
      final oldDevice = StreamController<int>(
        onCancel: () => cancellation.future,
      );
      final newDevice = StreamController<int>();
      var attempts = 0;
      final source = RecoveringSensorStream<int>(
        () => ++attempts == 1 ? oldDevice.stream : newDevice.stream,
      );
      final values = <int?>[];
      source.stream.listen(values.add);
      time.flushMicrotasks();
      oldDevice.addError(StateError('Device removed'));
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 5));
      expect(cancellation.isCompleted, isFalse);
      expect(attempts, 2);
      newDevice.add(42);
      time.flushMicrotasks();
      expect(values.last, 42);
      source.dispose();
      cancellation.complete();
      oldDevice.close();
      newDevice.close();
      time.flushMicrotasks();
      expect(time.pendingTimers, isEmpty);
    });
  });

  testWidgets(
    'native sensor can appear and reconnect while the same providers stay alive',
    (tester) async {
      var available = false;
      final listens = <String, int>{};
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
        (_) async {
          if (!available) throw MissingPluginException();
          return null;
        },
      );
      for (final name in ['accelerometer', 'magnetometer']) {
        messenger.setMockMethodCallHandler(
          MethodChannel('dev.fluttercommunity.plus/sensors/$name'),
          (call) async {
            if (call.method == 'listen') {
              listens.update(name, (n) => n + 1, ifAbsent: () => 1);
            }
            return null;
          },
        );
      }
      final container = ProviderContainer();
      container.listen(compassStreamProvider, (_, _) {});
      await tester.pump();
      expect(container.read(compassStreamProvider).requireValue, isNull);
      expect(listens, isEmpty);
      available = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      // Orientation and compass share one native acceleration subscription.
      expect(listens, {'accelerometer': 1, 'magnetometer': 1});
      void send(String name, List<double> values) {
        tester.binding.channelBuffers.push(
          'dev.fluttercommunity.plus/sensors/$name',
          const StandardMethodCodec().encodeSuccessEnvelope(values),
          (_) {},
        );
      }

      send('accelerometer', [0, 0, 9.8, 1000000]);
      send('magnetometer', [0, 1, 0, 1000000]);
      await tester.pump();
      expect(container.read(compassStreamProvider).requireValue, isNotNull);
      tester.binding.channelBuffers.push(
        'dev.fluttercommunity.plus/sensors/accelerometer',
        const StandardMethodCodec().encodeErrorEnvelope(code: 'disconnected'),
        (_) {},
      );
      await tester.pump();
      expect(container.read(compassStreamProvider).requireValue, isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(listens['accelerometer'], 2);
      send('accelerometer', [0, 0, 9.8, 2000000]);
      await tester.pump();
      expect(container.read(compassStreamProvider).requireValue, isNull);
      send('magnetometer', [0, 1, 0, 2000000]);
      await tester.pump();
      expect(container.read(compassStreamProvider).requireValue, isNotNull);
      container.dispose();
      await tester.pump();
      await tester.pump();
    },
  );

  testWidgets(
    'missing native backend fails before event-channel registration',
    (tester) async {
      var eventListens = 0;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
        (_) async => throw MissingPluginException(),
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
        (_) async {
          eventListens++;
          return null;
        },
      );
      final errors = <Object>[];
      final subscription = deviceSensorEvents<int>(
        channel: 'accelerometer',
        samplingMethod: 'setAccelerationSamplingPeriod',
        decode: (_) => 1,
        browserEvents: () => throw StateError('Unexpected browser backend'),
      ).listen((_) {}, onError: errors.add);
      await tester.pump();
      expect(errors.single, isA<MissingPluginException>());
      expect(eventListens, 0);
      await tester.runAsync(subscription.cancel);
    },
  );
}
