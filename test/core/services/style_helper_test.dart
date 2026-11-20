import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/style_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses the Mapterhorn terrain archive format and zoom limit', () async {
    final raw = await rootBundle.loadString('assets/openaip/styles.json');
    final style = jsonDecode(raw) as Map<String, dynamic>;

    final terrain = style['sources']['terrain'] as Map<String, dynamic>;
    expect(terrain['encoding'], 'terrarium');
    expect(terrain['tileSize'], 512);
    expect(terrain['maxzoom'], 12);
  });

  test('settlement labels allow overlap at different font sizes', () async {
    final raw = await rootBundle.loadString('assets/openaip/styles.json');
    for (final scale in [0.75, 1.5, 4.5]) {
      final style = jsonDecode(raw) as Map<String, dynamic>;
      StyleHelper.scaleLayers(style, scale);
      final layers = style['layers'] as List<dynamic>;
      final layout =
          layers.singleWhere(
                (layer) => layer['id'] == 'places_locality',
              )['layout']
              as Map<String, dynamic>;

      expect(layout['text-allow-overlap'], isTrue);
      expect(layout['text-overlap'], isNull);
      expect(layout['text-ignore-placement'], isTrue);
      expect(layout['icon-optional'], isTrue);
    }
  });

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

    test('scales step expression correctly (scales values/outputs, not thresholds)', () {
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
    });

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
