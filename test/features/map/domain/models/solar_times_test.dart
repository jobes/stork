import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/solar_times.dart';

void main() {
  // LZIB 48°10'12"N 17°12'46"E, USNO Sun and Moon Data (all times in UTC).
  // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-01-01&coords=48.17,17.2127778&tz=0
  const latitude = 48 + 10 / 60 + 12 / 3600;
  const longitude = 17 + 12 / 60 + 46 / 3600;
  final references = [
    (1, 1, [(6, 5), (6, 42), (15, 8), (15, 44)]),
    (6, 1, [(2, 15), (2, 55), (18, 43), (19, 23)]),
  ];

  for (final (month, day, times) in references) {
    test('matches the USNO LZIB times on 2026-$month-$day', () {
      final start = DateTime.utc(2026, month, day);
      final result = calculateSolarTimes(
        latitude: latitude,
        longitude: longitude,
        start: start,
        end: start.add(const Duration(days: 1)),
      );

      for (final (index, event) in SolarEvent.values.indexed) {
        final (hour, minute) = times[index];
        final expected = DateTime.utc(2026, month, day, hour, minute);
        final actual = result.firstTimeOf(event);
        expect(
          actual!.difference(expected).abs(),
          lessThanOrEqualTo(const Duration(seconds: 30)),
          reason: '$event expected $expected, calculated $actual',
        );
      }
    });
  }

  test('uses actual local midnight bounds across a daylight saving change', () {
    // Europe/Bratislava switches from UTC+1 to UTC+2 on March 29.
    final start = DateTime.utc(2026, 3, 28, 23);
    final end = DateTime.utc(2026, 3, 29, 22);
    final times = calculateSolarTimes(
      latitude: latitude,
      longitude: longitude,
      start: start,
      end: end,
    );

    expect(times.crossings, hasLength(4));
    expect(
      times
          .firstTimeOf(SolarEvent.civilDawn)!
          .difference(DateTime.utc(2026, 3, 29, 4, 5))
          .abs(),
      lessThanOrEqualTo(const Duration(seconds: 30)),
    );
  });

  test('includes events on both UTC dates of a local day at the date line', () {
    // Kiritimati, UTC+14, with longitude west of Greenwich.
    final start = DateTime.utc(2026, 6, 1, 10);
    final end = DateTime.utc(2026, 6, 2, 10);
    final times = calculateSolarTimes(
      latitude: 1.87,
      longitude: -157.4,
      start: start,
      end: end,
    );

    expect(times.crossings, hasLength(4));
    expect(times.firstTimeOf(SolarEvent.civilDawn)!.day, 1);
    expect(times.firstTimeOf(SolarEvent.civilDusk)!.day, 2);
    expect(
      times.crossings.every(
        (crossing) =>
            !crossing.time.isBefore(start) && crossing.time.isBefore(end),
      ),
      isTrue,
    );
  });

  test('returns no crossings during polar day', () {
    final times = calculateSolarTimes(
      latitude: 78.22,
      longitude: 15.65,
      start: DateTime.utc(2026, 6, 20),
      end: DateTime.utc(2026, 6, 21),
    );

    expect(times.crossings, isEmpty);
  });

  test('finds a short dip below the sunrise threshold in Tromsø', () {
    // Local May 18 (UTC+2) includes both crossings around solar midnight.
    final times = calculateSolarTimes(
      latitude: 69.6492,
      longitude: 18.9553,
      start: DateTime.utc(2026, 5, 17, 22),
      end: DateTime.utc(2026, 5, 18, 22),
    );

    expect(times.crossings.map((crossing) => crossing.event), [
      SolarEvent.sunset,
      SolarEvent.sunrise,
    ]);
    expect(
      times
          .firstTimeOf(SolarEvent.sunrise)!
          .difference(DateTime.utc(2026, 5, 17, 22, 52))
          .abs(),
      lessThan(const Duration(minutes: 1)),
    );
  });

  test('chooses dusk when it precedes dawn on the same local day', () {
    final midnight = DateTime.utc(2026, 4, 27, 22);
    final april28 = calculateSolarTimes(
      latitude: 69.6492,
      longitude: 18.9553,
      start: midnight,
      end: midnight.add(const Duration(days: 1)),
    );

    final beforeMidnight = nextCivilTwilight(
      now: midnight.subtract(const Duration(minutes: 1)),
      today: const SolarTimes.empty(),
      tomorrow: april28,
    );
    expect(beforeMidnight?.crossing.event, SolarEvent.civilDusk);
    expect(beforeMidnight?.tomorrow, isTrue);

    final afterMidnight = nextCivilTwilight(
      now: midnight,
      today: april28,
      tomorrow: const SolarTimes.empty(),
    );
    expect(afterMidnight?.crossing, beforeMidnight?.crossing);
    expect(afterMidnight?.tomorrow, isFalse);

    final atDusk = nextCivilTwilight(
      now: afterMidnight!.crossing.time,
      today: april28,
      tomorrow: const SolarTimes.empty(),
    );
    expect(atDusk?.crossing.event, SolarEvent.civilDawn);
  });
}
