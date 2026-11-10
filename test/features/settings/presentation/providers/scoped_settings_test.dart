import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/settings/domain/models/speed_unit.dart';
import 'package:stork/features/settings/domain/models/widget_position.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

void main() {
  late SharedPreferences preferences;
  late SettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = SettingsRepository(preferences);
  });

  test(
    'migrates legacy values to the original aircraft and pilot on switch',
    () async {
      const legacy = AppSettings(
        autoSelectDevice: false,
        airplaneId: 'aircraft-a',
        pilotId: 'pilot-a',
        rpmMaxRange: 7400,
        flightSpeedMaxRange: 43,
        widgetPositions: {'speed_widget': WidgetPosition(top: 120, left: 45)},
      );
      await preferences.setString('app_settings', json.encode(legacy.toJson()));

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(subscription.close);

      final initial = await container.read(appSettingsProvider.future);
      expect(initial.rpmMaxRange, 7400);
      expect(initial.widgetPositions['speed_widget']?.left, 45);

      final notifier = container.read(appSettingsProvider.notifier);
      expect(
        await notifier.updateAirplaneId('aircraft-b'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(container.read(appSettingsProvider).value?.rpmMaxRange, 6000);
      expect(
        container.read(appSettingsProvider).value?.flightSpeedMaxRange,
        38.89,
      );

      expect(
        await notifier.updatePilotId('pilot-b'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(
        container.read(appSettingsProvider).value?.widgetPositions,
        isEmpty,
      );

      expect(
        await notifier.updateAirplaneId('aircraft-a'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(container.read(appSettingsProvider).value?.rpmMaxRange, 7400);
      expect(
        container.read(appSettingsProvider).value?.flightSpeedMaxRange,
        43,
      );

      expect(
        await notifier.updatePilotId('pilot-a'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(
        container
            .read(appSettingsProvider)
            .value
            ?.widgetPositions['speed_widget']
            ?.top,
        120,
      );

      // Both profile maps survive a restart and the ordinary AppSettings fields
      // remain available to existing consumers.
      final restored = await SettingsRepository(preferences).getSettings();
      expect(restored.airplaneId, 'aircraft-a');
      expect(restored.pilotId, 'pilot-a');
      expect(restored.rpmMaxRange, 7400);
      expect(restored.widgetPositions['speed_widget']?.left, 45);
    },
  );

  test('aircraft limits and pilot positions are independent', () async {
    await repository.saveSettings(
      const AppSettings(
        autoSelectDevice: false,
        airplaneId: 'aircraft-a',
        pilotId: 'pilot-a',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(appSettingsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(appSettingsProvider.future);
    final notifier = container.read(appSettingsProvider.notifier);

    expect(
      await notifier.updateRpmMaxRange(6900),
      isA<SettingsUpdateSuccess>(),
    );
    expect(
      await notifier.updateWidgetPosition('altitude_widget', 30, 60),
      isA<SettingsUpdateSuccess>(),
    );

    await notifier.updateAirplaneId('aircraft-b');
    expect(container.read(appSettingsProvider).value?.rpmMaxRange, 6000);
    // Switching aircraft does not change a pilot's layout.
    expect(
      container
          .read(appSettingsProvider)
          .value
          ?.widgetPositions['altitude_widget']
          ?.left,
      60,
    );
    await notifier.updateRpmMaxRange(7200);

    await notifier.updatePilotId('pilot-b');
    expect(container.read(appSettingsProvider).value?.rpmMaxRange, 7200);
    expect(container.read(appSettingsProvider).value?.widgetPositions, isEmpty);
    await notifier.updateWidgetPosition('altitude_widget', 170, 190);

    await notifier.updateAirplaneId('aircraft-a');
    expect(container.read(appSettingsProvider).value?.rpmMaxRange, 6900);
    expect(
      container
          .read(appSettingsProvider)
          .value
          ?.widgetPositions['altitude_widget']
          ?.top,
      170,
    );

    await notifier.updatePilotId('pilot-a');
    expect(
      container
          .read(appSettingsProvider)
          .value
          ?.widgetPositions['altitude_widget']
          ?.top,
      30,
    );

    // Read a new repository instance: persistent data, not in-memory cache.
    final persisted = SettingsRepository(preferences);
    expect(
      (await persisted.getAircraftLimitsFor('aircraft-b'))['rpmMaxRange'],
      7200,
    );
    final layout = await persisted.getWidgetLayoutForPilot('pilot-b');
    expect((layout['widgetPositions'] as Map)['altitude_widget']['left'], 190);
  });

  test('guest profiles remain separate from named profiles', () async {
    const legacy = AppSettings(
      autoSelectDevice: false,
      rpmMaxRange: 6800,
      widgetPositions: {'speed_widget': WidgetPosition(top: 9, left: 10)},
    );
    await preferences.setString('app_settings', json.encode(legacy.toJson()));
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(appSettingsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(appSettingsProvider.future);
    final notifier = container.read(appSettingsProvider.notifier);

    await notifier.updateAirplaneId('aircraft-1');
    await notifier.updatePilotId('pilot-1');
    expect(container.read(appSettingsProvider).value?.rpmMaxRange, 6000);
    expect(container.read(appSettingsProvider).value?.widgetPositions, isEmpty);

    await notifier.updateAirplaneId(null);
    await notifier.updatePilotId(null);
    expect(container.read(appSettingsProvider).value?.rpmMaxRange, 6800);
    expect(
      container
          .read(appSettingsProvider)
          .value
          ?.widgetPositions['speed_widget']
          ?.left,
      10,
    );
  });
  test(
    'rapid profile switches keep interleaved edits in their target profile',
    () async {
      await repository.saveSettings(
        const AppSettings(
          autoSelectDevice: false,
          airplaneId: 'a',
          pilotId: 'a',
          rpmMaxRange: 6900,
          widgetPositions: {'speed_widget': WidgetPosition(top: 10, left: 20)},
        ),
      );
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);
      final results = await Future.wait([
        notifier.updateAirplaneId('b'),
        notifier.updateRpmMaxRange(7200),
        notifier.updatePilotId('b'),
        notifier.updateWidgetPosition('speed_widget', 100, 200),
        notifier.updateAirplaneId('a'),
        notifier.updatePilotId('a'),
      ]);
      expect(results, everyElement(isA<SettingsUpdateSuccess>()));
      final restored = await repository.getSettings();
      expect(restored.airplaneId, 'a');
      expect(restored.pilotId, 'a');
      expect(restored.rpmMaxRange, 6900);
      expect(restored.widgetPositions['speed_widget']?.left, 20);
      expect((await repository.getAircraftLimitsFor('b'))['rpmMaxRange'], 7200);
      expect(
        (await repository.getWidgetLayoutForPilot(
          'b',
        ))['widgetPositions']['speed_widget']['left'],
        200,
      );
    },
  );

  test(
    'every aircraft limit survives switching and reload without changing global units',
    () async {
      final thresholds = RangeThresholds(
        inactiveMax: 1,
        minError: 2,
        minWarning: 3,
        maxWarning: 4,
        maxError: 5,
      );
      final initial = AppSettings(
        autoSelectDevice: false,
        airplaneId: 'a',
        speedUnit: SpeedUnit.knots,
        flightSpeedThresholds: thresholds,
        flightSpeedMaxRange: 55,
        oilTempThresholds: thresholds,
        oilTempMaxRange: 440,
        oilPressureThresholds: thresholds,
        oilPressureMaxRange: 900,
        fuelThresholds: thresholds,
        egtThresholds: thresholds,
        egtMaxRange: 1400,
        chtThresholds: thresholds,
        chtMaxRange: 480,
        rpmThresholds: thresholds,
        rpmMaxRange: 7100,
      );
      await repository.saveSettings(initial);
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);
      expect(
        await notifier.updateAirplaneId('b'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(
        await repository.getSettings(),
        const AppSettings(
          autoSelectDevice: false,
          airplaneId: 'b',
          speedUnit: SpeedUnit.knots,
        ),
      );
      expect(
        await notifier.updateAirplaneId('a'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(await SettingsRepository(preferences).getSettings(), initial);
    },
  );

  test(
    'failed switch keeps the active profile and allows a later retry',
    () async {
      final failingRepository = _FailingRepository(preferences);
      const initial = AppSettings(
        autoSelectDevice: false,
        airplaneId: 'a',
        rpmMaxRange: 6900,
      );
      await failingRepository.saveSettings(initial);
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => failingRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);
      failingRepository.fail = true;
      expect(
        await notifier.updateAirplaneId('b'),
        isA<SettingsUpdateFailure>(),
      );
      expect(container.read(appSettingsProvider).value, initial);
      expect(await repository.getSettings(), initial);
      failingRepository.fail = false;
      expect(
        await notifier.updateAirplaneId('b'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(
        await notifier.updateAirplaneId('a'),
        isA<SettingsUpdateSuccess>(),
      );
      expect(await repository.getSettings(), initial);
    },
  );
}

class _FailingRepository extends SettingsRepository {
  _FailingRepository(super.preferences);
  bool fail = false;
  @override
  Future<void> saveSettings(AppSettings settings) async {
    if (fail) throw StateError('Simulated write failure');
    await super.saveSettings(settings);
  }
}
