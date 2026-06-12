import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/utils/time_utils.dart';

void main() {
  group('DurationFormatter Extension Tests', () {
    test('formats zero duration correctly', () {
      expect(Duration.zero.toHMSString(), equals('00:00'));
    });

    test('formats duration under a minute correctly', () {
      const duration = Duration(seconds: 45);
      expect(duration.toHMSString(), equals('00:45'));
    });

    test('formats duration under an hour correctly', () {
      const duration = Duration(minutes: 5, seconds: 3);
      expect(duration.toHMSString(), equals('05:03'));
    });

    test('formats exactly one hour correctly', () {
      const duration = Duration(hours: 1);
      expect(duration.toHMSString(), equals('1:00:00'));
    });

    test('formats duration over one hour correctly', () {
      const duration = Duration(hours: 1, minutes: 12, seconds: 9);
      expect(duration.toHMSString(), equals('1:12:09'));
    });

    test('formats double-digit hours and multi-hour durations correctly', () {
      const duration = Duration(hours: 10, minutes: 5, seconds: 0);
      expect(duration.toHMSString(), equals('10:05:00'));
    });
  });
}
