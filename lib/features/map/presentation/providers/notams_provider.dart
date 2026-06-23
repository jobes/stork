import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../data/repositories/notam_repository.dart';
import '../../domain/models/notam.dart';
import '../../domain/services/notam_service.dart';
import '../../domain/utils/fir_utils.dart';

import '../../../../core/providers/shared_preferences_provider.dart';

part 'notams_provider.g.dart';

@Riverpod(keepAlive: true)
NotamService notamService(Ref ref) {
  return NotamService(ref.watch(notamRepositoryProvider));
}

@riverpod
String? currentFir(Ref ref) {
  // Watch if we have a valid GPS fix
  final hasGpsFix = ref.watch(
    telemetryProvider.select(
      (s) =>
          s.latitude != null &&
          s.longitude != null &&
          s.latitude != 0.0 &&
          s.longitude != 0.0,
    ),
  );

  // Watch routePointsProvider to trigger recalculation when route changes
  ref.watch(routePointsProvider);

  if (!hasGpsFix) {
    return null;
  }

  // Read telemetry coordinates
  final telemetry = ref.read(telemetryProvider);
  final lat = telemetry.latitude!;
  final lon = telemetry.longitude!;

  return FirUtils.getFirForCoordinate(lat, lon);
}

@riverpod
List<Geographic> routePoints(Ref ref) {
  final navigation = ref.watch(navigationProvider).value;
  if (navigation == null || !navigation.isActive) {
    return const [];
  }
  return navigation.points
      .map((p) => Geographic(lat: p.latitude, lon: p.longitude))
      .toList();
}

const _hiddenNotamExpirationsKey = 'hidden_notam_expirations';

@Riverpod(keepAlive: true)
class Notams extends _$Notams {
  @override
  Future<List<Notam>> build() async {
    final currentFir = ref.watch(currentFirProvider);

    // Don't reload notams if point was removed because of goal was reached
    final navigationState = ref.watch(navigationProvider).value;
    final wasAutoAdvanced = navigationState?.wasAutoAdvanced ?? false;
    if (wasAutoAdvanced && state.hasValue) {
      return state.value!;
    }

    final routePoints = ref.watch(routePointsProvider);

    if (currentFir == null && routePoints.isEmpty) {
      return const [];
    }

    final service = ref.watch(notamServiceProvider);

    final List<Notam> fetched;
    if (routePoints.isNotEmpty) {
      fetched = await service.fetchRouteNotams(
        routePoints,
        extraFir: currentFir,
      );
    } else if (currentFir != null) {
      fetched = await service.fetchNotamsForFirs([currentFir]);
    } else {
      fetched = const [];
    }

    final hiddenSet = await _loadAndCleanHiddenNotams();
    if (hiddenSet.isEmpty) {
      return fetched;
    }
    return fetched.where((notam) => !hiddenSet.contains(notam.id)).toList();
  }

  Future<Set<String>> _loadAndCleanHiddenNotams() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final now = DateTime.now();

    final jsonStr = prefs.getString(_hiddenNotamExpirationsKey);
    Map<String, String> expirations = {};

    if (jsonStr != null) {
      try {
        final decoded = json.decode(jsonStr);
        if (decoded is Map) {
          expirations = decoded.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }
      } catch (e) {
        debugPrint('Error parsing hidden NOTAM expirations: $e');
      }
    }

    final originalLength = expirations.length;
    expirations.removeWhere((id, expStr) {
      try {
        final expDate = DateTime.parse(expStr);
        return expDate.isBefore(now);
      } catch (_) {
        return true;
      }
    });

    if (expirations.length != originalLength) {
      await prefs.setString(
        _hiddenNotamExpirationsKey,
        json.encode(expirations),
      );
    }

    return expirations.keys.toSet();
  }

  Future<void> hideNotam(Notam notam) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final now = DateTime.now();

    final jsonStr = prefs.getString(_hiddenNotamExpirationsKey);
    Map<String, String> expirations = {};
    if (jsonStr != null) {
      try {
        final decoded = json.decode(jsonStr);
        if (decoded is Map) {
          expirations = decoded.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }
      } catch (_) {}
    }

    expirations.removeWhere((id, expStr) {
      try {
        return DateTime.parse(expStr).isBefore(now);
      } catch (_) {
        return true;
      }
    });

    expirations[notam.id] = notam.to.toIso8601String();

    await prefs.setString(_hiddenNotamExpirationsKey, json.encode(expirations));

    if (state.hasValue) {
      final currentList = state.value!;
      state = AsyncData(currentList.where((n) => n.id != notam.id).toList());
    }
  }
}
