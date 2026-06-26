import '../../../../core/services/database/black_box_database.dart';
import '../../domain/models/flight.dart';
import '../../domain/models/telemetry_entry.dart';
import '../../domain/repositories/black_box_repository.dart';

export '../../domain/repositories/black_box_repository.dart';

class BlackBoxRepositoryImpl implements BlackBoxRepository {
  final BlackBoxDatabase _database;

  BlackBoxRepositoryImpl(this._database);

  @override
  Future<void> saveFlight(Flight flight) => _database.saveFlight(flight);

  @override
  Future<void> updateFlightEndTime(String uuid, DateTime endTime) =>
      _database.updateFlightEndTime(uuid, endTime);

  @override
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) =>
      _database.insertTelemetryEntries(entries);

  @override
  Future<List<Flight>> getFlights() => _database.getFlights();

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid) =>
      _database.getTelemetryForFlight(flightUuid);

  @override
  Future<void> deleteFlight(String uuid) => _database.deleteFlight(uuid);

  @override
  Future<void> clearAll() => _database.clearAll();

  @override
  Future<List<Flight>> getFlightsPaginated(int limit, int offset) =>
      _database.getFlightsPaginated(limit, offset);

  @override
  Future<int> getFlightsCount() => _database.getFlightsCount();

  @override
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
  }) => _database.updateFlightDetails(
    uuid: uuid,
    name: name,
    pilotId: pilotId,
    airplaneId: airplaneId,
  );

  @override
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(String flightUuid) =>
      _database.getGpxTelemetryForFlight(flightUuid);

  @override
  Future<void> calculateAndSaveFlightStatistics(String flightUuid) =>
      _database.calculateAndSaveFlightStatistics(flightUuid);

  @override
  Future<void> recoverUnfinishedFlights() async {
    final unfinishedFlights = await _database.getUnfinishedFlights();
    for (final flight in unfinishedFlights) {
      final lastEntry = await _database.getLastTelemetryForFlight(flight.uuid);
      final endTime = lastEntry?.timestamp ?? flight.startTime;
      await calculateAndSaveFlightStatistics(flight.uuid);
      await _database.updateFlightEndTime(flight.uuid, endTime);
    }
  }
}
