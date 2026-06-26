import '../models/flight.dart';
import '../models/telemetry_entry.dart';

abstract class BlackBoxRepository {
  Future<void> saveFlight(Flight flight);
  Future<void> updateFlightEndTime(String uuid, DateTime endTime);
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries);
  Future<List<Flight>> getFlights();
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid);
  Future<void> deleteFlight(String uuid);
  Future<void> clearAll();
  Future<List<Flight>> getFlightsPaginated(
    int limit, {
    DateTime? lastStartTime,
    String? lastUuid,
  });
  Future<int> getFlightsCount();
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
  });
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(String flightUuid);
  Future<void> calculateAndSaveFlightStatistics(String flightUuid);
  Future<void> recoverUnfinishedFlights();
}
