import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/range_thresholds.dart';

void main() {
  group('RangeThresholds Boundary Invariant Tests', () {
    test('Valid combinations do not throw assertions', () {
      expect(
        () => const RangeThresholds(),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(
          inactiveMax: 10.0,
          minError: 20.0,
          minWarning: 30.0,
          maxWarning: 40.0,
          maxError: 50.0,
        ),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(inactiveMax: 10.0),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(minError: 20.0),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(minWarning: 30.0),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(maxWarning: 40.0),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(maxError: 50.0),
        returnsNormally,
      );

      expect(
        () => const RangeThresholds(inactiveMax: 10.0, maxError: 50.0),
        returnsNormally,
      );
    });

    test('minWarning < minError throws AssertionError', () {
      expect(
        () => RangeThresholds(minError: 20.0, minWarning: 10.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('maxWarning > maxError throws AssertionError', () {
      expect(
        () => RangeThresholds(maxWarning: 50.0, maxError: 40.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minError > maxError throws AssertionError', () {
      expect(
        () => RangeThresholds(minError: 50.0, maxError: 40.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('inactiveMax > minError throws AssertionError', () {
      expect(
        () => RangeThresholds(inactiveMax: 30.0, minError: 20.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('inactiveMax > minWarning throws AssertionError', () {
      expect(
        () => RangeThresholds(inactiveMax: 30.0, minWarning: 20.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('inactiveMax > maxWarning throws AssertionError', () {
      expect(
        () => RangeThresholds(inactiveMax: 50.0, maxWarning: 40.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('inactiveMax > maxError throws AssertionError', () {
      expect(
        () => RangeThresholds(inactiveMax: 60.0, maxError: 50.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minError > maxWarning throws AssertionError', () {
      expect(
        () => RangeThresholds(minError: 40.0, maxWarning: 30.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minWarning > maxWarning throws AssertionError', () {
      expect(
        () => RangeThresholds(minWarning: 40.0, maxWarning: 30.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minWarning > maxError throws AssertionError', () {
      expect(
        () => RangeThresholds(minWarning: 50.0, maxError: 40.0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('RangeThresholds evaluate Tests', () {
    const thresholds = RangeThresholds(
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
      const partial = RangeThresholds(
        minWarning: 30.0,
        maxWarning: 40.0,
      );
      expect(partial.evaluate(20.0), ThresholdState.minWarning);
      expect(partial.evaluate(30.0), ThresholdState.minWarning);
      expect(partial.evaluate(35.0), ThresholdState.operational);
      expect(partial.evaluate(40.0), ThresholdState.maxWarning);
      expect(partial.evaluate(50.0), ThresholdState.maxWarning);
    });
  });
}
