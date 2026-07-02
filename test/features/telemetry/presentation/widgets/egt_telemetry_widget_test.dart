import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/l10n/app_localizations.dart';
import 'package:stork/features/telemetry/presentation/widgets/egt_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/widgets/telemetry_card.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EgtTelemetryWidget Tests', () {
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
              home: const Scaffold(
                body: EgtTelemetryWidget(),
              ),
            );
          },
        ),
      );
    }

    testWidgets('renders nothing when there is no EGT data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TelemetryCard), findsNothing);
    });

    testWidgets('renders normally with multiple cylinders EGT', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1073.15 K = 800 °C (operational/green), 423.15 K = 150 °C (inactive/gray)
      providerContainer.read(telemetryProvider.notifier).updateIceStatus(
            engineSpeedRpm: 1200,
            exhaustGasTemperatures: [1073.15, 423.15],
          );
      await tester.pumpAndSettle();

      expect(find.byType(TelemetryCard), findsOneWidget);
      expect(find.text('EGT'), findsOneWidget);

      // Verify values are displayed
      expect(find.text('800'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('enters error state (shows error outline and red border) when EGT is null (disconnected)', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // First set active EGT with 2 cylinders to establish they are supported
      providerContainer.read(telemetryProvider.notifier).updateIceStatus(
            engineSpeedRpm: 1200,
            exhaustGasTemperatures: [1073.15, 423.15],
          );
      await tester.pumpAndSettle();

      // Disconnect EGT (triggers decay to all nulls)
      providerContainer.read(telemetryProvider.notifier).updateIceStatus(
            engineSpeedRpm: 1200,
            exhaustGasTemperatures: [null, null],
          );
      await tester.pumpAndSettle();

      expect(find.byType(TelemetryCard), findsOneWidget);
      expect(find.text('EGT'), findsOneWidget);

      // Verify "---" text is displayed for both cylinders
      expect(find.text('---'), findsNWidgets(2));
      expect(find.byIcon(Icons.error_outline), findsNWidgets(2));

      // Verify card has red border (error)
      final cardFinder = find.byType(TelemetryCard);
      final TelemetryCard card = tester.widget(cardFinder);
      expect(
        card.state == ThresholdState.maxError,
        isTrue,
      );
    });
  });
}
