import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/map/utils/openaip_enums.dart';
import 'package:stork/l10n/app_localizations_en.dart';

void main() {
  group('OpenAipEnums Localization Tests', () {
    final l10nEn = AppLocalizationsEn();

    test('AirportType toLocalizedName returns correct values', () {
      expect(AirportType.airport.toLocalizedName(l10nEn), equals('Airport'));
      expect(
        AirportType.gliderSite.toLocalizedName(l10nEn),
        equals('Glider Site'),
      );
      expect(
        AirportType.unknown.toLocalizedName(l10nEn),
        equals('Unknown (Unknown)'),
      );
    });

    test('FrequencyType toLocalizedName returns correct values', () {
      expect(
        FrequencyType.approach.toLocalizedName(l10nEn),
        equals('Approach'),
      );
      expect(FrequencyType.tower.toLocalizedName(l10nEn), equals('Tower'));
      expect(
        FrequencyType.unknown.toLocalizedName(l10nEn),
        equals('Unknown (Unknown)'),
      );
    });

    test('RunwayComposition toLocalizedName returns correct values', () {
      expect(
        RunwayComposition.asphalt.toLocalizedName(l10nEn),
        equals('Asphalt'),
      );
      expect(RunwayComposition.grass.toLocalizedName(l10nEn), equals('Grass'));
      expect(
        RunwayComposition.unknown.toLocalizedName(l10nEn),
        equals('Unknown'),
      );
    });

    test('AirspaceClass toLocalizedName returns correct values', () {
      expect(AirspaceClass.a.toLocalizedName(l10nEn), equals('Class A'));
      expect(
        AirspaceClass.unclassified.toLocalizedName(l10nEn),
        equals('Unclassified / SUA'),
      );
      expect(
        AirspaceClass.unknown.toLocalizedName(l10nEn),
        equals('Unknown class'),
      );
    });

    test('AirspaceType toLocalizedName returns correct values', () {
      expect(AirspaceType.ctr.toLocalizedName(l10nEn), equals('CTR'));
      expect(
        AirspaceType.restricted.toLocalizedName(l10nEn),
        equals('Restricted'),
      );
      expect(AirspaceType.unknown.toLocalizedName(l10nEn), equals('Unknown'));
    });

    test('AirspaceActivity toLocalizedName returns correct values', () {
      expect(
        AirspaceActivity.parachuting.toLocalizedName(l10nEn),
        equals('Parachuting'),
      );
      expect(
        AirspaceActivity.gliding.toLocalizedName(l10nEn),
        equals('Gliding'),
      );
      expect(AirspaceActivity.none.toLocalizedName(l10nEn), equals('None'));
    });

    test('ReferenceDatum toLocalizedName returns correct values', () {
      expect(ReferenceDatum.gnd.toLocalizedName(l10nEn), equals('GND'));
      expect(ReferenceDatum.msl.toLocalizedName(l10nEn), equals('MSL'));
    });

    test(
      'AirspaceLimit formatLimit formats flightLevel and standard units correctly',
      () {
        final flightLevelLimit = AirspaceLimit(
          value: 95.0,
          unit: OpenAipUnit.flightLevel,
          referenceDatum: ReferenceDatum.std,
        );
        final feetLimit = AirspaceLimit(
          value: 5000.0,
          unit: OpenAipUnit.feet,
          referenceDatum: ReferenceDatum.msl,
        );

        expect(flightLevelLimit.formatLimit(l10nEn), equals('FL 95'));
        expect(feetLimit.formatLimit(l10nEn), equals('5000 ft MSL'));
      },
    );

    test('AirportImage formats URL endpoints correctly', () {
      final img = AirportImage(id: 'img1', filename: 'airport.jpg');
      expect(
        img.getThumbnailUrl('my_api_key'),
        contains('width=200&height=200&apiKey=my_api_key'),
      );
      expect(img.getFullSizeUrl('my_api_key'), endsWith('apiKey=my_api_key'));
    });
  });
}
