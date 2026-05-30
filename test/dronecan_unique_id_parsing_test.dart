import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';

class MockCannelloniService extends CannelloniService {
  @override
  bool build() {
    return false;
    // Bypass C initialization and socket binding during unit tests
  }
}

void main() {
  group('DroneCAN Unique ID Parsing and Robustness', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test(
      'Loads and parses a valid 32-character unique ID hex correctly',
      () async {
        const validHex = '0102030405060708090a0b0c0d0e0f10';
        await prefs.setString('dronecan_unique_id', validHex);

        final container = ProviderContainer(
          overrides: [
            cannelloniServiceProvider.overrideWith(
              () => MockCannelloniService(),
            ),
            sharedPreferencesProvider.overrideWith((ref) => prefs),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(cannelloniServiceProvider.notifier);
        final uniqueId = await service.loadOrGenerateUniqueIdForTesting();

        expect(uniqueId.length, equals(16));
        expect(
          uniqueId,
          equals(
            Uint8List.fromList([
              1,
              2,
              3,
              4,
              5,
              6,
              7,
              8,
              9,
              10,
              11,
              12,
              13,
              14,
              15,
              16,
            ]),
          ),
        );
      },
    );

    test(
      'Generates and persists a new unique ID if not already saved',
      () async {
        expect(prefs.containsKey('dronecan_unique_id'), isFalse);

        final container = ProviderContainer(
          overrides: [
            cannelloniServiceProvider.overrideWith(
              () => MockCannelloniService(),
            ),
            sharedPreferencesProvider.overrideWith((ref) => prefs),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(cannelloniServiceProvider.notifier);
        final uniqueId = await service.loadOrGenerateUniqueIdForTesting();

        expect(uniqueId.length, equals(16));
        expect(prefs.containsKey('dronecan_unique_id'), isTrue);

        final savedHex = prefs.getString('dronecan_unique_id');
        expect(savedHex, isNotNull);
        expect(savedHex!.length, equals(32));
      },
    );

    test(
      'Recovers from malformed unique ID hex by regenerating and persisting a new one',
      () async {
        // 32-character string containing invalid hex characters like 'g'
        const malformedHex = 'g1g2g3g4g5g6g7g8g9g0g1g2g3g4g5g6';
        await prefs.setString('dronecan_unique_id', malformedHex);

        final container = ProviderContainer(
          overrides: [
            cannelloniServiceProvider.overrideWith(
              () => MockCannelloniService(),
            ),
            sharedPreferencesProvider.overrideWith((ref) => prefs),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(cannelloniServiceProvider.notifier);
        final uniqueId = await service.loadOrGenerateUniqueIdForTesting();

        // Ensure that parsing failure didn't bubble up, but successfully recovered
        expect(uniqueId.length, equals(16));

        // Verify that a new valid hex has been generated and written back to prefs
        final newHex = prefs.getString('dronecan_unique_id');
        expect(newHex, isNotNull);
        expect(newHex!.length, equals(32));
        expect(newHex, isNot(equals(malformedHex)));

        // Verify the new hex is valid by converting it back and comparing
        final parsedBack = Uint8List(16);
        for (int i = 0; i < 16; i++) {
          parsedBack[i] = int.parse(
            newHex.substring(i * 2, i * 2 + 2),
            radix: 16,
          );
        }
        expect(parsedBack, equals(uniqueId));
      },
    );
  });
}
