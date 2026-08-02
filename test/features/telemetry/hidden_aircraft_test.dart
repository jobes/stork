import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';

void main() {
  group('Hidden Aircraft Tests', () {
    test(
      'hideAircraft and unhideAircraft update AppSettings hiddenAircraftIds correctly',
      () {
        const settings = AppSettings();
        expect(settings.hiddenAircraftIds, isEmpty);

        final updated1 = settings.copyWith(
          hiddenAircraftIds: {'flrdda5e6', 'ogn123456'},
        );
        expect(updated1.hiddenAircraftIds, contains('flrdda5e6'));
        expect(updated1.hiddenAircraftIds, contains('ogn123456'));

        final updated2 = updated1.copyWith(
          hiddenAircraftIds: Set<String>.from(updated1.hiddenAircraftIds)
            ..remove('flrdda5e6'),
        );
        expect(updated2.hiddenAircraftIds, isNot(contains('flrdda5e6')));
        expect(updated2.hiddenAircraftIds, contains('ogn123456'));
      },
    );

    test('hiddenAircraftIds defaults to an empty set', () {
      const settings = AppSettings();
      expect(settings.hiddenAircraftIds, isEmpty);
      expect(settings.hiddenAircraftIds, isA<Set<String>>());
    });
  });
}
