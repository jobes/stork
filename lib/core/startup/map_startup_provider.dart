import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'startup_timing.dart';

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

final mapStartupProvider = NotifierProvider<MapStartup, MapStartupState>(
  MapStartup.new,
);

/// A bounded, attempt-scoped gate. A late callback can never unlock a retry.
class MapStartup extends Notifier<MapStartupState> {
  static const preparationBudget = Duration(seconds: 15);
  static const renderingBudget = Duration(seconds: 15);
  Timer? _deadline;

  @override
  MapStartupState build() {
    ref.onDispose(() => _deadline?.cancel());
    return const MapStartupState();
  }

  void start() {
    _deadline?.cancel();
    state = MapStartupState(attempt: state.attempt + 1);
    _arm(preparationBudget);
    startupMilestone('Preparation started');
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
    _deadline = Timer(
      budget,
      () => fail(
        attempt,
        TimeoutException('Initial map ${state.phase.name}', budget),
      ),
    );
  }
}
