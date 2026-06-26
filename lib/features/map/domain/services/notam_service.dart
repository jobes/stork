import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';

import '../models/notam.dart';
import '../repositories/notam_repository.dart';
import '../utils/fir_utils.dart';

class NotamService {
  final NotamRepository _repository;

  NotamService(this._repository);

  Future<List<Notam>> fetchInitialNotams(double lat, double lon) async {
    final currentFir = FirUtils.getFirForCoordinate(lat, lon);
    debugPrint('NOTAMS: Found current FIR: $currentFir');
    if (currentFir == null) return [];
    return _repository.fetchNotamsByFirs([currentFir]);
  }

  Future<List<Notam>> fetchNotamsForFirs(List<String> firs) async {
    return _repository.fetchNotamsByFirs(firs);
  }

  Future<List<Notam>> fetchRouteNotams(
    List<Geographic> routePoints, {
    String? extraFir,
  }) async {
    if (routePoints.isEmpty) return [];

    // 1. Find FIRs for all waypoints and along route segments
    final List<String> routeFirs = [];
    if (extraFir != null) {
      routeFirs.add(extraFir);
    }
    for (final p in routePoints) {
      final fir = FirUtils.getFirForCoordinate(p.lat, p.lon);
      if (fir != null && !routeFirs.contains(fir)) {
        routeFirs.add(fir);
      }
    }

    // 2. Query location-based NOTAMs along the route legs
    final chunkPoints = FirUtils.getRouteChunkPoints(
      routePoints,
      50000.0,
    ); // Chunks of 50km

    final List<Notam> allNotams = [];

    // Fetch FIR NOTAMs and location NOTAMs in parallel
    final Future<List<Notam>> firsFuture = routeFirs.isNotEmpty
        ? _repository.fetchNotamsByFirs(routeFirs)
        : Future.value([]);

    final List<Future<List<Notam>>> chunkFutures = chunkPoints
        .map((p) => _repository.fetchNotamsAroundPoint(p, 50000))
        .toList();

    // Await all parallel requests
    final results = await Future.wait([firsFuture, ...chunkFutures]);

    for (final result in results) {
      allNotams.addAll(result);
    }

    // Deduplicate NOTAMs by ID
    final Map<String, Notam> uniqueNotamsMap = {};
    for (final n in allNotams) {
      uniqueNotamsMap[n.id] = n;
    }

    return uniqueNotamsMap.values.toList();
  }
}
