import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/map/presentation/components/controls/map_widget_wrapper.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/widget_position.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

void main() {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets(
      'map layout follows pilot and preserves drag lock in ${theme.brightness}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final repo = SettingsRepository(await SharedPreferences.getInstance());
        await repo.saveSettings(
          const AppSettings(
            autoSelectDevice: false,
            pilotId: 'a',
            widgetPositions: {
              'instrument': WidgetPosition(top: 100, left: 100),
            },
          ),
        );
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith((ref) async => repo),
          ],
        );
        addTearDown(container.dispose);
        const instrument = ValueKey('instrument');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              home: const Scaffold(
                body: Stack(
                  children: [
                    MapWidgetWrapper(
                      widgetId: 'instrument',
                      child: SizedBox(
                        key: instrument,
                        width: 100,
                        height: 40,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(instrument)),
          const Offset(100, 100),
        );
        await tester.drag(find.byKey(instrument), const Offset(30, 20));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(instrument)),
          const Offset(100, 100),
        );
        final notifier = container.read(appSettingsProvider.notifier);
        await notifier.updatePilotId('b');
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(instrument)), const Offset(16, 50));
        await notifier.updateAreWidgetsDraggable(true);
        await tester.pumpAndSettle();
        await tester.drag(find.byKey(instrument), const Offset(80, 60));
        await tester.pumpAndSettle();
        final moved = container
            .read(appSettingsProvider)
            .value!
            .widgetPositions['instrument']!;
        expect(moved.left, greaterThan(16));
        expect(moved.top, greaterThan(50));
        await notifier.updateAreWidgetsDraggable(false);
        await notifier.updatePilotId('a');
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(instrument)),
          const Offset(100, 100),
        );
        await notifier.updatePilotId('b');
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(instrument)),
          Offset(moved.left, moved.top),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
