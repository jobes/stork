import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/presentation/utils/dronecan_formatters.dart';
import 'package:stork/l10n/app_localizations_en.dart';
import 'package:stork/l10n/app_localizations_sk.dart';

void main() {
  final l10nEn = AppLocalizationsEn();
  final l10nSk = AppLocalizationsSk();

  group('formatDroneCanNumber', () {
    test('formats numbers consistently', () {
      expect(formatDroneCanNumber(2), equals('2'));
      expect(formatDroneCanNumber(2.0), equals('2.0'));
      expect(formatDroneCanNumber(2.25), equals('2.25'));
    });
  });

  group('formatDroneCanParameterValue', () {
    test('formats numeric and string values', () {
      expect(
        formatDroneCanParameterValue(
          const DroneCanParamValue.integer(7),
          l10nEn,
        ),
        equals('7'),
      );
      expect(
        formatDroneCanParameterValue(const DroneCanParamValue.real(2), l10nEn),
        equals('2.0'),
      );
      expect(
        formatDroneCanParameterValue(
          const DroneCanParamValue.string('GPS'),
          l10nEn,
        ),
        equals('GPS'),
      );
      expect(
        formatDroneCanParameterValue(const DroneCanParamValue.empty(), l10nEn),
        isEmpty,
      );
    });

    test('localizes boolean values', () {
      expect(
        formatDroneCanParameterValue(
          const DroneCanParamValue.boolean(true),
          l10nEn,
        ),
        equals(l10nEn.dronecanParameterValueTrue),
      );
      expect(
        formatDroneCanParameterValue(
          const DroneCanParamValue.boolean(false),
          l10nSk,
        ),
        equals(l10nSk.dronecanParameterValueFalse),
      );
    });
  });

  group('formatDroneCanParameterInput', () {
    test('returns the raw text of editable values', () {
      expect(
        formatDroneCanParameterInput(const DroneCanParamValue.integer(7)),
        equals('7'),
      );
      expect(
        formatDroneCanParameterInput(const DroneCanParamValue.real(1.5)),
        equals('1.5'),
      );
      expect(
        formatDroneCanParameterInput(const DroneCanParamValue.string('GPS')),
        equals('GPS'),
      );
      expect(
        formatDroneCanParameterInput(const DroneCanParamValue.empty()),
        isEmpty,
      );
    });
  });
}
