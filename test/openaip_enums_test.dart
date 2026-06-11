import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/presentation/utils/openaip_enums.dart';
import 'package:stork/l10n/app_localizations_en.dart';

void main() {
  group('OpenAipEnums Localization Tests', () {
    final l10nEn = AppLocalizationsEn();

    test('AirportType toLocalizedName returns correct values', () {
      expect(AirportType.airport.toLocalizedName(l10nEn), equals('Airport'));
      expect(AirportType.gliderSite.toLocalizedName(l10nEn), equals('Glider Site'));
      expect(AirportType.unknown.toLocalizedName(l10nEn), equals('Unknown (Unknown)'));
    });

    test('FrequencyType toLocalizedName returns correct values', () {
      expect(FrequencyType.approach.toLocalizedName(l10nEn), equals('Approach'));
      expect(FrequencyType.tower.toLocalizedName(l10nEn), equals('Tower'));
      expect(FrequencyType.unknown.toLocalizedName(l10nEn), equals('Unknown (Unknown)'));
    });

    test('RunwayComposition toLocalizedName returns correct values', () {
      expect(RunwayComposition.asphalt.toLocalizedName(l10nEn), equals('Asphalt'));
      expect(RunwayComposition.grass.toLocalizedName(l10nEn), equals('Grass'));
      expect(RunwayComposition.unknown.toLocalizedName(l10nEn), equals('Unknown'));
    });
  });
}
