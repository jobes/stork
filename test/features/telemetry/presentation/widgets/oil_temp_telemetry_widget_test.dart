import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/l10n/app_localizations.dart';
import 'package:stork/features/telemetry/presentation/widgets/oil_temp_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/widgets/telemetry_card.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OilTempTelemetryWidget Tests', () {
    late ProviderContainer providerContainer;

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            providerContainer = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: OilTempTelemetryWidget()),
            );
          },
        ),
      );
    }

    testWidgets('renders normally when temperature is valid', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Update telemetry with a valid temperature (e.g., 363.15 K = 90 °C, which is normal/operational)
      providerContainer
          .read(telemetryProvider.notifier)
          .updateIceStatus(engineSpeedRpm: 1000, oilTemperature: 363.15);
      await tester.pumpAndSettle();

      // Verify temperature is displayed
      expect(find.text('90'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter != null &&
              widget.painter.runtimeType.toString() == 'SegmentedGaugePainter',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsNothing);

      // Verify it's not showing error colors for the border/card
      final cardFinder = find.byType(TelemetryCard);
      expect(cardFinder, findsOneWidget);
      final TelemetryCard card = tester.widget(cardFinder);
      expect(card.borderColor, isNot(equals(Colors.red.shade600)));
      expect(card.borderColor, isNot(equals(Colors.redAccent.shade200)));
    });

    testWidgets(
      'enters error state (shows error icon, ---, and red border) when signal is lost (null)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Update telemetry with null temperature
        providerContainer
            .read(telemetryProvider.notifier)
            .updateIceStatus(engineSpeedRpm: 1000, oilTemperature: null);
        await tester.pumpAndSettle();

        // Verify "---" text is displayed
        expect(find.text('---'), findsOneWidget);

        // Verify custom painter is not used, and error icon is displayed instead
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint &&
                widget.painter != null &&
                widget.painter.runtimeType.toString() ==
                    'SegmentedGaugePainter',
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Verify card has red border (error)
        final cardFinder = find.byType(TelemetryCard);
        expect(cardFinder, findsOneWidget);
        final TelemetryCard card = tester.widget(cardFinder);

        // Since default theme brightness is light, we check for light-mode error color (Colors.red.shade600)
        expect(card.state == ThresholdState.maxError, isTrue);
      },
    );
  });
}
