import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../telemetry/presentation/providers/black_box_repository_provider.dart';
import '../../../telemetry/domain/models/time_based_stats.dart';
import '../../data/repositories/aircraft_repository.dart';

import 'package:uuid/uuid.dart';
import '../../domain/models/aircraft.dart';

part 'aircraft_provider.g.dart';

@riverpod
class AircraftState extends _$AircraftState {
  @override
  FutureOr<List<Aircraft>> build() async {
    final repository = await ref.watch(aircraftRepositoryProvider.future);
    return repository.getAircrafts();
  }

  Future<String> createAircraft({
    required String name,
    double initialFlightHours = 0.0,
    int initialFlights = 0,
    String? id,
  }) async {
    final repository = await ref.read(aircraftRepositoryProvider.future);
    final newId = id ?? const Uuid().v4();
    final aircraft = Aircraft(
      id: newId,
      name: name,
      initialFlightHours: initialFlightHours,
      initialFlights: initialFlights,
    );
    await repository.saveAircraft(aircraft);
    ref.invalidateSelf();
    await future;
    return newId;
  }

  Future<void> updateAircraft(Aircraft aircraft) async {
    final repository = await ref.read(aircraftRepositoryProvider.future);
    await repository.saveAircraft(aircraft);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteAircraft(String id) async {
    final repository = await ref.read(aircraftRepositoryProvider.future);
    await repository.deleteAircraft(id);
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<double> aircraftHours(Ref ref, String airplaneId) async {
  if (airplaneId.isEmpty) return 0.0;

  final repository = ref.watch(blackBoxRepositoryProvider);
  final aircrafts = await ref.watch(aircraftStateProvider.future);
  final aircraft = aircrafts.cast<Aircraft?>().firstWhere((a) => a?.id == airplaneId, orElse: () => null);
  final initialHours = aircraft?.initialFlightHours ?? 0.0;
  final initialFlights = aircraft?.initialFlights ?? 0;

  final stats = await repository.getAircraftTimeStats(airplaneId, initialHours: initialHours, initialFlights: initialFlights);
  return stats.totalHours;
}

@riverpod
Future<TimeBasedStats> aircraftStats(Ref ref, String airplaneId) async {
  if (airplaneId.isEmpty) {
    return TimeBasedStats.empty();
  }

  final repository = ref.watch(blackBoxRepositoryProvider);
  final aircrafts = await ref.watch(aircraftStateProvider.future);
  final aircraft = aircrafts.cast<Aircraft?>().firstWhere((a) => a?.id == airplaneId, orElse: () => null);
  final initialHours = aircraft?.initialFlightHours ?? 0.0;
  final initialFlights = aircraft?.initialFlights ?? 0;

  return repository.getAircraftTimeStats(
    airplaneId,
    initialHours: initialHours,
    initialFlights: initialFlights,
  );
}
