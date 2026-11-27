import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'startup_timing.dart';

part 'map_startup_provider.g.dart';

enum MapStartupPhase { preparing, rendering, ready, failed }

class MapStartupState {
  const MapStartupState({
    this.attempt = 0,
    this.phase = MapStartupPhase.preparing,
  });
  final int attempt;
  final MapStartupPhase phase;
  bool get ready => phase == MapStartupPhase.ready;
  bool get failed => phase == MapStartupPhase.failed;
}

/// A bounded, attempt-scoped gate. A late callback can never unlock a retry.
@Riverpod(keepAlive: true)
class MapStartup extends _$MapStartup {
  static const preparationBudget = Duration(seconds: 15);
  static const renderingBudget = Duration(seconds: 15);
  Timer? _deadline;
  int? _frameAttempt;

  @override
  MapStartupState build() {
    ref.onDispose(() => _deadline?.cancel());
    return const MapStartupState();
  }

  void start() {
    _deadline?.cancel();
    _frameAttempt = null;
    state = MapStartupState(attempt: state.attempt + 1);
    _arm(preparationBudget);
    startupMilestone('Preparation started');
  }

  /// Records that the native renderer produced a frame for [attempt]. Remote
  /// tiles can keep the map from turning idle, so the rendering deadline
  /// reveals this rendered map instead of failing when the deadline expires.
  void frameRendered(int attempt) {
    if (state.attempt != attempt || state.ready || state.failed) return;
    if (_frameAttempt == attempt) return;
    _frameAttempt = attempt;
    startupMilestone('Map frame rendered');
  }

  void rendering(int attempt) {
    if (state.attempt != attempt || state.phase != MapStartupPhase.preparing) {
      return;
    }
    state = MapStartupState(attempt: attempt, phase: MapStartupPhase.rendering);
    _arm(renderingBudget);
    startupMilestone('Map mounted');
  }

  void ready(int attempt) {
    if (state.attempt != attempt || state.ready || state.failed) return;
    _deadline?.cancel();
    state = MapStartupState(attempt: attempt, phase: MapStartupPhase.ready);
    startupMilestone('Map ready');
  }

  void fail(int attempt, Object error) {
    if (state.attempt != attempt || state.ready || state.failed) return;
    _deadline?.cancel();
    state = MapStartupState(attempt: attempt, phase: MapStartupPhase.failed);
    startupMilestone('Startup failed: $error');
  }

  void _arm(Duration budget) {
    _deadline?.cancel();
    final attempt = state.attempt;
    _deadline = Timer(budget, () {
      if (state.attempt == attempt &&
          state.phase == MapStartupPhase.rendering &&
          _frameAttempt == attempt) {
        _deadline = null;
        state = MapStartupState(attempt: attempt, phase: MapStartupPhase.ready);
        startupMilestone('Map revealed at deadline');
        return;
      }
      fail(
        attempt,
        TimeoutException('Initial map ${state.phase.name}', budget),
      );
    });
  }
}
