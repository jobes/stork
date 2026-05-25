import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/speed_unit.dart';
import 'package:stork/l10n/app_localizations_en.dart';
import 'package:stork/l10n/app_localizations_sk.dart';

void main() {
  group('SpeedUnit Tests', () {
    final l10nEn = AppLocalizationsEn();
    final l10nSk = AppLocalizationsSk();

    test('convertFromMs converts correctly', () {
      expect(SpeedUnit.ms.convertFromMs(10.0), closeTo(10.0, 0.0001));
      expect(SpeedUnit.kmh.convertFromMs(10.0), closeTo(36.0, 0.0001));
      expect(SpeedUnit.mph.convertFromMs(10.0), closeTo(22.3694, 0.0001));
      expect(SpeedUnit.knots.convertFromMs(10.0), closeTo(19.4384, 0.0001));
    });

    test('convertToMs converts correctly', () {
      expect(SpeedUnit.ms.convertToMs(10.0), closeTo(10.0, 0.0001));
      expect(SpeedUnit.kmh.convertToMs(36.0), closeTo(10.0, 0.0001));
      expect(SpeedUnit.mph.convertToMs(22.3694), closeTo(10.0, 0.0001));
      expect(SpeedUnit.knots.convertToMs(19.4384), closeTo(10.0, 0.0001));
    });

    test('getLabel returns correct labels in English', () {
      expect(SpeedUnit.ms.getLabel(l10nEn), equals('m/s'));
      expect(SpeedUnit.kmh.getLabel(l10nEn), equals('kph'));
      expect(SpeedUnit.mph.getLabel(l10nEn), equals('mph'));
      expect(SpeedUnit.knots.getLabel(l10nEn), equals('knots'));
    });

    test('getAbbreviation returns correct abbreviations in English', () {
      expect(SpeedUnit.ms.getAbbreviation(l10nEn), equals('m/s'));
      expect(SpeedUnit.kmh.getAbbreviation(l10nEn), equals('kph'));
      expect(SpeedUnit.mph.getAbbreviation(l10nEn), equals('mph'));
      expect(SpeedUnit.knots.getAbbreviation(l10nEn), equals('kt'));
    });

    test('getLabel returns correct labels in Slovak', () {
      expect(SpeedUnit.ms.getLabel(l10nSk), equals('m/s'));
      expect(SpeedUnit.kmh.getLabel(l10nSk), equals('km/h'));
      expect(SpeedUnit.mph.getLabel(l10nSk), equals('mph'));
      expect(SpeedUnit.knots.getLabel(l10nSk), equals('uzly'));
    });

    test('getAbbreviation returns correct abbreviations in Slovak', () {
      expect(SpeedUnit.ms.getAbbreviation(l10nSk), equals('m/s'));
      expect(SpeedUnit.kmh.getAbbreviation(l10nSk), equals('km/h'));
      expect(SpeedUnit.mph.getAbbreviation(l10nSk), equals('mph'));
      expect(SpeedUnit.knots.getAbbreviation(l10nSk), equals('kt'));
    });
  });
}
