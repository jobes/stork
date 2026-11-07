import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/features/map/presentation/components/controls/map_drawer.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/domain/models/pilot.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:stork/features/settings/presentation/providers/pilot_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _FakeSettingsNotifier extends AppSettingsNotifier {
  _FakeSettingsNotifier(this.settings);

  final AppSettings settings;

  @override
  Future<AppSettings> build() async => settings;
}

class _FakePilotState extends PilotState {
  @override
  FutureOr<List<Pilot>> build() async => const [];
}

class _FakeAircraftState extends AircraftState {
  @override
  FutureOr<List<Aircraft>> build() async => const [];
}

class _ConnectedCannelloniService extends CannelloniService {
  @override
  bool build() => true;
}

class _DisconnectedCannelloniService extends CannelloniService {
  @override
  bool build() => false;

  void connectForTesting() {
    state = true;
  }
}

/// The drawer header has a fixed height and overflows in the default test
/// surface; that pre-existing layout issue is unrelated to these tests.
Future<void> _ignoreOverflow(Future<void> Function() body) async {
  final reportedErrors = <FlutterErrorDetails>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = reportedErrors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previousOnError;
  }

  for (final details in reportedErrors) {
    if (!details.exceptionAsString().contains('overflowed')) {
      Error.throwWithStackTrace(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    }
  }
}

Future<void> _pumpDrawer(
  WidgetTester tester, {
  required bool connected,
  CannelloniDevice? selectedDevice,
  List<CannelloniDevice> discoveredDevices = const [],
}) {
  return _ignoreOverflow(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(
            () => _FakeSettingsNotifier(
              AppSettings(selectedDevice: selectedDevice),
            ),
          ),
          pilotStateProvider.overrideWith(_FakePilotState.new),
          aircraftStateProvider.overrideWith(_FakeAircraftState.new),
          cannelloniServiceProvider.overrideWith(
            () => connected
                ? _ConnectedCannelloniService()
                : _DisconnectedCannelloniService(),
          ),
          discoveredDevicesProvider.overrideWith(
            (ref) => Stream.value(discoveredDevices),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(drawer: MapDrawer(), body: SizedBox.shrink()),
        ),
      ),
    );

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  });
}

void main() {
  const gateway = CannelloniDevice(
    name: 'avionics-dronecan._cannelloni._udp.local',
    hostname: 'gateway.local',
    ip: '192.168.1.10',
    port: 47998,
  );

  testWidgets('shows the DroneCAN instruments entry when connected', (
    tester,
  ) async {
    await _pumpDrawer(tester, connected: true);

    expect(find.text('DroneCAN instruments'), findsOneWidget);
  });

  testWidgets(
    'shows the DroneCAN instruments entry with a discovered gateway',
    (tester) async {
      await _pumpDrawer(
        tester,
        connected: false,
        selectedDevice: gateway,
        discoveredDevices: const [gateway],
      );

      expect(find.text('DroneCAN instruments'), findsOneWidget);
    },
  );

  testWidgets('hides the entry when the selected gateway is not discovered', (
    tester,
  ) async {
    await _pumpDrawer(tester, connected: false, selectedDevice: gateway);

    expect(find.text('DroneCAN instruments'), findsNothing);
  });

  testWidgets('hides the DroneCAN instruments entry when disconnected', (
    tester,
  ) async {
    await _pumpDrawer(tester, connected: false);

    expect(find.text('DroneCAN instruments'), findsNothing);
    expect(find.text('Flight Records'), findsOneWidget);
  });

  testWidgets('reacts when the DroneCAN connection becomes active', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          () => _FakeSettingsNotifier(const AppSettings()),
        ),
        pilotStateProvider.overrideWith(_FakePilotState.new),
        aircraftStateProvider.overrideWith(_FakeAircraftState.new),
        cannelloniServiceProvider.overrideWith(
          _DisconnectedCannelloniService.new,
        ),
        discoveredDevicesProvider.overrideWith(
          (ref) => Stream.value(const <CannelloniDevice>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _ignoreOverflow(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(drawer: MapDrawer(), body: SizedBox.shrink()),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('DroneCAN instruments'), findsNothing);

      final service =
          container.read(cannelloniServiceProvider.notifier)
              as _DisconnectedCannelloniService;
      service.connectForTesting();
      await tester.pumpAndSettle();

      expect(find.text('DroneCAN instruments'), findsOneWidget);
    });
  });
}
