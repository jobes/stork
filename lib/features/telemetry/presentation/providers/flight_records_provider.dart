import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'black_box_repository_provider.dart';
import '../../domain/models/flight.dart';

part 'flight_records_provider.g.dart';

class FlightRecordsState {
  final List<Flight> flights;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;

  FlightRecordsState({
    required this.flights,
    required this.totalCount,
    required this.isLoadingMore,
    required this.hasMore,
  });

  FlightRecordsState copyWith({
    List<Flight>? flights,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return FlightRecordsState(
      flights: flights ?? this.flights,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

@riverpod
class FlightRecords extends _$FlightRecords {
  static const int _pageSize = 20;

  @override
  FutureOr<FlightRecordsState> build() async {
    final repo = ref.watch(blackBoxRepositoryProvider);
    final count = await repo.getFlightsCount();
    final flights = await repo.getFlightsPaginated(_pageSize);
    return FlightRecordsState(
      flights: flights,
      totalCount: count,
      isLoadingMore: false,
      hasMore: flights.length < count,
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
      final lastFlight = currentState.flights.isNotEmpty ? currentState.flights.last : null;
      final nextFlights = await repo.getFlightsPaginated(
        _pageSize,
        lastStartTime: lastFlight?.startTime,
        lastUuid: lastFlight?.uuid,
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
    state = const AsyncLoading();
    try {
      final repo = ref.read(blackBoxRepositoryProvider);
      final count = await repo.getFlightsCount();
      if (!ref.mounted) return;
      final flights = await repo.getFlightsPaginated(_pageSize);
      if (!ref.mounted) return;
      state = AsyncData(FlightRecordsState(
        flights: flights,
        totalCount: count,
        isLoadingMore: false,
        hasMore: flights.length < count,
      ));
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
  }) async {
    final repo = ref.read(blackBoxRepositoryProvider);
    await repo.updateFlightDetails(
      uuid: uuid,
      name: name,
      pilotId: pilotId,
      airplaneId: airplaneId,
    );

    if (!ref.mounted) return;

    final currentState = state.value;
    if (currentState != null) {
      final updatedFlights = currentState.flights.map((f) {
        if (f.uuid == uuid) {
          return f.copyWith(
            name: name,
            pilotId: pilotId,
            airplaneId: airplaneId,
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
    await refresh();
  }
}
