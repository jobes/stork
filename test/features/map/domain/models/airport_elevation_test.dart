import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/airport_elevation.dart';
import 'package:stork/features/map/domain/models/openaip_unit.dart';
import 'package:stork/features/map/domain/models/reference_datum.dart';

void main() {
  // OpenAIP stores the reference datum as the enum index.
  AirportElevation elevation(
    double value,
    OpenAipUnit unit,
    ReferenceDatum datum,
  ) => AirportElevation(value: value, unit: unit, referenceDatum: datum.index);

  group('AirportElevation.metersMsl', () {
    test('returns MSL elevations in meters', () {
      expect(
        elevation(430, OpenAipUnit.meters, ReferenceDatum.msl).metersMsl,
        430,
      );
    });

    test('converts MSL elevations given in feet', () {
      expect(
        elevation(1000, OpenAipUnit.feet, ReferenceDatum.msl).metersMsl,
        closeTo(304.8, 0.001),
      );
    });

    test('ignores heights that are not referenced to mean sea level', () {
      expect(
        elevation(430, OpenAipUnit.meters, ReferenceDatum.gnd).metersMsl,
        isNull,
      );
      expect(
        elevation(430, OpenAipUnit.meters, ReferenceDatum.std).metersMsl,
        isNull,
      );
    });

    test('ignores units that do not describe a height', () {
      expect(
        elevation(430, OpenAipUnit.mhz, ReferenceDatum.msl).metersMsl,
        isNull,
      );
    });
  });
}
