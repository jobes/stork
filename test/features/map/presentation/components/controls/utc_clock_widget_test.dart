import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/solar_times.dart';
import 'package:stork/features/map/presentation/components/controls/utc_clock_widget.dart';
import 'package:stork/features/map/presentation/providers/map_clock_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/widgets/telemetry_card.dart';
import 'package:stork/l10n/app_localizations.dart';

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  void setWarningMinutes(int minutes) {
    state = AsyncData(
      state.requireValue.copyWith(sunsetWarningMinutes: minutes),
    );
  }
}

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
  testWidgets('clock warns only within the configured time before sunset', (
    tester,
  ) async {
    final settings = _Settings();
    final telemetry = _Telemetry();
    final times = calculateSolarTimes(
      latitude: 48.17,
      longitude: 17.21,
      start: DateTime.utc(2026, 11, 12),
      end: DateTime.utc(2026, 11, 13),
    );
    final sunset = times.firstTimeOf(SolarEvent.sunset)!;
    final start = sunset.subtract(const Duration(hours: 1));
    var now = start.subtract(const Duration(seconds: 1));

    await withClock(Clock(() => now), () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(() => settings),
            telemetryProvider.overrideWith(() => telemetry),
            mapSolarTimesProvider.overrideWithValue((
              today: times,
              tomorrow: const SolarTimes.empty(),
            )),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: UtcClockWidget()),
          ),
        ),
      );

      final clock = find.byType(UtcClockWidget);
      final theme = Theme.of(tester.element(clock));
      final normal = theme.colorScheme.onSurface;
      final warning = TelemetryCard.warningColor(isDark: false);
      Color? clockColor() => tester
          .widget<Text>(find.descendant(of: clock, matching: find.byType(Text)))
          .style
          ?.color;

      telemetry.fix(now);
      await tester.pump();
      expect(clockColor(), normal);

      now = start;
      await tester.pump(const Duration(seconds: 1));
      expect(clockColor(), warning);

      settings.setWarningMinutes(30);
      await tester.pump();
      expect(clockColor(), normal);

      now = sunset.subtract(const Duration(minutes: 15));
      await tester.pump(const Duration(seconds: 1));
      expect(clockColor(), normal, reason: 'The GPS fix is stale');
      telemetry.fix(now);
      await tester.pump();
      expect(clockColor(), warning);

      now = sunset;
      telemetry.fix(now);
      await tester.pump(const Duration(seconds: 1));
      expect(clockColor(), normal);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
