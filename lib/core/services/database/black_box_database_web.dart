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
    // No-op on web
  }

  @override
  Future<void> saveFlight(Flight flight) async {
    // No-op on web
  }

  @override
  Future<void> updateFlightEndTime(String uuid, DateTime endTime) async {
    // No-op on web
  }

  @override
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) async {
    // No-op on web
  }

  @override
  Future<List<Flight>> getFlights() async {
    return [];
  }

  @override
  Future<List<Flight>> getUnfinishedFlights() async {
    return [];
  }

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid) async {
    return [];
  }

  @override
  Future<TelemetryEntry?> getLastTelemetryForFlight(String flightUuid) async {
    return null;
  }

  @override
  Future<void> saveFlightStatistics(
    String flightUuid,
    FlightStatistics stats,
  ) async {
    // No-op on web
  }

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlightPaginated(
    String flightUuid,
    int limit,
    int? lastId,
  ) async {
    return [];
  }

  @override
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(
    String flightUuid,
  ) async {
    return [];
  }

  @override
  Future<void> deleteFlight(String uuid) async {
    // No-op on web
  }

  @override
  Future<void> clearAll() async {
    // No-op on web
  }

  @override
  Future<List<Flight>> getFlightsPaginated(int limit, int offset) async {
    return [];
  }

  @override
  Future<int> getFlightsCount() async {
    return 0;
  }

  @override
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
  }) async {
    // No-op on web
  }

  @override
  Future<void> calculateAndSaveFlightStatistics(String flightUuid) async {
    // No-op on web
  }
}
