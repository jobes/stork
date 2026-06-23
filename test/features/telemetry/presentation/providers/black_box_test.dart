import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_state.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/black_box_provider.dart';
import 'package:stork/core/services/database/black_box_database.dart';

class MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings _settings;
  MockAppSettingsNotifier(this._settings);

  @override
  FutureOr<AppSettings> build() => _settings;
}

void main() {
  late Database db;

  setUp(() {
    db = sqlite3.openInMemory();
    db.execute('PRAGMA foreign_keys = ON;');
    BlackBoxDatabase.database = db;
    BlackBoxDatabase.setupTables(db);
  });

  tearDown(() {
    db.close();
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

      await BlackBoxDatabase.saveFlight(flight);

      final flights = await BlackBoxDatabase.getFlights();
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

      await BlackBoxDatabase.saveFlight(flight);
      final endTime = startTime.add(const Duration(hours: 1));
      await BlackBoxDatabase.updateFlightEndTime('test-uuid-2', endTime);

      final flights = await BlackBoxDatabase.getFlights();
      expect(flights.length, equals(1));
      expect(flights.first.endTime, isNotNull);
      expect(flights.first.endTime!.difference(startTime), equals(const Duration(hours: 1)));
    });

    test('Can insert and retrieve telemetry entries', () async {
      final flightUuid = 'test-uuid-3';
      final flight = Flight(
        uuid: flightUuid,
        name: 'Test Flight 3',
        startTime: DateTime.now(),
      );
      await BlackBoxDatabase.saveFlight(flight);

      final entries = [
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now(),
          isSnapshot: true,
          data: {
            'latitude': 48.0,
            'longitude': 17.0,
            'engine_rpm': 2500.0,
          },
        ),
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          isSnapshot: false,
          data: {
            'engine_rpm': 2600.0,
          },
        ),
      ];

      await BlackBoxDatabase.insertTelemetryEntries(entries);

      final retrieved = await BlackBoxDatabase.getTelemetryForFlight(flightUuid);
      expect(retrieved.length, equals(2));
      
      // First is snapshot, all fields populated
      expect(retrieved[0].isSnapshot, isTrue);
      expect(retrieved[0].getFieldValue(TelemetryField.latitude), equals(48.0));
      expect(retrieved[0].getFieldValue(TelemetryField.engineRPM), equals(2500.0));

      // Second is delta, latitude is null (unchanged), engineRPM is populated
      expect(retrieved[1].isSnapshot, isFalse);
      expect(retrieved[1].getFieldValue(TelemetryField.latitude), isNull);
      expect(retrieved[1].getFieldValue(TelemetryField.engineRPM), equals(2600.0));
    });

    test('Deleting a flight deletes its telemetry (cascade)', () async {
      final flightUuid = 'test-uuid-4';
      final flight = Flight(
        uuid: flightUuid,
        name: 'Test Flight 4',
        startTime: DateTime.now(),
      );
      await BlackBoxDatabase.saveFlight(flight);

      final entries = [
        TelemetryEntry(
          flightUuid: flightUuid,
          timestamp: DateTime.now(),
          isSnapshot: true,
          data: {
            'latitude': 48.0,
            'longitude': 17.0,
          },
        ),
      ];
      await BlackBoxDatabase.insertTelemetryEntries(entries);

      // Verify inserted
      var retrieved = await BlackBoxDatabase.getTelemetryForFlight(flightUuid);
      expect(retrieved.length, equals(1));

      // Delete flight
      await BlackBoxDatabase.deleteFlight(flightUuid);

      // Verify both flight and telemetry are gone
      final flights = await BlackBoxDatabase.getFlights();
      expect(flights.isEmpty, isTrue);

      retrieved = await BlackBoxDatabase.getTelemetryForFlight(flightUuid);
      expect(retrieved.isEmpty, isTrue);
    });
  });

  group('BlackBoxService Provider Tests', () {
    test('Transitions of isFlying start and stop flight logging', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(const AppSettings(
              pilotId: 'test-pilot',
              airplaneId: 'test-plane',
            ))),
          ],
        );
        addTearDown(container.dispose);

        // Start listening to the black box service provider
        final serviceSub = container.listen(blackBoxServiceProvider, (prev, next) {});
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // Verify no flights initially
        expect(container.read(blackBoxServiceProvider.notifier).activeFlightUuid, isNull);

        // Transition to flying (ground speed > 2.77 threshold)
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        async.elapse(const Duration(milliseconds: 100)); // Let listeners process

        final activeUuid = container.read(blackBoxServiceProvider.notifier).activeFlightUuid;
        expect(activeUuid, isNotNull);

        // Retrieve flights to verify it was stored
        async.elapse(const Duration(seconds: 1)); // let database write execute
        async.elapse(const Duration(milliseconds: 500));

        // Check if DB lists the flight
        expect(db.select('SELECT COUNT(*) as count FROM flights').first['count'], equals(1));
        final flightRow = db.select('SELECT * FROM flights').first;
        expect(flightRow['uuid'], equals(activeUuid));
        expect(flightRow['pilot_id'], equals('test-pilot'));
        expect(flightRow['airplane_id'], equals('test-plane'));

        // Transition back to not flying
        telemetryNotifier.updateGPS(groundSpeed: 0.0);
        async.elapse(const Duration(milliseconds: 100));

        expect(container.read(blackBoxServiceProvider.notifier).activeFlightUuid, isNull);
        
        // Flight should have end_time populated now
        final endedFlightRow = db.select('SELECT end_time FROM flights').first;
        expect(endedFlightRow['end_time'], isNotNull);

        serviceSub.close();
      });
    });

    test('High-frequency telemetry changes are buffered and flushed at 1Hz with deltas', () {
      fakeAsync((async) {
        final container = ProviderContainer();
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

        final activeUuid = container.read(blackBoxServiceProvider.notifier).activeFlightUuid;
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
        expect(telemetryCount, equals(0)); // 0 because the flusher timer fires periodic 1s

        // Advance past 1 second to trigger flushing
        async.elapse(const Duration(milliseconds: 1100));

        // Check DB rows
        final rows = db.select('SELECT * FROM flight_telemetry ORDER BY timestamp ASC');
        expect(rows.length, equals(4)); // 1 initial keyframe + 3 RPM changes

        // Check that only RPM changed in subsequent rows (others are NULL)
        expect(rows[0]['is_snapshot'], equals(1)); // Initial keyframe
        expect(rows[0]['latitude'], equals(48.0));
        expect(rows[0]['engine_rpm'], isNull); // RPM wasn't set yet in initial state

        expect(rows[1]['is_snapshot'], equals(1)); // Snapshot frame because RPM null -> 2500
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
    });

    test('Periodic keyframes are forced every 10 seconds and on sensor offline/online status changes', () {
      fakeAsync((async) {
        final container = ProviderContainer();
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

        // Wait 12 seconds while updating RPM occasionally (should trigger periodic keyframe)
        for (int i = 0; i < 12; i++) {
          telemetryNotifier.updateEngineRPM(2500.0 + i);
          telemetryNotifier.updateGPS(
            latitude: 48.0,
            longitude: 17.0,
            groundSpeed: 10.0,
          );
          async.elapse(const Duration(seconds: 1));
        }

        final rows = db.select('SELECT * FROM flight_telemetry ORDER BY timestamp ASC');
        final snapshots = rows.where((r) => r['is_snapshot'] == 1).toList();
        
        // We should have at least 2 snapshots (the initial one + one after 10 seconds)
        expect(snapshots.length, greaterThanOrEqualTo(2));

        // Now test sensor online/offline status change: lose GPS by resetting it
        final currentTelemetry = container.read(telemetryProvider);
        telemetryNotifier.updateAll(currentTelemetry.resetField(TelemetryField.latitude));
        async.elapse(const Duration(milliseconds: 1100));

        final updatedRows = db.select('SELECT * FROM flight_telemetry ORDER BY timestamp ASC');
        final lastRow = updatedRows.last;
        
        // GPS offline (latitude: null) should force a keyframe!
        expect(lastRow['is_snapshot'], equals(1));
        expect(lastRow['latitude'], isNull); // real null

        serviceSub.close();
      });
    });
  });
}
