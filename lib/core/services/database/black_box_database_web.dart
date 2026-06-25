import '../../../features/telemetry/domain/models/flight.dart';
import '../../../features/telemetry/domain/models/flight_statistics.dart';
import '../../../features/telemetry/domain/models/telemetry_entry.dart';

import 'black_box_database.dart';

BlackBoxDatabase getDatabase() => WebBlackBoxDatabase();

class WebBlackBoxDatabase implements BlackBoxDatabase {
  Future<dynamic> get database async =>
      throw UnsupportedError('SQLite is not supported on web.');

  set database(dynamic db) {
    // No-op on web
  }

  void setupTables(dynamic db) {
    // No-op on web
  }

  @override
  Future<void> resetDatabase() async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> saveFlight(Flight flight) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> updateFlightEndTime(String uuid, DateTime endTime) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<List<Flight>> getFlights() async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<List<Flight>> getUnfinishedFlights() async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<TelemetryEntry?> getLastTelemetryForFlight(String flightUuid) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> saveFlightStatistics(
    String flightUuid,
    FlightStatistics stats,
  ) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlightPaginated(
    String flightUuid,
    int limit,
    int? lastId,
  ) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(
    String flightUuid,
  ) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> deleteFlight(String uuid) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> clearAll() async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<List<Flight>> getFlightsPaginated(int limit, int offset) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<int> getFlightsCount() async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
  }) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  @override
  Future<void> calculateAndSaveFlightStatistics(String flightUuid) async {
    throw UnsupportedError('SQLite is not supported on web.');
  }
}
