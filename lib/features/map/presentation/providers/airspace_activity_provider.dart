import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../data/repositories/aup_repository.dart';
import '../../domain/models/airspace_activity_status.dart';
import '../../domain/utils/fir_utils.dart';

part 'airspace_activity_provider.g.dart';

/// Distance in meters to a FIR/country boundary that triggers AUP/UUP
/// pre-fetching of the airspace activity for that FIR.
const double kAirspacePrefetchBufferMeters = 30000.0;

/// How often the aircraft position is re-evaluated against FIR boundaries.
/// Once the evaluation interval elapses, AUP/UUP data for the nearby FIRs is
/// downloaded immediately (there is no additional fetch cooldown).
const Duration kAirspaceEvaluationInterval = Duration(minutes: 1);

/// Holds the loaded AUP/UUP airspace activity map
/// (`Map<String, AupAirspaceActivity>` keyed by openAIP airspace id).
///
/// Subscribes to the telemetry aircraft position and automatically pre-fetches
/// active AUP/UUP data for every FIR whose boundary is within
/// [kAirspacePrefetchBufferMeters] of the aircraft. The position is evaluated
/// at most once per [kAirspaceEvaluationInterval]; when the interval elapses,
/// the data is fetched immediately for every nearby FIR.
///
/// The generated provider keeps the stable name `airspaceActivityProvider`
/// (see `name:` below); the notifier class itself uses the `*Controller`
/// suffix so it does not collide with the `AirspaceActivity` enum in the
/// domain layer.
@Riverpod(keepAlive: true, name: 'airspaceActivityProvider')
class AirspaceActivityController extends _$AirspaceActivityController {
  final Map<String, AupAirspaceActivity> _activities = {};

  /// Airspace ids contributed by each fetched FIR, used to prune activities
  /// when the aircraft leaves the FIR's vicinity.
  final Map<String, Set<String>> _activitiesByFir = {};

  final Set<String> _inflightFirs = {};
  DateTime? _lastEvaluationTime;

  @override
  Map<String, AupAirspaceActivity> build() {
    // Trigger pre-fetch whenever the aircraft position changes.
    ref.listen(
      telemetryProvider.select(
        (s) => (latitude: s.latitude, longitude: s.longitude),
      ),
      (previous, next) {
        _evaluatePreFetch(next.latitude, next.longitude);
      },
    );

    // Evaluate once with the current position (if any) on first build.
    final telemetry = ref.read(telemetryProvider);
    _evaluatePreFetch(telemetry.latitude, telemetry.longitude);

    return _snapshot();
  }

  /// Evaluates the aircraft position against FIR boundaries at most once per
  /// [kAirspaceEvaluationInterval] and triggers an immediate pre-fetch for
  /// every FIR within the 30 km buffer zone. Activities of FIRs the aircraft
  /// has left are pruned on every evaluation.
  void _evaluatePreFetch(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return;
    if (latitude == 0.0 && longitude == 0.0) return;

    final now = clock.now();
    final last = _lastEvaluationTime;
    if (last != null && now.difference(last) < kAirspaceEvaluationInterval) {
      return;
    }
    _lastEvaluationTime = now;

    final firs = FirUtils.firsNearCoordinate(
      latitude,
      longitude,
      bufferMeters: kAirspacePrefetchBufferMeters,
    );
    _pruneStaleActivities(firs);
    for (final fir in firs) {
      _maybeFetchForFir(fir);
    }
  }

  /// Removes activities contributed by FIRs that are no longer within the
  /// pre-fetch buffer, so the map stops highlighting airspaces the aircraft
  /// has left (and the provider state does not grow without bound).
  void _pruneStaleActivities(List<String> nearbyFirs) {
    final nearby = nearbyFirs.toSet();
    var changed = false;
    _activitiesByFir.removeWhere((fir, ids) {
      if (nearby.contains(fir)) return false;
      for (final id in ids) {
        _activities.remove(id);
      }
      changed = true;
      return true;
    });
    if (changed) {
      state = _snapshot();
    }
  }

  Future<void> _maybeFetchForFir(String firIcao) async {
    if (_inflightFirs.contains(firIcao)) return;

    _inflightFirs.add(firIcao);
    try {
      final repository = ref.read(aupRepositoryProvider);
      final activities = await repository.fetchActivitiesForFir(firIcao);
      if (!ref.mounted) return;

      // Replace the FIR's previous activities so entries that disappeared from
      // the AUP (e.g. deactivated by a UUP) no longer linger.
      final previous = _activitiesByFir[firIcao];
      if (previous != null) {
        for (final id in previous) {
          _activities.remove(id);
        }
      }
      final ids = <String>{};
      for (final activity in activities) {
        _activities[activity.airspaceId] = activity;
        ids.add(activity.airspaceId);
      }
      _activitiesByFir[firIcao] = ids;
      state = _snapshot();
    } catch (e) {
      debugPrint(
        'AirspaceActivityController: failed to fetch AUP for $firIcao: $e',
      );
    } finally {
      _inflightFirs.remove(firIcao);
    }
  }

  /// Immutable copy of the current activities map, so consumers can never
  /// mutate the notifier's internal state in place.
  Map<String, AupAirspaceActivity> _snapshot() =>
      Map<String, AupAirspaceActivity>.unmodifiable(Map.of(_activities));
}
