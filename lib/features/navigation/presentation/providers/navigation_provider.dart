import 'dart:convert';
import 'dart:math' as math;
import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/domain/models/telemetry_state.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

part 'navigation_provider.g.dart';

class NavigationPoint {
  final double latitude;
  final double longitude;
  final String name;
  final bool isAirport;

  const NavigationPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.isAirport = false,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'isAirport': isAirport,
      };

  factory NavigationPoint.fromJson(Map<String, dynamic> json) => NavigationPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        name: json['name'] as String,
        isAirport: json['isAirport'] as bool? ?? false,
      );

  double distanceTo(double otherLat, double otherLon) {
    const earthRadius = 6371000.0; // in meters
    final dLat = (otherLat - latitude) * math.pi / 180.0;
    final dLon = (otherLon - longitude) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude * math.pi / 180.0) *
            math.cos(otherLat * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
}

class NavigationState {
  final List<NavigationPoint> points;
  final bool isActive;

  const NavigationState({
    this.points = const [],
    this.isActive = false,
  });

  NavigationState copyWith({
    List<NavigationPoint>? points,
    bool? isActive,
  }) {
    return NavigationState(
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'isActive': isActive,
      };

  factory NavigationState.fromJson(Map<String, dynamic> json) => NavigationState(
        points: (json['points'] as List<dynamic>?)
                ?.map((item) => NavigationPoint.fromJson(item))
                .toList() ??
            const [],
        isActive: json['isActive'] as bool? ?? false,
      );
}

class NavigationLeg {
  final NavigationPoint point;
  final double legDistanceMeters;
  final Duration legDuration;
  final double cumulativeDistanceMeters;
  final Duration cumulativeDuration;
  final DateTime? eta;

  const NavigationLeg({
    required this.point,
    required this.legDistanceMeters,
    required this.legDuration,
    required this.cumulativeDistanceMeters,
    required this.cumulativeDuration,
    this.eta,
  });
}

class NavigationCalculations {
  final List<NavigationLeg> legs;
  final double totalDistanceMeters;
  final Duration totalDuration;

  const NavigationCalculations({
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDuration,
  });

  factory NavigationCalculations.calculate({
    required List<NavigationPoint> points,
    required double? currentLatitude,
    required double? currentLongitude,
    required double activeSpeedMs,
    DateTime? now,
  }) {
    if (points.isEmpty ||
        currentLatitude == null ||
        currentLongitude == null ||
        currentLatitude == 0.0 ||
        currentLongitude == 0.0) {
      return const NavigationCalculations(
        legs: [],
        totalDistanceMeters: 0.0,
        totalDuration: Duration.zero,
      );
    }

    final effectiveNow = now ?? clock.now();
    final List<NavigationLeg> computedLegs = [];
    double accumulatedDistance = 0.0;
    double accumulatedSeconds = 0.0;

    double lastLat = currentLatitude;
    double lastLon = currentLongitude;

    for (final p in points) {
      final dist = p.distanceTo(lastLat, lastLon);
      accumulatedDistance += dist;

      final legSecs = activeSpeedMs > 0 ? dist / activeSpeedMs : 0.0;
      accumulatedSeconds += legSecs;

      final cumulativeDuration = Duration(seconds: accumulatedSeconds.round());

      computedLegs.add(
        NavigationLeg(
          point: p,
          legDistanceMeters: dist,
          legDuration: Duration(seconds: legSecs.round()),
          cumulativeDistanceMeters: accumulatedDistance,
          cumulativeDuration: cumulativeDuration,
          eta: effectiveNow.add(cumulativeDuration),
        ),
      );

      lastLat = p.latitude;
      lastLon = p.longitude;
    }

    return NavigationCalculations(
      legs: computedLegs,
      totalDistanceMeters: accumulatedDistance,
      totalDuration: Duration(seconds: accumulatedSeconds.round()),
    );
  }
}

@Riverpod(keepAlive: true)
void navigationAutoAdvance(Ref ref) {
  ref.listen<TelemetryState>(telemetryProvider, (previous, next) {
    Future.microtask(() {
      if (ref.mounted) {
        ref.read(navigationProvider.notifier).checkAutoAdvance(next);
      }
    });
  });
}

@Riverpod(keepAlive: true)
class NavigationNotifier extends _$NavigationNotifier {
  static const _prefsKey = 'navigation_state_json';
  bool _isAutoAdvancing = false;

  @override
  FutureOr<NavigationState> build() async {
    ref.read(navigationAutoAdvanceProvider);

    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return const NavigationState();
    try {
      return NavigationState.fromJson(json.decode(jsonStr));
    } catch (_) {
      return const NavigationState();
    }
  }

  void checkAutoAdvance(TelemetryState telemetry) {
    if (_isAutoAdvancing) return;
    if (state.isLoading || state.hasError) return;
    final navState = state.value;
    if (navState == null || !navState.isActive || navState.points.isEmpty) return;

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

    final useRealSpeed = telemetry.isFlying && telemetry.groundSpeed != null && telemetry.groundSpeed! > 0;
    final activeSpeedMs = useRealSpeed ? telemetry.groundSpeed! : settings.averageSpeed;

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
      removePoints(removeCount).then((_) {
        _isAutoAdvancing = false;
      }).catchError((_) {
        _isAutoAdvancing = false;
      });
    }
  }

  Future<void> _save(NavigationState stateVal) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      _prefsKey,
      json.encode(stateVal.toJson()),
    );
  }

  Future<void> addPoint(NavigationPoint point) async {
    final current = state.value ?? const NavigationState();
    final isFirst = current.points.isEmpty;
    final updatedPoints = [...current.points, point];
    final updated = current.copyWith(
      points: updatedPoints,
      isActive: isFirst ? true : current.isActive,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> removePoints(int count) async {
    final current = state.value ?? const NavigationState();
    if (count <= 0 || count > current.points.length) return;
    final updatedPoints = List<NavigationPoint>.from(current.points)..removeRange(0, count);
    final updated = current.copyWith(
      points: updatedPoints,
      isActive: updatedPoints.isEmpty ? false : current.isActive,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> removePoint(int index) async {
    final current = state.value ?? const NavigationState();
    if (index < 0 || index >= current.points.length) return;
    final updatedPoints = List<NavigationPoint>.from(current.points)..removeAt(index);
    final updated = current.copyWith(
      points: updatedPoints,
      isActive: updatedPoints.isEmpty ? false : current.isActive,
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> reorderPoints(int oldIndex, int newIndex) async {
    final current = state.value ?? const NavigationState();
    final updatedPoints = List<NavigationPoint>.from(current.points);
    if (oldIndex < 0 || oldIndex >= updatedPoints.length) return;
    if (newIndex < 0 || newIndex >= updatedPoints.length) return;
    final item = updatedPoints.removeAt(oldIndex);
    updatedPoints.insert(newIndex, item);
    final updated = current.copyWith(points: updatedPoints);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> clearNavigation() async {
    const updated = NavigationState(points: [], isActive: false);
    state = const AsyncData(updated);
    await _save(updated);
  }

  Future<void> toggleActive() async {
    final current = state.value ?? const NavigationState();
    final updated = current.copyWith(isActive: !current.isActive);
    state = AsyncData(updated);
    await _save(updated);
  }
}
