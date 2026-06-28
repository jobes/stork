import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/settings/data/repositories/pilot_repository.dart';
import 'package:stork/features/settings/domain/models/pilot.dart';

void main() {
  group('PilotRepository Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('getPilots returns empty list if no key is in storage', () async {
      final repository = PilotRepository(prefs);
      final list = await repository.getPilots();
      expect(list, isEmpty);
    });

    test('getPilots parses a valid JSON list of pilots correctly', () async {
      final repository = PilotRepository(prefs);
      const originalPilots = [
        Pilot(id: '1', name: 'John Doe', initialFlightHours: 15.5, initialFlights: 10),
        Pilot(id: '2', name: 'Jane Smith', initialFlightHours: 2.0, initialFlights: 1),
      ];

      await prefs.setString(
        'app_pilots',
        json.encode(originalPilots.map((p) => p.toJson()).toList()),
      );

      final pilots = await repository.getPilots();
      expect(pilots, hasLength(2));
      expect(pilots[0].id, equals('1'));
      expect(pilots[0].name, equals('John Doe'));
      expect(pilots[1].id, equals('2'));
      expect(pilots[1].name, equals('Jane Smith'));
    });

    test('getPilots throws FormatException when JSON is malformed', () async {
      final repository = PilotRepository(prefs);
      // Malformed JSON (missing closing bracket/brace)
      await prefs.setString('app_pilots', '[{"id": "1", "name": "John Doe"');

      expect(
        () => repository.getPilots(),
        throwsA(isA<FormatException>()),
      );
    });

    test('getPilots throws TypeError when JSON structure does not match expected schema', () async {
      final repository = PilotRepository(prefs);
      // "initialFlights" has invalid type (string instead of int)
      await prefs.setString('app_pilots', '[{"id": "1", "name": "John Doe", "initialFlights": "ten"}]');

      expect(
        () => repository.getPilots(),
        throwsA(isA<TypeError>()),
      );
    });

    test('savePilots successfully persists pilots', () async {
      final repository = PilotRepository(prefs);
      const pilots = [
        Pilot(id: '1', name: 'John Doe'),
      ];

      await repository.savePilots(pilots);

      final savedJson = prefs.getString('app_pilots');
      expect(savedJson, isNotNull);
      final decoded = json.decode(savedJson!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(decoded[0]['name'], equals('John Doe'));
    });

    test('getPilot, savePilot and deletePilot work correctly', () async {
      final repository = PilotRepository(prefs);
      const p1 = Pilot(id: '1', name: 'John Doe');
      const p2 = Pilot(id: '2', name: 'Jane Smith');

      await repository.savePilots([p1]);

      // getPilot
      expect(await repository.getPilot('1'), equals(p1));
      expect(await repository.getPilot('2'), isNull);

      // savePilot (insert)
      await repository.savePilot(p2);
      expect(await repository.getPilot('2'), equals(p2));

      // savePilot (update)
      const p2Updated = Pilot(id: '2', name: 'Jane Smith Updated');
      await repository.savePilot(p2Updated);
      expect(await repository.getPilot('2'), equals(p2Updated));

      // deletePilot
      await repository.deletePilot('1');
      expect(await repository.getPilot('1'), isNull);
      final remaining = await repository.getPilots();
      expect(remaining, hasLength(1));
      expect(remaining.first.id, equals('2'));
    });
  });
}
