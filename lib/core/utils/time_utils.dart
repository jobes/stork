import 'dart:core';

/// Global stopwatch to measure the real uptime of the application from its start.
/// This stopwatch is explicitly started at the very beginning of the `main()` function
/// to guarantee accurate, monotonic time measurement across the entire app lifetime.
final Stopwatch appStopwatch = Stopwatch();

extension DurationFormatter on Duration {
  String toHMSString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    } else {
      return '$minutesStr:$secondsStr';
    }
  }
}

