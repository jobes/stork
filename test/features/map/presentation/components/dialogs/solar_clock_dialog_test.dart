import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/solar_times.dart';
import 'package:stork/features/map/presentation/components/dialogs/solar_clock_dialog.dart';
import 'package:stork/features/map/presentation/providers/map_clock_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState();

  void fix(DateTime now) {
    state = TelemetryState(
      latitude: 48.17,
      longitude: 17.21,
      gpsLastFixAt: now,
    );
  }
}

void main() {
  testWidgets('waits for a current GPS fix and switches to tomorrow at dusk', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final telemetry = _Telemetry();
    // Fix the solar day bounds independently of the test runner's timezone.
    SolarTimes timesForDay(int day) => calculateSolarTimes(
      latitude: 48.17,
      longitude: 17.21,
      start: DateTime.utc(2026, 11, day),
      end: DateTime.utc(2026, 11, day + 1),
    );
    final today = timesForDay(12);
    final tomorrow = timesForDay(13);
    final dusk = today.firstTimeOf(SolarEvent.civilDusk)!;
    var now = dusk.subtract(const Duration(seconds: 1));

    await withClock(Clock(() => now), () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryProvider.overrideWith(() => telemetry),
            mapSolarTimesProvider.overrideWithValue((
              today: today,
              tomorrow: tomorrow,
            )),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('sk'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const SolarClockDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('sk'));
      expect(find.text(l10n.gpsWaiting), findsOneWidget);
      expect(find.text(l10n.clockSunrise), findsNothing);
      telemetry.fix(now);
      await tester.pump();
      expect(find.text('BMCT'), findsOneWidget);
      expect(find.text('EECT'), findsOneWidget);
      expect(find.text(l10n.clockUntilDusk), findsOneWidget);

      now = dusk;
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l10n.clockUntilTomorrowDawn), findsOneWidget);

      now = now.add(const Duration(seconds: 11));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l10n.gpsWaiting), findsOneWidget);
      expect(find.text(l10n.clockUntilTomorrowDawn), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
