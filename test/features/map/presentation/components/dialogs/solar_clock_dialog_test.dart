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
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSolarClockDialog(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('sk'));
      expect(find.text(l10n.gpsWaiting), findsOneWidget);
      expect(find.text(l10n.clockSunrise), findsNothing);
      expect(find.text('Dĺžka dňa: nedostupná'), findsOneWidget);
      telemetry.fix(now);
      await tester.pump();
      expect(find.text(l10n.clockCivilDawnAbbrev), findsOneWidget);
      expect(find.text(l10n.clockCivilDuskAbbrev), findsOneWidget);
      expect(find.text('Dĺžka dňa: 9 h 24 min'), findsOneWidget);
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

  testWidgets('shows unavailable day length with a fix during polar night', (
    tester,
  ) async {
    final telemetry = _Telemetry();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telemetryProvider.overrideWith(() => telemetry),
          mapSolarTimesProvider.overrideWithValue((
            today: const SolarTimes.empty(),
            tomorrow: const SolarTimes.empty(),
          )),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSolarClockDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    telemetry.fix(clock.now());
    await tester.pump();
    expect(find.text('Day length: unavailable'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Waiting for GPS...'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
