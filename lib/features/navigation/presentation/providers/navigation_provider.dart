import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/navigation_repository.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/navigation_point.dart';
import '../../domain/models/navigation_state.dart';

export '../../domain/models/navigation_point.dart';
export '../../domain/models/navigation_state.dart';
export '../../domain/models/navigation_leg.dart';
export '../../domain/models/navigation_calculations.dart';

part 'navigation_provider.g.dart';

@Riverpod(keepAlive: true)
void navigationAutoAdvance(Ref ref) {
  ref.listen(
    telemetryProvider.select(
      (s) => (
        latitude: s.latitude,
        longitude: s.longitude,
        groundSpeed: s.groundSpeed,
        isFlying: s.isFlying,
      ),
    ),
    (previous, next) {
      Future.microtask(() {
        if (ref.mounted) {
          final telemetry = ref.read(telemetryProvider);
          ref.read(navigationProvider.notifier).checkAutoAdvance(telemetry);
        }
      });
    },
  );
}

@Riverpod(keepAlive: true)
class NavigationNotifier extends _$NavigationNotifier {
  bool _isAutoAdvancing = false;

  @override
  FutureOr<NavigationState> build() async {
    ref.read(navigationAutoAdvanceProvider);

    final repository = await ref.watch(navigationRepositoryProvider.future);
    return repository.loadNavigationState();
  }

  void checkAutoAdvance(TelemetryState telemetry) {
    if (_isAutoAdvancing) return;
    if (state.isLoading || state.hasError) return;
    final navState = state.value;
    if (navState == null || !navState.isActive || navState.points.isEmpty) {
      return;
    }

    if (telemetry.latitude == null ||
        telemetry.longitude == null ||
        telemetry.latitude == 0.0 ||
        telemetry.longitude == 0.0) {
      return;
    }

    final settingsAsync = ref.read(appSettingsProvider);
    if (settingsAsync.isLoading || settingsAsync.hasError) return;
    final settings = settingsAsync.value;
    if (settings == null) return;

    final useRealSpeed =
        telemetry.isFlying &&
        telemetry.groundSpeed != null &&
        telemetry.groundSpeed! > 0;
    final activeSpeedMs = useRealSpeed
        ? telemetry.groundSpeed!
        : settings.averageSpeed;

    if (activeSpeedMs <= 0) return;

    double accumulatedDistance = 0.0;
    double lastLat = telemetry.latitude!;
    double lastLon = telemetry.longitude!;
    int removeCount = 0;

    for (final p in navState.points) {
      accumulatedDistance += p.distanceTo(lastLat, lastLon);
      final timeToPointSecs = accumulatedDistance / activeSpeedMs;
      if (timeToPointSecs <= 60.0) {
        removeCount++;
        lastLat = p.latitude;
        lastLon = p.longitude;
      } else {
        break;
      }
    }

    if (removeCount > 0) {
      _isAutoAdvancing = true;
      removePoints(removeCount, isAutoAdvance: true)
          .then((_) {
            _isAutoAdvancing = false;
          })
          .catchError((_) {
            _isAutoAdvancing = false;
          });
    }
  }

  Future<void> _save(NavigationState stateVal) async {
    final repository = await ref.read(navigationRepositoryProvider.future);
    await repository.saveNavigationState(stateVal);
  }

  Future<void> addPoint(NavigationPoint point) async {
    final current = state.value ?? const NavigationState();
    final isFirst = current.points.isEmpty;
    final updatedPoints = [...current.points, point];
    final updated = current.copyWith(
      points: updatedPoints,
      isActive: isFirst ? true : current.isActive,
      wasAutoAdvanced: false,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> removePoints(int count, {bool isAutoAdvance = false}) async {
    final current = state.value ?? const NavigationState();
    if (count <= 0 || count > current.points.length) return;
    final updatedPoints = List<NavigationPoint>.from(current.points)
      ..removeRange(0, count);
    final updated = current.copyWith(
      points: updatedPoints,
      isActive: updatedPoints.isEmpty ? false : current.isActive,
      wasAutoAdvanced: isAutoAdvance,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> removePoint(int index) async {
    final current = state.value ?? const NavigationState();
    if (index < 0 || index >= current.points.length) return;
    final updatedPoints = List<NavigationPoint>.from(current.points)
      ..removeAt(index);
    final updated = current.copyWith(
      points: updatedPoints,
      isActive: updatedPoints.isEmpty ? false : current.isActive,
      wasAutoAdvanced: false,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> reorderPoints(int oldIndex, int newIndex) async {
    final current = state.value ?? const NavigationState();
    final updatedPoints = List<NavigationPoint>.from(current.points);
    if (oldIndex < 0 || oldIndex >= updatedPoints.length) return;
    if (newIndex < 0 || newIndex > updatedPoints.length) return;

    final item = updatedPoints.removeAt(oldIndex);
    updatedPoints.insert(newIndex, item);

    final updated = current.copyWith(
      points: updatedPoints,
      wasAutoAdvanced: false,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> clearNavigation() async {
    const updated = NavigationState(
      points: [],
      isActive: false,
      wasAutoAdvanced: false,
    );
    state = const AsyncData(updated);
    await _save(updated);
  }

  Future<void> toggleActive() async {
    final current = state.value ?? const NavigationState();
    final updated = current.copyWith(
      isActive: !current.isActive,
      wasAutoAdvanced: false,
    );
    state = AsyncData(updated);
    await _save(updated);
  }
}
