import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StartupTask { notams, airspaces, weather, radar, catalog }

final deferredStartupTasksProvider = Provider<DeferredStartupTasks>((ref) {
  final tasks = DeferredStartupTasks();
  ref.onDispose(tasks.dispose);
  return tasks;
});

/// Only the application shell holds these gates. Standalone pages/providers
/// retain their normal behavior (including tests and embedded previews).
class DeferredStartupTasks {
  final _gates = <StartupTask, Completer<void>>{};
  final _timers = <Timer>[];
  bool _released = false;

  void hold() {
    if (_released || _gates.isNotEmpty) return;
    for (final task in StartupTask.values) {
      _gates[task] = Completer<void>();
    }
  }

  Future<void> waitFor(StartupTask task) =>
      _gates[task]?.future ?? Future<void>.value();

  /// Start independent refresh groups gradually after the prepared UI has
  /// actually painted. A slow or failed group cannot block the next group.
  void releaseAfterFirstFrame() {
    if (_released) return;
    _released = true;
    for (final task in StartupTask.values) {
      _timers.add(
        Timer(Duration(seconds: task.index + 1), () {
          final gate = _gates[task];
          if (gate != null && !gate.isCompleted) gate.complete();
        }),
      );
    }
  }

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final gate in _gates.values) {
      if (!gate.isCompleted) gate.complete();
    }
  }
}
