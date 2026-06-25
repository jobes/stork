import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:stork/core/services/database/black_box_database_io.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';

void main() {
  late IoBlackBoxDatabase blackBoxDb;
  late String dbPath;

  setUp(() {
    final tempDir = Directory.systemTemp.createTempSync('blackbox_io_test_');
    dbPath = p.join(tempDir.path, 'test_db.sqlite');
    blackBoxDb = IoBlackBoxDatabase();
    blackBoxDb.dbPathOverride = dbPath;
  });

  tearDown(() async {
    try {
      await blackBoxDb.resetDatabase();
    } catch (_) {}
    try {
      final dir = Directory(p.dirname(dbPath));
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('IoBlackBoxDatabase Concurrency Tests', () {
    test('concurrently awaiting database returns the same instance and only initializes once', () async {
      final futures = Future.wait([
        blackBoxDb.database,
        blackBoxDb.database,
        blackBoxDb.database,
      ]);

      final databases = await futures;
      expect(databases[0], isNotNull);
      expect(databases[0], same(databases[1]));
      expect(databases[0], same(databases[2]));
    });

    test('resetting the database allows creating a new database connection instance', () async {
      final db1 = await blackBoxDb.database;
      await blackBoxDb.resetDatabase();
      final db2 = await blackBoxDb.database;

      expect(db1, isNot(same(db2)));
    });
  });

  group('IoBlackBoxDatabase saveFlight Tests', () {
    test('saveFlight with existing UUID preserves related telemetry entries (ON CONFLICT DO UPDATE)', () async {
      final flightUuid = 'conflict-test-uuid';
      final flight = Flight(
        uuid: flightUuid,
        name: 'Initial Flight Name',
        startTime: DateTime.now(),
        pilotId: 'pilot-1',
        airplaneId: 'airplane-1',
      );

      await blackBoxDb.saveFlight(flight);

      // Insert some telemetry associated with the flight
      final entries = [
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now(),
          isSnapshot: true,
          data: {'engine_rpm': 2300.0},
        ),
      ];
      await blackBoxDb.insertTelemetryEntries(entries);

      // Check telemetry exists
      var telemetry = await blackBoxDb.getTelemetryForFlight(flightUuid);
      expect(telemetry, hasLength(1));

      // Re-save/upsert the same flight (e.g. updating the name or endTime)
      final updatedFlight = Flight(
        uuid: flightUuid,
        name: 'Updated Flight Name',
        startTime: flight.startTime,
        endTime: DateTime.now(),
        pilotId: 'pilot-1',
        airplaneId: 'airplane-1',
      );
      await blackBoxDb.saveFlight(updatedFlight);

      // Verify flight details were updated
      final flights = await blackBoxDb.getFlights();
      final savedFlight = flights.firstWhere((f) => f.uuid == flightUuid);
      expect(savedFlight.name, equals('Updated Flight Name'));
      expect(savedFlight.endTime, isNotNull);

      // Verify that related telemetry WAS NOT deleted by CASCADE (as it would be under INSERT OR REPLACE)
      telemetry = await blackBoxDb.getTelemetryForFlight(flightUuid);
      expect(telemetry, hasLength(1));
    });
  });
}
