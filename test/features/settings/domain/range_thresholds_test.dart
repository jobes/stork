import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';

void main() {
  group('RangeThresholds Boundary Invariant Tests', () {
    test('Valid combinations do not throw assertions', () {
      expect(() => RangeThresholds(), returnsNormally);

      expect(
        () => RangeThresholds(
          inactiveMax: 10.0,
          minError: 20.0,
          minWarning: 30.0,
          maxWarning: 40.0,
          maxError: 50.0,
        ),
        returnsNormally,
      );

      expect(() => RangeThresholds(inactiveMax: 10.0), returnsNormally);

      expect(() => RangeThresholds(minError: 20.0), returnsNormally);

      expect(() => RangeThresholds(minWarning: 30.0), returnsNormally);

      expect(() => RangeThresholds(maxWarning: 40.0), returnsNormally);

      expect(() => RangeThresholds(maxError: 50.0), returnsNormally);

      expect(
        () => RangeThresholds(inactiveMax: 10.0, maxError: 50.0),
        returnsNormally,
      );
    });

    test('minWarning < minError throws ArgumentError', () {
      expect(
        () => RangeThresholds(minError: 20.0, minWarning: 10.0),
        throwsArgumentError,
      );
    });

    test('maxWarning > maxError throws ArgumentError', () {
      expect(
        () => RangeThresholds(maxWarning: 50.0, maxError: 40.0),
        throwsArgumentError,
      );
    });

    test('minError > maxError throws ArgumentError', () {
      expect(
        () => RangeThresholds(minError: 50.0, maxError: 40.0),
        throwsArgumentError,
      );
    });

    test('inactiveMax > minError throws ArgumentError', () {
      expect(
        () => RangeThresholds(inactiveMax: 30.0, minError: 20.0),
        throwsArgumentError,
      );
    });

    test('inactiveMax > minWarning throws ArgumentError', () {
      expect(
        () => RangeThresholds(inactiveMax: 30.0, minWarning: 20.0),
        throwsArgumentError,
      );
    });

    test('inactiveMax > maxWarning throws ArgumentError', () {
      expect(
        () => RangeThresholds(inactiveMax: 50.0, maxWarning: 40.0),
        throwsArgumentError,
      );
    });

    test('inactiveMax > maxError throws ArgumentError', () {
      expect(
        () => RangeThresholds(inactiveMax: 60.0, maxError: 50.0),
        throwsArgumentError,
      );
    });

    test('minError > maxWarning throws ArgumentError', () {
      expect(
        () => RangeThresholds(minError: 40.0, maxWarning: 30.0),
        throwsArgumentError,
      );
    });

    test('minWarning > maxWarning throws ArgumentError', () {
      expect(
        () => RangeThresholds(minWarning: 40.0, maxWarning: 30.0),
        throwsArgumentError,
      );
    });

    test('minWarning > maxError throws ArgumentError', () {
      expect(
        () => RangeThresholds(minWarning: 50.0, maxError: 40.0),
        throwsArgumentError,
      );
    });
  });

  group('RangeThresholds evaluate Tests', () {
    const thresholds = RangeThresholds.raw(
      inactiveMax: 10.0,
      minError: 20.0,
      minWarning: 30.0,
      maxWarning: 40.0,
      maxError: 50.0,
    );

    test('value <= inactiveMax returns inactive', () {
      expect(thresholds.evaluate(5.0), ThresholdState.inactive);
      expect(thresholds.evaluate(10.0), ThresholdState.inactive);
    });

    test('inactiveMax < value <= minError returns minError', () {
      expect(thresholds.evaluate(15.0), ThresholdState.minError);
      expect(thresholds.evaluate(20.0), ThresholdState.minError);
    });

    test('minError < value <= minWarning returns minWarning', () {
      expect(thresholds.evaluate(25.0), ThresholdState.minWarning);
      expect(thresholds.evaluate(30.0), ThresholdState.minWarning);
    });

    test('minWarning < value < maxWarning returns operational', () {
      expect(thresholds.evaluate(35.0), ThresholdState.operational);
    });

    test('maxWarning <= value < maxError returns maxWarning', () {
      expect(thresholds.evaluate(40.0), ThresholdState.maxWarning);
      expect(thresholds.evaluate(45.0), ThresholdState.maxWarning);
    });

    test('value >= maxError returns maxError', () {
      expect(thresholds.evaluate(50.0), ThresholdState.maxError);
      expect(thresholds.evaluate(55.0), ThresholdState.maxError);
    });

    test('with null thresholds returns operational or correct subset', () {
      const partial = RangeThresholds.raw(minWarning: 30.0, maxWarning: 40.0);
      expect(partial.evaluate(20.0), ThresholdState.minWarning);
      expect(partial.evaluate(30.0), ThresholdState.minWarning);
      expect(partial.evaluate(35.0), ThresholdState.operational);
      expect(partial.evaluate(40.0), ThresholdState.maxWarning);
      expect(partial.evaluate(50.0), ThresholdState.maxWarning);
    });
  });

  group('RangeThresholds.fromJson validation Tests', () {
    test('Valid JSON deserializes normally', () {
      final json = {
        'inactiveMax': 10.0,
        'minError': 20.0,
        'minWarning': 30.0,
        'maxWarning': 40.0,
        'maxError': 50.0,
      };
      expect(() => RangeThresholds.fromJson(json), returnsNormally);
      final thresholds = RangeThresholds.fromJson(json);
      expect(thresholds.inactiveMax, 10.0);
      expect(thresholds.minError, 20.0);
      expect(thresholds.minWarning, 30.0);
      expect(thresholds.maxWarning, 40.0);
      expect(thresholds.maxError, 50.0);
    });

    test('Invalid JSON (minWarning < minError) throws ArgumentError', () {
      final json = {'minError': 20.0, 'minWarning': 10.0};
      expect(() => RangeThresholds.fromJson(json), throwsArgumentError);
    });

    test('Invalid JSON (inactiveMax > minError) throws ArgumentError', () {
      final json = {'inactiveMax': 30.0, 'minError': 20.0};
      expect(() => RangeThresholds.fromJson(json), throwsArgumentError);
    });
  });
}
