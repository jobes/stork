import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/pressure_unit.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';

void main() {
  group('AppSettings copyWithValidatedOilPressureMaxRange Tests', () {
    test('Preserves fractional values in bar mode', () {
      const settings = AppSettings(
        pressureUnit: PressureUnit.bar,
        oilPressureThresholds: RangeThresholds.raw(
          inactiveMax: 50.0, // 0.5 bar
          minError: 80.0,    // 0.8 bar
          minWarning: 200.0, // 2.0 bar
          maxWarning: 500.0, // 5.0 bar
          maxError: 700.0,   // 7.0 bar
        ),
        oilPressureMaxRange: 800.0, // 8.0 bar
      );

      final updated = settings.copyWithValidatedOilPressureMaxRange(
        8.0, // maxRange in bar (which translates to 800.0 kPa)
        defaultMaxRangeKpa: 800.0,
        defaultInactiveMaxKpa: 50.0,
        defaultMinErrorKpa: 80.0,
        defaultMinWarningKpa: 200.0,
        defaultMaxWarningKpa: 500.0,
        defaultMaxErrorKpa: 700.0,
        minRangeLimit: 1.0,
        maxRangeLimit: 20.0,
      );

      // Verify that thresholds like 0.5 bar (50 kPa) and 0.8 bar (80 kPa) are preserved.
      expect(updated.oilPressureThresholds.inactiveMax, closeTo(50.0, 0.001));
      expect(updated.oilPressureThresholds.minError, closeTo(80.0, 0.001));
      expect(updated.oilPressureThresholds.minWarning, closeTo(200.0, 0.001));
      expect(updated.oilPressureThresholds.maxWarning, closeTo(500.0, 0.001));
      expect(updated.oilPressureThresholds.maxError, closeTo(700.0, 0.001));
    });

    test('Rounds to whole unit in kPa/psi mode (no fractional places)', () {
      const settings = AppSettings(
        pressureUnit: PressureUnit.kPa,
        oilPressureThresholds: RangeThresholds.raw(
          inactiveMax: 50.5,
          minError: 80.9,
          minWarning: 200.1,
          maxWarning: 500.0,
          maxError: 700.0,
        ),
        oilPressureMaxRange: 800.0,
      );

      final updated = settings.copyWithValidatedOilPressureMaxRange(
        800.0, // maxRange in kPa
        defaultMaxRangeKpa: 800.0,
        defaultInactiveMaxKpa: 50.0,
        defaultMinErrorKpa: 80.0,
        defaultMinWarningKpa: 200.0,
        defaultMaxWarningKpa: 500.0,
        defaultMaxErrorKpa: 700.0,
        minRangeLimit: 100.0,
        maxRangeLimit: 2000.0,
      );

      // Verify that thresholds are rounded to nearest whole double (since kPa decimalPlaces is 0)
      expect(updated.oilPressureThresholds.inactiveMax, equals(51.0));
      expect(updated.oilPressureThresholds.minError, equals(81.0));
      expect(updated.oilPressureThresholds.minWarning, equals(200.0));
    });
  });
}
