import '../../../../core/startup/deferred_startup_tasks.dart';

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../offline_maps/presentation/providers/offline_maps_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../data/repositories/notam_catalog_repository.dart';
import '../../data/repositories/notam_repository.dart';
import '../../domain/models/notam.dart';
import '../../domain/repositories/notam_repository.dart';

part 'notams_provider.g.dart';

const _selectionDistanceMeters = 10 * 1852.0;

@riverpod
Future<Set<String>> notamLocations(Ref ref) {
  final navigation = ref.watch(navigationProvider).value;
  final route = [
    if (navigation != null && navigation.isActive)
      for (final point in navigation.points)
        Geographic(lat: point.latitude, lon: point.longitude),
  ];
  final telemetry = ref.read(telemetryProvider);
  final position = _gpsPosition(telemetry.latitude, telemetry.longitude);
  ref.listen(telemetryProvider.select((s) => (s.latitude, s.longitude)), (
    _,
    next,
  ) {
    final latest = _gpsPosition(next.$1, next.$2);
    if (position == null || latest == null) {
      if (position != latest) ref.invalidateSelf();
    } else if (GeoUtils.distanceBetween(
          position.lat,
          position.lon,
          latest.lat,
          latest.lon,
        ) >=
        _selectionDistanceMeters) {
      ref.invalidateSelf();
    }
  });
  if (position == null && route.isEmpty) {
    return Future.value(const <String>{});
  }

  final catalogs = ref.watch(notamCatalogRepositoryProvider);
  ref.listen(offlineMapsProvider.select((state) => state.downloadDate), (
    _,
    date,
  ) {
    if (date != null) ref.invalidateSelf();
  });

  var current = true;
  ref.onDispose(() => current = false);
  final deferred = ref.read(deferredStartupTasksProvider);
  return () async {
    await deferred.waitFor(StartupTask.notams);
    if (!current) return <String>{};
    return catalogs.selectLocations([
      ?position,
      ...route,
    ], isCurrent: () => current);
  }();
}

Geographic? _gpsPosition(double? latitude, double? longitude) {
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180 ||
      (latitude == 0 && longitude == 0)) {
    return null;
  }
  return Geographic(lat: latitude, lon: longitude);
}

@riverpod
class Notams extends _$Notams {
  bool _forceNextRefresh = false;

  void refresh() {
    _forceNextRefresh = true;
    if (ref.read(notamLocationsProvider).hasError) {
      ref.invalidate(notamLocationsProvider);
    }
    ref.invalidateSelf();
  }

  @override
  Future<NotamFetchResult> build() async {
    final owner = ref;
    final repository = owner.watch(notamRepositoryProvider);
    final locationsFuture = owner.watch(notamLocationsProvider.future);

    var current = true;
    Timer? expiryTimer;
    Timer? refreshTimer;
    owner.onDispose(() {
      current = false;
      expiryTimer?.cancel();
      refreshTimer?.cancel();
    });

    final locations = await locationsFuture;
    if (!current || locations.isEmpty) return const NotamFetchResult([]);
    await repository.loadHiddenNotams();
    if (!current) return const NotamFetchResult([]);

    final force = _forceNextRefresh;
    _forceNextRefresh = false;
    var result = repository.cachedNotams(locations);
    final needsRefresh =
        force || !(result.nextRefresh?.isAfter(clock.now()) ?? true);
    if (needsRefresh) {
      result = result.copyWith(isRefreshing: true);
    }

    NotamFetchResult visible() {
      final now = clock.now();
      final hidden = repository.hiddenNotamKeys(now);
      final notams = _visibleNotams(result.notams, hidden, now);
      expiryTimer?.cancel();
      final expiry = notams
          .map((notam) => notam.to)
          .nonNulls
          .fold<DateTime?>(
            null,
            (first, end) => first == null || end.isBefore(first) ? end : first,
          );
      if (expiry != null) {
        expiryTimer = Timer(expiry.difference(now), () {
          if (current) state = AsyncData(visible());
        });
      }
      return result.copyWith(notams: notams);
    }

    void scheduleRefresh() {
      if (result.nextRefresh case final next?) {
        refreshTimer = Timer(
          next.difference(clock.now()),
          owner.invalidateSelf,
        );
      }
    }

    final snapshot = visible();
    if (!needsRefresh) {
      scheduleRefresh();
      return snapshot;
    }

    // Publish the cache for the current codes immediately while missing or
    // expired responses load. A new route cancels queued requests for old codes.
    Timer.run(() async {
      if (!current) return;
      try {
        result = await repository.fetchNotamsByLocations(
          locations,
          force: force,
          isCurrent: () => current,
          onProgress: (progress) {
            if (!current) return;
            result = progress.copyWith(isRefreshing: true);
            state = AsyncData(visible());
          },
        );
        if (!current) return;
        state = AsyncData(visible());
        scheduleRefresh();
      } catch (error, stack) {
        if (current) state = AsyncError(error, stack);
      }
    });
    return snapshot;
  }

  List<Notam> _visibleNotams(
    List<Notam> notams,
    Set<String> hidden,
    DateTime now,
  ) {
    return notams.where((notam) {
      final end = notam.to;
      return notam.type != 'NOTAMC' &&
          (end == null || end.isAfter(now)) &&
          !hidden.contains(notam.key) &&
          !hidden.contains(notam.id);
    }).toList();
  }

  Future<bool> hideNotam(Notam notam) async {
    final owner = ref;
    final container = owner.container;
    final repository = owner.read(notamRepositoryProvider);
    await repository.loadHiddenNotams();
    if (!owner.mounted) return false;
    final saved = await repository.hideNotam(notam);
    if (!saved) return false;
    if (!owner.mounted) {
      container.invalidate(notamsProvider);
      return true;
    }
    if (state case AsyncData(:final value)) {
      state = AsyncData(
        value.copyWith(
          notams: value.notams.where((item) => item.key != notam.key).toList(),
        ),
      );
    }
    return true;
  }
}
