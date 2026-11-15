import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
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
  return catalogs.selectLocations([
    ?position,
    ...route,
  ], isCurrent: () => current);
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

const _hiddenNotamExpirationsKey = 'hidden_notam_expirations';

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
    final prefs = await owner.read(sharedPreferencesProvider.future);
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
      final hidden = prefs.getString(_hiddenNotamExpirationsKey);
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
    String? hiddenExpirations,
    DateTime now,
  ) {
    final hidden = _hiddenNotams(hiddenExpirations, now);
    return notams.where((notam) {
      final end = notam.to;
      return notam.type != 'NOTAMC' &&
          (end == null || end.isAfter(now)) &&
          !hidden.containsKey(notam.key) &&
          !hidden.containsKey(notam.id);
    }).toList();
  }

  Map<String, String> _hiddenNotams(String? encoded, DateTime now) {
    if (encoded == null) return {};
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return {
          for (final MapEntry(:key, :value) in decoded.entries)
            if (value is String &&
                (value == 'PERM' ||
                    DateTime.tryParse(value)?.isAfter(now) == true))
              key: value,
        };
      }
    } on FormatException catch (error) {
      debugPrint('Invalid saved NOTAM expirations: ${error.message}');
    }
    return {};
  }

  Future<bool> hideNotam(Notam notam) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (!ref.mounted) return false;
    final hidden = _hiddenNotams(
      prefs.getString(_hiddenNotamExpirationsKey),
      clock.now(),
    );
    hidden[notam.key] = notam.to?.toIso8601String() ?? 'PERM';
    final saved = await prefs.setString(
      _hiddenNotamExpirationsKey,
      jsonEncode(hidden),
    );
    if (!saved || !ref.mounted) return false;
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
