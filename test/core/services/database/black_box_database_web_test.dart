import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/database/black_box_database_web.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/flight_statistics.dart';

void main() {
  group('WebBlackBoxDatabase Tests', () {
    late WebBlackBoxDatabase db;

    setUp(() {
      db = WebBlackBoxDatabase();
    });

    test('database getter throws UnsupportedError', () async {
      expect(() => db.database, throwsUnsupportedError);
    });

    test('resetDatabase throws UnsupportedError', () async {
      expect(() => db.resetDatabase(), throwsUnsupportedError);
    });

    test('saveFlight throws UnsupportedError', () async {
      final flight = Flight(
        uuid: 'test-uuid',
        name: 'Test Flight',
        startTime: DateTime.now(),
      );
      expect(() => db.saveFlight(flight), throwsUnsupportedError);
    });

    test('updateFlightEndTime throws UnsupportedError', () async {
      expect(
        () => db.updateFlightEndTime('test-uuid', DateTime.now()),
        throwsUnsupportedError,
      );
    });

    test('insertTelemetryEntries throws UnsupportedError', () async {
      expect(() => db.insertTelemetryEntries([]), throwsUnsupportedError);
    });

    test('getFlights throws UnsupportedError', () async {
      expect(() => db.getFlights(), throwsUnsupportedError);
    });

    test('getUnfinishedFlights throws UnsupportedError', () async {
      expect(() => db.getUnfinishedFlights(), throwsUnsupportedError);
    });

    test('getTelemetryForFlight throws UnsupportedError', () async {
      expect(() => db.getTelemetryForFlight('test-uuid'), throwsUnsupportedError);
    });

    test('getLastTelemetryForFlight throws UnsupportedError', () async {
      expect(() => db.getLastTelemetryForFlight('test-uuid'), throwsUnsupportedError);
    });

    test('saveFlightStatistics throws UnsupportedError', () async {
      final stats = FlightStatistics(
        maxAltitude: 1000,
        maxGroundSpeed: 100,
        totalDistance: 50,
      );
      expect(() => db.saveFlightStatistics('test-uuid', stats), throwsUnsupportedError);
    });

    test('getTelemetryForFlightPaginated throws UnsupportedError', () async {
      expect(
        () => db.getTelemetryForFlightPaginated('test-uuid', 10, null),
        throwsUnsupportedError,
      );
    });

    test('getGpxTelemetryForFlight throws UnsupportedError', () async {
      expect(() => db.getGpxTelemetryForFlight('test-uuid'), throwsUnsupportedError);
    });

    test('deleteFlight throws UnsupportedError', () async {
      expect(() => db.deleteFlight('test-uuid'), throwsUnsupportedError);
    });

    test('clearAll throws UnsupportedError', () async {
      expect(() => db.clearAll(), throwsUnsupportedError);
    });

    test('getFlightsPaginated throws UnsupportedError', () async {
      expect(() => db.getFlightsPaginated(10), throwsUnsupportedError);
    });

    test('getFlightsCount throws UnsupportedError', () async {
      expect(() => db.getFlightsCount(), throwsUnsupportedError);
    });

    test('updateFlightDetails throws UnsupportedError', () async {
      expect(
        () => db.updateFlightDetails(uuid: 'test-uuid', name: 'Test Flight'),
        throwsUnsupportedError,
      );
    });

    test('calculateAndSaveFlightStatistics throws UnsupportedError', () async {
      expect(
        () => db.calculateAndSaveFlightStatistics('test-uuid'),
        throwsUnsupportedError,
      );
    });
  });
}
