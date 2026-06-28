import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/pilot.dart';
import '../../data/repositories/pilot_repository.dart';
import '../../../telemetry/presentation/providers/black_box_repository_provider.dart';
import '../../../telemetry/domain/models/time_based_stats.dart';
part 'pilot_provider.g.dart';

@riverpod
class PilotState extends _$PilotState {
  @override
  FutureOr<List<Pilot>> build() async {
    final repository = await ref.watch(pilotRepositoryProvider.future);
    return repository.getPilots();
  }

  Future<String> createPilot({
    required String name,
    String? pin,
    double initialFlightHours = 0.0,
    int initialFlights = 0,
    String? id,
  }) async {
    final repository = await ref.read(pilotRepositoryProvider.future);
    final newId = id ?? const Uuid().v4();
    final pilot = Pilot(
      id: newId,
      name: name,
      pin: pin,
      initialFlightHours: initialFlightHours,
      initialFlights: initialFlights,
    );
    await repository.savePilot(pilot);
    ref.invalidateSelf();
    await future;
    return newId;
  }

  Future<void> updatePilot(Pilot pilot) async {
    final repository = await ref.read(pilotRepositoryProvider.future);
    await repository.savePilot(pilot);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deletePilot(String id) async {
    final repository = await ref.read(pilotRepositoryProvider.future);
    await repository.deletePilot(id);
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<TimeBasedStats> pilotStats(Ref ref, String pilotId) async {
  final repository = ref.watch(blackBoxRepositoryProvider);
  final pilots = await ref.watch(pilotStateProvider.future);
  final pilot = pilots.cast<Pilot?>().firstWhere((p) => p?.id == pilotId, orElse: () => null);
  if (pilot == null) {
    return TimeBasedStats.empty();
  }
  return repository.getPilotTimeStats(
    pilotId,
    initialHours: pilot.initialFlightHours,
    initialFlights: pilot.initialFlights,
  );
}

