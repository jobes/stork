import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Opens a sensors_plus native channel only after sampling setup succeeds.
/// The plugin's convenience API does not await this native configuration call.
/// Web uses the plugin's browser implementation instead of method channels.
Stream<T> deviceSensorEvents<T>({
  required String channel,
  required String samplingMethod,
  required T Function(List<double> values) decode,
  required Stream<T> Function() browserEvents,
}) async* {
  if (kIsWeb) {
    yield* browserEvents();
    return;
  }
  await const MethodChannel('dev.fluttercommunity.plus/sensors/method')
      .invokeMethod<void>(
        samplingMethod,
        SensorInterval.normalInterval.inMicroseconds,
      );
  yield* EventChannel('dev.fluttercommunity.plus/sensors/$channel')
      .receiveBroadcastStream()
      .map((dynamic event) => decode((event as List).cast<double>()));
}

/// A sensor can appear, disappear, fail or silently stop on any platform.
/// Null means unavailable; successful data always supersedes that fallback.
/// Retrying never blocks app startup and stops when the last listener leaves.
class RecoveringSensorStream<T> {
  RecoveringSensorStream(
    this.connect, {
    this.retryDelay = const Duration(seconds: 5),
    this.silenceTimeout = const Duration(seconds: 10),
  }) {
    _events = StreamController<T?>.broadcast(onListen: _start, onCancel: _stop);
  }

  final Stream<T> Function() connect;
  final Duration retryDelay;
  final Duration silenceTimeout;
  late final StreamController<T?> _events;
  Stream<T?> get stream => _events.stream;
  StreamSubscription<T>? _subscription;
  Future<void> _cancellation = Future.value();
  Timer? _retry;
  Timer? _watchdog;
  Timer? _cancelDeadline;
  Completer<void>? _cancelCompletion;
  int _generation = 0;
  bool _disposed = false;

  bool _current(int generation) =>
      !_disposed && _events.hasListener && generation == _generation;

  void _start() {
    final generation = ++_generation;
    // Cancellation may have begun while there were no listeners and therefore
    // no deadline. Bound that existing wait as soon as a consumer returns.
    if (_cancelCompletion != null && _cancelDeadline == null) {
      _cancelDeadline = Timer(retryDelay, _finishCancellation);
    }
    _events.add(null);
    unawaited(_subscribe(generation));
  }

  Future<void> _subscribe(int generation) => _cancellation.then((_) {
    if (!_current(generation)) return;
    try {
      _watch(generation);
      final subscription = connect().listen(
        (event) {
          if (!_current(generation)) return;
          _watch(generation);
          _events.add(event);
        },
        onError: (Object _, StackTrace _) => _lost(generation),
        onDone: () => _lost(generation),
      );
      if (_current(generation)) {
        _subscription = subscription;
      } else {
        _cancel(subscription);
      }
    } catch (_) {
      _lost(generation);
    }
  });

  void _watch(int generation) {
    _watchdog?.cancel();
    _watchdog = Timer(silenceTimeout, () => _lost(generation));
  }

  void _lost(int generation) {
    if (!_current(generation)) return;
    final next = ++_generation;
    _watchdog?.cancel();
    _events.add(null);
    _cancel(_subscription);
    _subscription = null;
    _retry?.cancel();
    _retry = Timer(retryDelay, () => unawaited(_subscribe(next)));
  }

  void _cancel(StreamSubscription<T>? subscription) {
    if (subscription == null) return;
    _cancellation = _cancellation.then((_) {
      final completion = Completer<void>();
      _cancelCompletion = completion;
      void finish() {
        if (identical(_cancelCompletion, completion)) {
          _finishCancellation();
        } else if (!completion.isCompleted) {
          completion.complete();
        }
      }

      if (!_disposed && _events.hasListener) {
        // A removed device may never complete cancellation.
        _cancelDeadline = Timer(retryDelay, finish);
      }
      try {
        subscription.cancel().then(
          (_) => finish(),
          onError: (Object _) => finish(),
        );
      } catch (_) {
        finish();
      }
      return completion.future;
    });
  }

  void _finishCancellation() {
    _cancelDeadline?.cancel();
    _cancelDeadline = null;
    final completion = _cancelCompletion;
    _cancelCompletion = null;
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  void _stop() {
    ++_generation;
    _retry?.cancel();
    _watchdog?.cancel();
    _finishCancellation();
    _cancel(_subscription);
    _subscription = null;
  }

  void dispose() {
    _disposed = true;
    _stop();
    unawaited(_events.close());
  }
}
