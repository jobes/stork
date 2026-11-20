import 'dart:async';
import 'dart:developer' as developer;

import '../utils/time_utils.dart';

/// Timings are opt-in for release measurements, without normal startup logging.
const _logStartupTimings = bool.fromEnvironment('STORK_STARTUP_TIMINGS');

Future<T> measureStartup<T>(String name, FutureOr<T> Function() prepare) async {
  final task = developer.TimelineTask()..start('Startup: $name');
  final stopwatch = Stopwatch()..start();
  try {
    return await prepare();
  } finally {
    task.finish();
    if (_logStartupTimings) {
      // ignore: avoid_print
      print(
        '[Startup] $name: ${stopwatch.elapsedMilliseconds} ms '
        '(main +${appStopwatch.elapsedMilliseconds} ms)',
      );
    }
  }
}

/// A milestone, measured from Dart main rather than a nested preparation span.
void startupMilestone(String name) {
  developer.Timeline.instantSync('Startup: $name');
  if (_logStartupTimings) {
    // ignore: avoid_print
    print('[Startup] $name (main +${appStopwatch.elapsedMilliseconds} ms)');
  }
}
