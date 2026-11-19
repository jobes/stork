import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/settings/data/repositories/aircraft_repository.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';

void main() {
  group('AircraftRepository Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('getAircrafts returns empty list if no key is in storage', () async {
      final repository = AircraftRepository(prefs);
      final list = await repository.getAircrafts();
      expect(list, isEmpty);
    });

    test(
      'getAircrafts parses a valid JSON list of aircrafts correctly',
      () async {
        final repository = AircraftRepository(prefs);
        const originalAircrafts = [
          Aircraft(
            id: '1',
            name: 'Cessna 172',
            initialFlightHours: 15.5,
            initialFlights: 10,
          ),
          Aircraft(
            id: '2',
            name: 'Piper Archer',
            initialFlightHours: 2.0,
            initialFlights: 1,
          ),
        ];

        await prefs.setString(
          'app_aircrafts',
          json.encode(originalAircrafts.map((a) => a.toJson()).toList()),
        );

        final aircrafts = await repository.getAircrafts();
        expect(aircrafts, hasLength(2));
        expect(aircrafts[0].id, equals('1'));
        expect(aircrafts[0].name, equals('Cessna 172'));
        expect(aircrafts[1].id, equals('2'));
        expect(aircrafts[1].name, equals('Piper Archer'));
      },
    );

    test(
      'getAircrafts throws FormatException when JSON is malformed',
      () async {
        final repository = AircraftRepository(prefs);
        // Malformed JSON (missing closing bracket/brace)
        await prefs.setString('app_aircrafts', '[{"id": "1", "name": "Cessna"');

        expect(
          () => repository.getAircrafts(),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'getAircrafts throws TypeError when JSON structure does not match expected schema',
      () async {
        final repository = AircraftRepository(prefs);
        // "initialFlights" has invalid type (string instead of int)
        await prefs.setString(
          'app_aircrafts',
          '[{"id": "1", "name": "Cessna", "initialFlights": "ten"}]',
        );

        expect(() => repository.getAircrafts(), throwsA(isA<TypeError>()));
      },
    );

    test(
      'each aircraft stores its own flight profile with fresh defaults',
      () async {
        final repository = AircraftRepository(prefs);
        await prefs.setString('app_settings', '{"averageSpeed":37}');
        await prefs.setString(
          'app_aircrafts',
          '[{"id":"one","name":"First"},{"id":"two","name":"Second"}]',
        );

        final first = (await repository.getAircraft('one'))!;
        expect(first.cruiseSpeedMs, defaultCruiseSpeedMs);
        expect(first.weatherAltitudeFeet, isNull);

        await repository.saveAircraft(
          first.copyWith(cruiseSpeedMs: 21, weatherAltitudeFeet: 3200),
        );
        expect(
          (await repository.getAircraft('one'))!.weatherAltitudeFeet,
          3200,
        );
        expect((await repository.getAircraft('one'))!.cruiseSpeedMs, 21);
        expect(
          (await repository.getAircraft('two'))!.cruiseSpeedMs,
          defaultCruiseSpeedMs,
        );
        expect(
          (await repository.getAircraft('two'))!.weatherAltitudeFeet,
          isNull,
        );
      },
    );

    test('weather limits are optional and isolated per aircraft', () async {
      final repository = AircraftRepository(prefs);
      await repository.saveAircrafts([
        const Aircraft(
          id: 'one',
          name: 'First',
          dangerousWindMs: 7,
          dangerousGustMs: 11,
        ),
        const Aircraft(id: 'two', name: 'Second'),
      ]);
      expect((await repository.getAircraft('one'))!.dangerousWindMs, 7);
      expect((await repository.getAircraft('one'))!.dangerousGustMs, 11);
      expect((await repository.getAircraft('two'))!.dangerousWindMs, isNull);
      expect((await repository.getAircraft('two'))!.dangerousGustMs, isNull);
      final first = (await repository.getAircraft('one'))!;
      await repository.saveAircraft(first.copyWith(dangerousWindMs: null));
      expect((await repository.getAircraft('one'))!.dangerousWindMs, isNull);
      expect((await repository.getAircraft('one'))!.dangerousGustMs, 11);
    });

    test('saveAircrafts successfully persists aircrafts', () async {
      final repository = AircraftRepository(prefs);
      const aircrafts = [Aircraft(id: '1', name: 'Cessna 172')];

      await repository.saveAircrafts(aircrafts);

      final savedJson = prefs.getString('app_aircrafts');
      expect(savedJson, isNotNull);
      final decoded = json.decode(savedJson!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(decoded[0]['name'], equals('Cessna 172'));
    });

    test(
      'getAircraft, saveAircraft and deleteAircraft work correctly',
      () async {
        final repository = AircraftRepository(prefs);
        const a1 = Aircraft(id: '1', name: 'Cessna 172');
        const a2 = Aircraft(id: '2', name: 'Piper Archer');

        await repository.saveAircrafts([a1]);

        // getAircraft
        expect(await repository.getAircraft('1'), equals(a1));
        expect(await repository.getAircraft('2'), isNull);

        // saveAircraft (insert)
        await repository.saveAircraft(a2);
        expect(await repository.getAircraft('2'), equals(a2));

        // saveAircraft (update)
        const a2Updated = Aircraft(id: '2', name: 'Piper Archer II');
        await repository.saveAircraft(a2Updated);
        expect(await repository.getAircraft('2'), equals(a2Updated));

        // deleteAircraft
        await repository.deleteAircraft('1');
        expect(await repository.getAircraft('1'), isNull);
        final remaining = await repository.getAircrafts();
        expect(remaining, hasLength(1));
        expect(remaining.first.id, equals('2'));
      },
    );
  });
}
