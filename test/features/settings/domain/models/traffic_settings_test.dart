import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  group('Traffic Settings Default Values & CopyWith', () {
    test('default traffic settings are enabled and have standard ranges', () {
      const settings = AppSettings();
      expect(settings.trafficFilterMaxHorizontalDistanceEnabled, isTrue);
      expect(settings.trafficMaxHorizontalDistance, 50000.0);
      expect(settings.trafficFilterMaxVerticalDistanceEnabled, isTrue);
      expect(settings.trafficMaxVerticalDistance, 1500.0);
    });

    test('copyWith updates traffic settings correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        trafficFilterMaxHorizontalDistanceEnabled: false,
        trafficMaxHorizontalDistance: 30000.0,
        trafficFilterMaxVerticalDistanceEnabled: false,
        trafficMaxVerticalDistance: 1000.0,
      );

      expect(updated.trafficFilterMaxHorizontalDistanceEnabled, isFalse);
      expect(updated.trafficMaxHorizontalDistance, 30000.0);
      expect(updated.trafficFilterMaxVerticalDistanceEnabled, isFalse);
      expect(updated.trafficMaxVerticalDistance, 1000.0);
    });

    test('json serialization roundtrip preserves traffic settings', () {
      const settings = AppSettings(
        trafficFilterMaxHorizontalDistanceEnabled: false,
        trafficMaxHorizontalDistance: 25000.0,
        trafficFilterMaxVerticalDistanceEnabled: true,
        trafficMaxVerticalDistance: 2000.0,
      );

      final jsonMap = json.decode(json.encode(settings.toJson())) as Map<String, dynamic>;
      final deserialized = AppSettings.fromJson(jsonMap);

      expect(deserialized.trafficFilterMaxHorizontalDistanceEnabled, isFalse);
      expect(deserialized.trafficMaxHorizontalDistance, 25000.0);
      expect(deserialized.trafficFilterMaxVerticalDistanceEnabled, isTrue);
      expect(deserialized.trafficMaxVerticalDistance, 2000.0);
    });
  });

  group('AppSettingsNotifier Traffic Settings Provider Tests', () {
    late MockSettingsRepository mockRepository;

    setUp(() {
      mockRepository = MockSettingsRepository();
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const AppSettings());
      when(() => mockRepository.saveSettings(any()))
          .thenAnswer((_) async {});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
        ],
      );
      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);
      return container;
    }

    test('updateTrafficFilterMaxHorizontalDistanceEnabled updates state and persists', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final result = await notifier.updateTrafficFilterMaxHorizontalDistanceEnabled(false);
      expect(result, isA<SettingsUpdateSuccess>());

      final state = container.read(appSettingsProvider).value;
      expect(state?.trafficFilterMaxHorizontalDistanceEnabled, isFalse);
      verify(() => mockRepository.saveSettings(any(
        that: isA<AppSettings>().having(
          (s) => s.trafficFilterMaxHorizontalDistanceEnabled,
          'trafficFilterMaxHorizontalDistanceEnabled',
          isFalse,
        ),
      ))).called(1);
    });

    test('updateTrafficMaxHorizontalDistance clamps to lower boundary (1000.0)', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final result = await notifier.updateTrafficMaxHorizontalDistance(500.0);
      expect(result, isA<SettingsUpdateSuccess>());

      final state = container.read(appSettingsProvider).value;
      expect(state?.trafficMaxHorizontalDistance, equals(1000.0));
      expect(state?.trafficMaxHorizontalDistance, isA<double>());
    });

    test('updateTrafficMaxHorizontalDistance clamps to upper boundary (500000.0)', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final result = await notifier.updateTrafficMaxHorizontalDistance(600000.0);
      expect(result, isA<SettingsUpdateSuccess>());

      final state = container.read(appSettingsProvider).value;
      expect(state?.trafficMaxHorizontalDistance, equals(500000.0));
      expect(state?.trafficMaxHorizontalDistance, isA<double>());
    });

    test('updateTrafficFilterMaxVerticalDistanceEnabled updates state and persists', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final result = await notifier.updateTrafficFilterMaxVerticalDistanceEnabled(false);
      expect(result, isA<SettingsUpdateSuccess>());

      final state = container.read(appSettingsProvider).value;
      expect(state?.trafficFilterMaxVerticalDistanceEnabled, isFalse);
    });

    test('updateTrafficMaxVerticalDistance clamps to lower boundary (100.0)', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final result = await notifier.updateTrafficMaxVerticalDistance(50.0);
      expect(result, isA<SettingsUpdateSuccess>());

      final state = container.read(appSettingsProvider).value;
      expect(state?.trafficMaxVerticalDistance, equals(100.0));
      expect(state?.trafficMaxVerticalDistance, isA<double>());
    });

    test('updateTrafficMaxVerticalDistance clamps to upper boundary (20000.0)', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final result = await notifier.updateTrafficMaxVerticalDistance(30000.0);
      expect(result, isA<SettingsUpdateSuccess>());

      final state = container.read(appSettingsProvider).value;
      expect(state?.trafficMaxVerticalDistance, equals(20000.0));
      expect(state?.trafficMaxVerticalDistance, isA<double>());
    });
  });
}
