import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/l10n/app_localizations.dart';
import 'package:stork/features/telemetry/presentation/widgets/cylinder_temp_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/widgets/telemetry_card.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CylinderTempTelemetryWidget Tests', () {
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
              home: const Scaffold(body: CylinderTempTelemetryWidget()),
            );
          },
        ),
      );
    }

    testWidgets('renders nothing when there is no cylinder data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TelemetryCard), findsNothing);
    });

    testWidgets('renders normally with multiple cylinders', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 363.15 K = 90 °C (operational/green), 323.15 K = 50 °C (inactive/gray)
      providerContainer
          .read(telemetryProvider.notifier)
          .updateIceStatus(
            engineSpeedRpm: 1200,
            cylinderHeadTemperatures: [363.15, 323.15],
          );
      await tester.pumpAndSettle();

      expect(find.byType(TelemetryCard), findsOneWidget);
      expect(find.text('CHT'), findsOneWidget);

      // Verify C1 and C2 labels are NOT shown
      expect(find.text('C1'), findsNothing);
      expect(find.text('C2'), findsNothing);

      // Verify values are displayed
      expect(find.text('90'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets(
      'enters error state (shows error outline and red border) when CHT is null (disconnected)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // First set active CHT with 2 cylinders to establish they are supported
        providerContainer
            .read(telemetryProvider.notifier)
            .updateIceStatus(
              engineSpeedRpm: 1200,
              cylinderHeadTemperatures: [363.15, 323.15],
            );
        await tester.pumpAndSettle();

        // Disconnect CHT (triggers decay to all nulls)
        providerContainer
            .read(telemetryProvider.notifier)
            .updateIceStatus(
              engineSpeedRpm: 1200,
              cylinderHeadTemperatures: [null, null],
            );
        await tester.pumpAndSettle();

        expect(find.byType(TelemetryCard), findsOneWidget);
        expect(find.text('CHT'), findsOneWidget);

        // Verify "---" text is displayed for both cylinders
        expect(find.text('---'), findsNWidgets(2));
        expect(find.byIcon(Icons.error_outline), findsNWidgets(2));

        // Verify card has red border (error)
        final cardFinder = find.byType(TelemetryCard);
        final TelemetryCard card = tester.widget(cardFinder);
        expect(card.state == ThresholdState.maxError, isTrue);
      },
    );
  });
}
