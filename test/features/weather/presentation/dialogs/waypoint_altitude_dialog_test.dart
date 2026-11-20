import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/weather/presentation/dialogs/waypoint_altitude_dialog.dart';
import 'package:stork/l10n/localizations.dart';

const _first = NavigationPoint(latitude: 48, longitude: 17, name: 'First');
const _edited = NavigationPoint(
  latitude: 49,
  longitude: 17,
  name: 'Edited',
  weatherAltitudeFeet: 2000,
);

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(points: [_first, _edited]);

  @override
  Future<void> removePoint(int index) async {
    final points = [...state.value!.points]..removeAt(index);
    state = AsyncData(NavigationState(points: points));
  }

  @override
  Future<void> updatePointWeatherAltitude(int index, int? feet) async {
    final points = [...state.value!.points];
    points[index] = points[index].withWeatherAltitude(feet);
    state = AsyncData(NavigationState(points: points));
  }
}

void main() {
  for (final action in ['remove earlier', 'remove edited', 'default']) {
    testWidgets('altitude save handles $action while the dialog is open', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appSettingsProvider.overrideWith(_Settings.new),
          navigationProvider.overrideWith(_Navigation.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showWaypointAltitudeDialog(
                    context,
                    ref,
                    waypoint: _edited,
                    waypointIndex: 1,
                    defaultFeet: null,
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      if (action == 'default') {
        await tester.tap(find.text('Default'));
      } else {
        await tester.enterText(find.byType(TextFormField), '3200');
        await container
            .read(navigationProvider.notifier)
            .removePoint(action == 'remove earlier' ? 0 : 1);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      final points = container.read(navigationProvider).value!.points;
      if (action == 'remove earlier') {
        expect(points.single.name, 'Edited');
        expect(points.single.weatherAltitudeFeet, 3200);
      } else if (action == 'remove edited') {
        expect(points.single, same(_first));
        expect(points.single.weatherAltitudeFeet, isNull);
      } else {
        expect(points.last.weatherAltitudeFeet, isNull);
      }
    });
  }
}
