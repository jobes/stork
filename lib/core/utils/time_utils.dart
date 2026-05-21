import 'dart:core';

/// Global stopwatch to measure the real uptime of the application from its start.
/// This stopwatch is explicitly started at the very beginning of the `main()` function
/// to guarantee accurate, monotonic time measurement across the entire app lifetime.
final Stopwatch appStopwatch = Stopwatch();
