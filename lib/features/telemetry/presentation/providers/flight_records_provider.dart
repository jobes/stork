import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'black_box_repository_provider.dart';
import '../../domain/models/flight.dart';
import 'unique_filters_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

part 'flight_records_provider.g.dart';

class FlightRecordsState {
  final List<Flight> flights;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final String? filterPilotId;
  final String? filterAirplaneId;

  FlightRecordsState({
    required this.flights,
    required this.totalCount,
    required this.isLoadingMore,
    required this.hasMore,
    this.filterPilotId,
    this.filterAirplaneId,
  });

  FlightRecordsState copyWith({
    List<Flight>? flights,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    String? Function()? filterPilotId,
    String? Function()? filterAirplaneId,
  }) {
    return FlightRecordsState(
      flights: flights ?? this.flights,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      filterPilotId: filterPilotId != null
          ? filterPilotId()
          : this.filterPilotId,
      filterAirplaneId: filterAirplaneId != null
          ? filterAirplaneId()
          : this.filterAirplaneId,
    );
  }
}

@riverpod
class FlightRecords extends _$FlightRecords {
  static const int _pageSize = 20;

  @override
  FutureOr<FlightRecordsState> build() async {
    final repo = ref.watch(blackBoxRepositoryProvider);
    final settings = await ref.watch(appSettingsProvider.future);

    final defaultPilotId = settings.pilotId;
    final defaultAirplaneId = settings.airplaneId;

    final count = await repo.getFlightsCount(
      pilotId: defaultPilotId,
      airplaneId: defaultAirplaneId,
    );
    final flights = await repo.getFlightsPaginated(
      _pageSize,
      pilotId: defaultPilotId,
      airplaneId: defaultAirplaneId,
    );

    return FlightRecordsState(
      flights: flights,
      totalCount: count,
      isLoadingMore: false,
      hasMore: flights.length < count,
      filterPilotId: defaultPilotId,
      filterAirplaneId: defaultAirplaneId,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(blackBoxRepositoryProvider);
      final lastFlight = currentState.flights.isNotEmpty
          ? currentState.flights.last
          : null;

      final pilotAnonymous = currentState.filterPilotId == 'anonymous'
          ? true
          : null;
      final pilotId =
          (currentState.filterPilotId != null &&
              currentState.filterPilotId != 'anonymous')
          ? currentState.filterPilotId
          : null;
      final airplaneAnonymous = currentState.filterAirplaneId == 'anonymous'
          ? true
          : null;
      final airplaneId =
          (currentState.filterAirplaneId != null &&
              currentState.filterAirplaneId != 'anonymous')
          ? currentState.filterAirplaneId
          : null;

      final nextFlights = await repo.getFlightsPaginated(
        _pageSize,
        lastStartTime: lastFlight?.startTime,
        lastUuid: lastFlight?.uuid,
        pilotId: pilotId,
        airplaneId: airplaneId,
        pilotAnonymous: pilotAnonymous,
        airplaneAnonymous: airplaneAnonymous,
      );

      if (!ref.mounted) return;

      final updatedFlights = [...currentState.flights, ...nextFlights];
      state = AsyncData(
        currentState.copyWith(
          flights: updatedFlights,
          isLoadingMore: false,
          hasMore: nextFlights.length == _pageSize,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    // Preserve current filter state if it exists
    final currentState = state.value;
    final filterPilotId = currentState?.filterPilotId;
    final filterAirplaneId = currentState?.filterAirplaneId;

    state = const AsyncLoading();
    try {
      final repo = ref.read(blackBoxRepositoryProvider);

      final pilotAnonymous = filterPilotId == 'anonymous' ? true : null;
      final pilotId = (filterPilotId != null && filterPilotId != 'anonymous')
          ? filterPilotId
          : null;
      final airplaneAnonymous = filterAirplaneId == 'anonymous' ? true : null;
      final airplaneId =
          (filterAirplaneId != null && filterAirplaneId != 'anonymous')
          ? filterAirplaneId
          : null;

      final count = await repo.getFlightsCount(
        pilotId: pilotId,
        airplaneId: airplaneId,
        pilotAnonymous: pilotAnonymous,
        airplaneAnonymous: airplaneAnonymous,
      );
      if (!ref.mounted) return;

      final flights = await repo.getFlightsPaginated(
        _pageSize,
        pilotId: pilotId,
        airplaneId: airplaneId,
        pilotAnonymous: pilotAnonymous,
        airplaneAnonymous: airplaneAnonymous,
      );
      if (!ref.mounted) return;

      state = AsyncData(
        FlightRecordsState(
          flights: flights,
          totalCount: count,
          isLoadingMore: false,
          hasMore: flights.length < count,
          filterPilotId: filterPilotId,
          filterAirplaneId: filterAirplaneId,
        ),
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> setFilters({
    String? Function()? filterPilotId,
    String? Function()? filterAirplaneId,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedState = currentState.copyWith(
      filterPilotId: filterPilotId,
      filterAirplaneId: filterAirplaneId,
    );

    state = AsyncData(updatedState);
    await refresh();
  }

  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
    String? notes,
  }) async {
    final repo = ref.read(blackBoxRepositoryProvider);
    await repo.updateFlightDetails(
      uuid: uuid,
      name: name,
      pilotId: pilotId,
      airplaneId: airplaneId,
      notes: notes,
    );

    if (!ref.mounted) return;

    ref.invalidate(uniquePilotIdsProvider);
    ref.invalidate(uniqueAirplaneIdsProvider);

    final currentState = state.value;
    if (currentState != null) {
      final updatedFlights = currentState.flights.map((f) {
        if (f.uuid == uuid) {
          return f.copyWith(
            name: name,
            pilotId: pilotId,
            airplaneId: airplaneId,
            notes: notes,
          );
        }
        return f;
      }).toList();
      state = AsyncData(currentState.copyWith(flights: updatedFlights));
    }
  }

  Future<void> deleteFlight(String uuid) async {
    final repo = ref.read(blackBoxRepositoryProvider);
    await repo.deleteFlight(uuid);
    if (!ref.mounted) return;

    ref.invalidate(uniquePilotIdsProvider);
    ref.invalidate(uniqueAirplaneIdsProvider);

    await refresh();
  }
}
