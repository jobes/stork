import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';

void main() {
  group('DroneCanParamValue', () {
    test('compares numeric values across integer and real types', () {
      expect(
        const DroneCanParamValue.integer(
          1,
        ).sameAs(const DroneCanParamValue.real(1.0)),
        isTrue,
      );
      expect(
        const DroneCanParamValue.integer(
          1,
        ).sameAs(const DroneCanParamValue.integer(2)),
        isFalse,
      );
      expect(
        const DroneCanParamValue.string(
          'a',
        ).sameAs(const DroneCanParamValue.string('a')),
        isTrue,
      );
    });

    test('exposes the value kind', () {
      expect(
        const DroneCanParamValue.integer(1).type,
        equals(DroneCanParamValueType.integer),
      );
      expect(const DroneCanParamValue.empty().isEmpty, isTrue);
      expect(const DroneCanParamValue.integer(1).isNumeric, isTrue);
      expect(const DroneCanParamValue.real(1.5).isNumeric, isTrue);
      expect(const DroneCanParamValue.string('a').isNumeric, isFalse);
      expect(const DroneCanParamValue.boolean(true).booleanValue, isTrue);
      expect(const DroneCanParamValue.integer(1).booleanValue, isNull);
    });
  });

  group('DroneCanParameter', () {
    const parameter = DroneCanParameter(
      index: 3,
      name: 'ESC_INDEX',
      value: DroneCanParamValue.integer(2),
      defaultValue: DroneCanParamValue.real(2.0),
      minValue: 0,
      maxValue: 10,
    );

    test('treats numerically equal values as unmodified', () {
      expect(parameter.isModified, isFalse);
    });

    test('reports a value that differs from the default', () {
      expect(
        parameter.withValue(const DroneCanParamValue.integer(4)).isModified,
        isTrue,
      );
    });

    test('never marks a parameter without a default as modified', () {
      const withoutDefault = DroneCanParameter(
        index: 0,
        name: 'A',
        value: DroneCanParamValue.integer(1),
      );

      expect(withoutDefault.isModified, isFalse);
    });

    test('merges the node response and keeps the known metadata', () {
      final merged = parameter.merge(
        const DroneCanParameter(
          index: 0,
          name: 'ESC_INDEX',
          value: DroneCanParamValue.integer(4),
        ),
      );

      expect(merged.index, equals(3));
      expect(merged.value, equals(const DroneCanParamValue.integer(4)));
      expect(merged.defaultValue, equals(const DroneCanParamValue.real(2.0)));
      expect(merged.minValue, equals(0));
      expect(merged.maxValue, equals(10));
    });
  });
}
