import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/style_helper.dart';

void main() {
  group('StyleHelper.scaleTextSize', () {
    test('scales simple numeric values', () {
      expect(StyleHelper.scaleTextSize(12, 1.5), 18.0);
      expect(StyleHelper.scaleTextSize(12, 1.0), 12);
    });

    test(
      'scales interpolate expression correctly (scales values, not thresholds)',
      () {
        final input = [
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          12,
          14,
          16,
        ];
        final expected = [
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          18.0,
          14,
          24.0,
        ];
        expect(StyleHelper.scaleTextSize(input, 1.5), expected);
      },
    );

    test(
      'scales step expression correctly (scales values/outputs, not thresholds)',
      () {
        final input = [
          'step',
          ['zoom'],
          12,
          10,
          14,
          15,
          16,
        ];
        final expected = [
          'step',
          ['zoom'],
          18.0,
          10,
          21.0,
          15,
          24.0,
        ];
        expect(StyleHelper.scaleTextSize(input, 1.5), expected);
      },
    );

    test('returns unmodified value if fontSize is 1.0', () {
      final input = [
        'step',
        ['zoom'],
        12,
        10,
        14,
        15,
        16,
      ];
      expect(StyleHelper.scaleTextSize(input, 1.0), input);
    });
  });
}
