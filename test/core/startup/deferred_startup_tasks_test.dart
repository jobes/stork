import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/startup/deferred_startup_tasks.dart';

void main() {
  test('no online group starts until the prepared UI has painted', () {
    fakeAsync((time) {
      final tasks = DeferredStartupTasks()..hold();
      final started = <StartupTask>[];
      for (final task in StartupTask.values) {
        tasks.waitFor(task).then((_) => started.add(task));
      }
      time.elapse(const Duration(minutes: 1));
      expect(started, isEmpty);
      tasks.releaseAfterFirstFrame();
      tasks.releaseAfterFirstFrame();
      time.elapse(const Duration(milliseconds: 999));
      expect(started, isEmpty);
      time.elapse(const Duration(milliseconds: 1));
      expect(started, [StartupTask.notams]);
      time.elapse(const Duration(seconds: 4));
      expect(started, StartupTask.values);
      tasks.dispose();
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('standalone providers do not wait for an application shell', () async {
    final tasks = DeferredStartupTasks();
    await tasks.waitFor(StartupTask.weather);
    tasks.dispose();
  });
}
