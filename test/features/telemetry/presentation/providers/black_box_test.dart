import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_state.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/black_box_provider.dart';
import 'package:stork/core/services/database/black_box_database_io.dart';
import 'package:stork/features/telemetry/presentation/providers/black_box_repository_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/flight_records_provider.dart';

class MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings _settings;
  MockAppSettingsNotifier(this._settings);

  @override
  FutureOr<AppSettings> build() => _settings;
}

void main() {
  late Database db;
  late IoBlackBoxDatabase blackBoxDb;
  late String dbPath;

  setUp(() {
    final tempDir = Directory.systemTemp.createTempSync('blackbox_test_');
    dbPath = p.join(tempDir.path, 'test_db.sqlite');
    
    db = sqlite3.open(dbPath);
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA busy_timeout = 5000;');
    
    blackBoxDb = IoBlackBoxDatabase();
    blackBoxDb.dbPathOverride = dbPath;
    blackBoxDb.database = db;
    blackBoxDb.setupTables(db);
  });

  tearDown(() {
    db.close();
    try {
      File(dbPath).parent.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('BlackBoxDatabase Tests', () {
    test('Can save and retrieve a flight', () async {
      final startTime = DateTime.now();

      final flight = Flight(
        uuid: 'test-uuid-1',
        name: 'Test Flight',
        startTime: startTime,
        pilotId: 'pilot-1',
        airplaneId: 'airplane-1',
      );

      await blackBoxDb.saveFlight(flight);

      final flights = await blackBoxDb.getFlights();
      expect(flights.length, equals(1));
      expect(flights.first.uuid, equals('test-uuid-1'));
      expect(flights.first.name, equals('Test Flight'));
      expect(flights.first.pilotId, equals('pilot-1'));
      expect(flights.first.airplaneId, equals('airplane-1'));
      expect(flights.first.endTime, isNull);
    });

    test('Can update flight end time', () async {
      final startTime = DateTime.now();
      final flight = Flight(
        uuid: 'test-uuid-2',
        name: 'Test Flight 2',
        startTime: startTime,
      );

      await blackBoxDb.saveFlight(flight);
      final endTime = startTime.add(const Duration(hours: 1));
      await blackBoxDb.updateFlightEndTime('test-uuid-2', endTime);

      final flights = await blackBoxDb.getFlights();
      expect(flights.length, equals(1));
      expect(flights.first.endTime, isNotNull);
      expect(
        flights.first.endTime!.difference(startTime),
        equals(const Duration(hours: 1)),
      );
    });

    test('Can insert and retrieve telemetry entries', () async {
      final flightUuid = 'test-uuid-3';
      final flight = Flight(
        uuid: flightUuid,
        name: 'Test Flight 3',
        startTime: DateTime.now(),
      );
      await blackBoxDb.saveFlight(flight);

      final entries = [
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now(),
          isSnapshot: true,
          data: {'latitude': 48.0, 'longitude': 17.0, 'engine_rpm': 2500.0},
        ),
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          isSnapshot: false,
          data: {'engine_rpm': 2600.0},
        ),
      ];

      await blackBoxDb.insertTelemetryEntries(entries);

      final retrieved = await blackBoxDb.getTelemetryForFlight(flightUuid);
      expect(retrieved.length, equals(2));

      // First is snapshot, all fields populated
      expect(retrieved[0].isSnapshot, isTrue);
      expect(retrieved[0].getFieldValue(TelemetryField.latitude), equals(48.0));
      expect(
        retrieved[0].getFieldValue(TelemetryField.engineRPM),
        equals(2500.0),
      );

      // Second is delta, latitude is null (unchanged), engineRPM is populated
      expect(retrieved[1].isSnapshot, isFalse);
      expect(retrieved[1].getFieldValue(TelemetryField.latitude), isNull);
      expect(
        retrieved[1].getFieldValue(TelemetryField.engineRPM),
        equals(2600.0),
      );
    });

    test('Deleting a flight deletes its telemetry (cascade)', () async {
      final flightUuid = 'test-uuid-4';
      final flight = Flight(
        uuid: flightUuid,
        name: 'Test Flight 4',
        startTime: DateTime.now(),
      );
      await blackBoxDb.saveFlight(flight);

      final entries = [
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now(),
          isSnapshot: true,
          data: {'latitude': 48.0, 'longitude': 17.0},
        ),
      ];
      await blackBoxDb.insertTelemetryEntries(entries);

      // Verify inserted
      var retrieved = await blackBoxDb.getTelemetryForFlight(flightUuid);
      expect(retrieved.length, equals(1));

      // Delete flight
      await blackBoxDb.deleteFlight(flightUuid);

      // Verify both flight and telemetry are gone
      final flights = await blackBoxDb.getFlights();
      expect(flights.isEmpty, isTrue);

      retrieved = await blackBoxDb.getTelemetryForFlight(flightUuid);
      expect(retrieved.isEmpty, isTrue);
    });
  });

  group('BlackBoxService Provider Tests', () {
    test('Transitions of isFlying start and stop flight logging', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            blackBoxDatabaseProvider.overrideWithValue(blackBoxDb),
            appSettingsProvider.overrideWith(
              () => MockAppSettingsNotifier(
                const AppSettings(
                  pilotId: 'test-pilot',
                  airplaneId: 'test-plane',
                ),
              ),
            ),
          ],
        );


        // Start listening to the black box service provider
        final serviceSub = container.listen(
          blackBoxServiceProvider,
          (prev, next) {},
        );
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // Verify no flights initially
        expect(
          container.read(blackBoxServiceProvider.notifier).activeFlightUuid,
          isNull,
        );

        // Transition to flying (ground speed > 2.77 threshold)
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        async.elapse(
          const Duration(milliseconds: 100),
        ); // Let listeners process

        final activeUuid = container
            .read(blackBoxServiceProvider.notifier)
            .activeFlightUuid;
        expect(activeUuid, isNotNull);

        // Retrieve flights to verify it was stored
        async.elapse(const Duration(seconds: 1)); // let database write execute
        async.elapse(const Duration(milliseconds: 500));

        // Check if DB lists the flight
        expect(
          db.select('SELECT COUNT(*) as count FROM flights').first['count'],
          equals(1),
        );
        final flightRow = db.select('SELECT * FROM flights').first;
        expect(flightRow['uuid'], equals(activeUuid));
        expect(flightRow['pilot_id'], equals('test-pilot'));
        expect(flightRow['airplane_id'], equals('test-plane'));

        // Transition back to not flying
        telemetryNotifier.updateGPS(groundSpeed: 0.0);
        async.elapse(const Duration(milliseconds: 100));

        expect(
          container.read(blackBoxServiceProvider.notifier).activeFlightUuid,
          isNull,
        );

        // Flight should have end_time populated now
        final endedFlightRow = db.select('SELECT end_time FROM flights').first;
        expect(endedFlightRow['end_time'], isNotNull);

        serviceSub.close();
      });
    });

    test(
      'High-frequency telemetry changes are buffered and flushed at 1Hz with deltas',
      () {
        fakeAsync((async) {
          final container = ProviderContainer(
            overrides: [blackBoxDatabaseProvider.overrideWithValue(blackBoxDb)],
          );
          addTearDown(container.dispose);

          final serviceSub = container.listen(
            blackBoxServiceProvider,
            (prev, next) {},
          );
          final telemetryNotifier = container.read(telemetryProvider.notifier);

          // Start flying
          telemetryNotifier.updateGPS(
            latitude: 48.0,
            longitude: 17.0,
            groundSpeed: 10.0,
          );
          async.elapse(const Duration(milliseconds: 100));

          final activeUuid = container
              .read(blackBoxServiceProvider.notifier)
              .activeFlightUuid;
          expect(activeUuid, isNotNull);

          // Initial keyframe is buffered immediately. Let's make multiple rapid changes to RPM
          telemetryNotifier.updateEngineRPM(2500);
          async.elapse(const Duration(milliseconds: 50));
          telemetryNotifier.updateEngineRPM(2600);
          async.elapse(const Duration(milliseconds: 50));
          telemetryNotifier.updateEngineRPM(2700);
          async.elapse(const Duration(milliseconds: 50));

          // Since it's within 1 second, the buffer hasn't flushed yet to DB
          final allTelemetryRows = db.select('SELECT * FROM flight_telemetry');
          var telemetryCount = allTelemetryRows.length;
          expect(
            telemetryCount,
            equals(0),
          ); // 0 because the flusher timer fires periodic 1s

          // Advance past 1 second to trigger flushing
          async.elapse(const Duration(milliseconds: 1100));

          // Check DB rows
          final rows = db.select(
            'SELECT * FROM flight_telemetry ORDER BY timestamp ASC',
          );
          expect(rows.length, equals(4)); // 1 initial keyframe + 3 RPM changes

          // Check that only RPM changed in subsequent rows (others are NULL)
          expect(rows[0]['is_snapshot'], equals(1)); // Initial keyframe
          expect(rows[0]['latitude'], equals(48.0));
          expect(
            rows[0]['engine_rpm'],
            isNull,
          ); // RPM wasn't set yet in initial state

          expect(
            rows[1]['is_snapshot'],
            equals(1),
          ); // Snapshot frame because RPM null -> 2500
          expect(rows[1]['latitude'], equals(48.0));
          expect(rows[1]['engine_rpm'], equals(2500.0));

          expect(rows[2]['is_snapshot'], equals(0)); // Delta frame
          expect(rows[2]['latitude'], isNull); // unchanged
          expect(rows[2]['engine_rpm'], equals(2600.0));

          expect(rows[3]['is_snapshot'], equals(0)); // Delta frame
          expect(rows[3]['latitude'], isNull); // unchanged
          expect(rows[3]['engine_rpm'], equals(2700.0));

          serviceSub.close();
        });
      },
    );

    test(
      'Periodic keyframes are forced every 10 seconds and on sensor offline/online status changes',
      () {
        fakeAsync((async) {
          final container = ProviderContainer(
            overrides: [blackBoxDatabaseProvider.overrideWithValue(blackBoxDb)],
          );
          addTearDown(container.dispose);

          final serviceSub = container.listen(
            blackBoxServiceProvider,
            (prev, next) {},
          );
          final telemetryNotifier = container.read(telemetryProvider.notifier);

          // Start flying
          telemetryNotifier.updateGPS(
            latitude: 48.0,
            longitude: 17.0,
            groundSpeed: 10.0,
          );
          async.elapse(const Duration(milliseconds: 100));

          // Wait 12 seconds while updating RPM occasionally (should trigger periodic keyframe)
          for (int i = 0; i < 12; i++) {
            telemetryNotifier.updateEngineRPM(2500 + i);
            telemetryNotifier.updateGPS(
              latitude: 48.0,
              longitude: 17.0,
              groundSpeed: 10.0,
            );
            async.elapse(const Duration(seconds: 1));
          }

          final rows = db.select(
            'SELECT * FROM flight_telemetry ORDER BY timestamp ASC',
          );
          final snapshots = rows.where((r) => r['is_snapshot'] == 1).toList();

          // We should have at least 2 snapshots (the initial one + one after 10 seconds)
          expect(snapshots.length, greaterThanOrEqualTo(2));

          // Now test sensor online/offline status change: lose GPS by resetting it
          final currentTelemetry = container.read(telemetryProvider);
          telemetryNotifier.updateAll(
            currentTelemetry.resetField(TelemetryField.latitude),
          );
          async.elapse(const Duration(milliseconds: 1100));

          final updatedRows = db.select(
            'SELECT * FROM flight_telemetry ORDER BY timestamp ASC',
          );
          final lastRow = updatedRows.last;

          // GPS offline (latitude: null) should force a keyframe!
          expect(lastRow['is_snapshot'], equals(1));
          expect(lastRow['latitude'], isNull); // real null

          serviceSub.close();
        });
      },
    );

    test('Telemetry is not buffered during flight creation progress, and is buffered after', () {
      fakeAsync((async) {
        final mockDb = FakeDelayingBlackBoxDatabase();
        mockDb.dbPathOverride = dbPath;
        mockDb.database = db;
        mockDb.setupTables(db);

        final completer = Completer<void>();
        mockDb.saveFlightCompleter = completer;

        final container = ProviderContainer(
          overrides: [
            blackBoxDatabaseProvider.overrideWithValue(mockDb),
          ],
        );
        addTearDown(container.dispose);

        final serviceSub = container.listen(blackBoxServiceProvider, (prev, next) {});
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // Start flying (triggers _startFlight which calls saveFlight but it's delayed)
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        async.elapse(const Duration(milliseconds: 100));

        // Update telemetry while saveFlight is in progress
        telemetryNotifier.updateEngineRPM(2500);
        async.elapse(const Duration(milliseconds: 100));

        // Verify no telemetry in DB yet
        expect(db.select('SELECT COUNT(*) as count FROM flight_telemetry').first['count'], equals(0));

        // Complete saveFlight
        completer.complete();
        async.elapse(const Duration(milliseconds: 100));

        // Initial keyframe should be buffered/saved now (after flush timer fires)
        async.elapse(const Duration(seconds: 1));
        final allTelemetry = db.select('SELECT * FROM flight_telemetry');
        final countAfterInit = allTelemetry.length;
        expect(countAfterInit, greaterThan(0));

        // Assert the engine RPM sample of 2500 is eventually persisted
        final hasRPM2500 = allTelemetry.any((row) => (row['engine_rpm'] as num?)?.toDouble() == 2500.0);
        expect(hasRPM2500, isTrue);

        serviceSub.close();
      });
    });

    test('Failed telemetry batch inserts are requeued and retried on next flush', () {
      fakeAsync((async) {
        final mockDb = FakeDelayingBlackBoxDatabase();
        mockDb.dbPathOverride = dbPath;
        mockDb.database = db;
        mockDb.setupTables(db);

        final container = ProviderContainer(
          overrides: [
            blackBoxDatabaseProvider.overrideWithValue(mockDb),
          ],
        );
        addTearDown(container.dispose);

        final serviceSub = container.listen(blackBoxServiceProvider, (prev, next) {});
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // Start flying
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        async.elapse(const Duration(milliseconds: 100));

        // Wait for flight creation to complete and initial keyframe to flush
        async.elapse(const Duration(seconds: 1));
        final initialCount = db.select('SELECT COUNT(*) as count FROM flight_telemetry').first['count'] as int;
        expect(initialCount, equals(1));

        // Enable failure for telemetry inserts
        mockDb.failInsertTelemetry = true;

        // Produce telemetry updates
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        telemetryNotifier.updateEngineRPM(2500);
        async.elapse(const Duration(milliseconds: 100));
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        telemetryNotifier.updateEngineRPM(2600);
        async.elapse(const Duration(milliseconds: 100));

        // Trigger flush (will fail)
        async.elapse(const Duration(milliseconds: 800));

        // DB count should remain 1 (initial keyframe) because inserts failed
        final countDuringFailure = db.select('SELECT COUNT(*) as count FROM flight_telemetry').first['count'] as int;
        expect(countDuringFailure, equals(1));

        // Disable failure
        mockDb.failInsertTelemetry = false;

        // Trigger next flush
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        async.elapse(const Duration(seconds: 1));

        // DB count should now contain the updates (at least greater than countDuringFailure)
        final finalCount = db.select('SELECT COUNT(*) as count FROM flight_telemetry').first['count'] as int;
        expect(finalCount, greaterThan(countDuringFailure));

        serviceSub.close();
      });
    });

    test('flightRecordsProvider recovers unfinished flights and updates on start/stop', () {
        fakeAsync((async) {
          final mockDb = FakeDelayingBlackBoxDatabase();
          mockDb.dbPathOverride = dbPath;
          mockDb.database = db;
          mockDb.setupTables(db);
          mockDb.runStatsSynchronously = true;

          // Seed an unfinished flight (endTime null) directly in the fake DB
          final unfinishedFlight = Flight(
            uuid: 'unfinished-uuid',
            name: 'Unfinished Flight',
            startTime: DateTime.now(),
            pilotId: 'test-pilot',
            airplaneId: 'test-plane',
          );
          // Save without awaiting; IoBlackBoxDatabase uses synchronous sqlite calls internally
          mockDb.saveFlight(unfinishedFlight);
          async.flushMicrotasks();

          final container = ProviderContainer(
            overrides: [
              blackBoxDatabaseProvider.overrideWithValue(mockDb),
              appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(
                  const AppSettings(
                    pilotId: 'test-pilot',
                    airplaneId: 'test-plane',
                  ),
                ),
              ),
            ],
          );
          // Wait for recovery to finish
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();

          // Keep flightRecordsProvider listened so it retains its state
          final recordsListener = container.listen(flightRecordsProvider, (prev, next) {});

          // Build black box service (triggers recovery)
          final serviceSub = container.listen(blackBoxServiceProvider, (prev, next) {});
          final telemetryNotifier = container.read(telemetryProvider.notifier);

          // Allow recovery to run – the provider should now contain the seeded flight with a recovered endTime
          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();
          
          final recovered = container.read(flightRecordsProvider).value;
          expect(recovered?.flights.length, equals(1));
          expect(recovered?.flights.first.uuid, equals('unfinished-uuid'));
          expect(recovered?.flights.first.endTime, isNotNull,
            reason: 'recoverUnfinishedFlights should set a non‑null endTime');

          // Start a new flight – this should add a second entry
          telemetryNotifier.updateGPS(
            latitude: 48.0,
            longitude: 17.0,
            groundSpeed: 10.0,
          );
          async.elapse(const Duration(milliseconds: 100));
          final afterStart = container.read(flightRecordsProvider).value;
          expect(afterStart?.flights.length, equals(2));
          // The newest flight should have a null endTime initially
          final newFlight = afterStart?.flights.firstWhere((f) => f.uuid != 'unfinished-uuid');
          expect(newFlight?.endTime, isNull);

          // Stop the new flight – endTime should become non‑null
          telemetryNotifier.updateGPS(groundSpeed: 0.0);
          async.elapse(const Duration(milliseconds: 100));
          final afterStop = container.read(flightRecordsProvider).value;
          expect(afterStop?.flights.length, equals(2));
          final stoppedFlight = afterStop?.flights.firstWhere((f) => f.uuid != 'unfinished-uuid');
          expect(stoppedFlight?.endTime, isNotNull);

          serviceSub.close();
          recordsListener.close();
        });
      });
  });
}

class FakeDelayingBlackBoxDatabase extends IoBlackBoxDatabase {
  Completer<void>? saveFlightCompleter;
  bool failSaveFlight = false;
  bool failInsertTelemetry = false;
  bool runStatsSynchronously = false;

  @override
  Future<void> saveFlight(Flight flight) async {
    if (failSaveFlight) {
      throw Exception('Database write error');
    }
    if (saveFlightCompleter != null) {
      await saveFlightCompleter!.future;
    }
    await super.saveFlight(flight);
  }

  @override
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) async {
    if (failInsertTelemetry) {
      throw Exception('Transient SQLite insert error');
    }
    await super.insertTelemetryEntries(entries);
  }

  @override
  Future<void> calculateAndSaveFlightStatistics(String flightUuid) async {
    if (runStatsSynchronously) {
      return;
    }
    return super.calculateAndSaveFlightStatistics(flightUuid);
  }
}
