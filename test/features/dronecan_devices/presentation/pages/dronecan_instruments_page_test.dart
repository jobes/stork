import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node_info_refresh.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_result.dart';
import 'package:stork/features/dronecan_devices/presentation/pages/dronecan_instruments_page.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_node_actions_provider.dart';
import 'package:stork/features/dronecan_devices/presentation/providers/dronecan_nodes_provider.dart';
import 'package:stork/features/dronecan_devices/presentation/utils/dronecan_formatters.dart';
import 'package:stork/l10n/app_localizations.dart';
import 'package:stork/l10n/app_localizations_en.dart';

class _ConnectedCannelloniService extends CannelloniService {
  @override
  bool build() => true;
}

class _DisconnectedCannelloniService extends CannelloniService {
  @override
  bool build() => false;
}

class _FakeNodesActions extends DroneCanNodesActions {
  _FakeNodesActions(this.refreshResult);

  final DroneCanResult<DroneCanNodeInfoRefresh> refreshResult;

  @override
  Future<DroneCanResult<DroneCanNodeInfoRefresh>> refreshAll() async =>
      refreshResult;
}

Widget _buildPage({
  required List<DroneCanNode> nodes,
  required bool connected,
  DroneCanNodesActions? actions,
}) {
  return ProviderScope(
    overrides: [
      droneCanNodesProvider.overrideWith((ref) => Stream.value(nodes)),
      cannelloniServiceProvider.overrideWith(
        () => connected
            ? _ConnectedCannelloniService()
            : _DisconnectedCannelloniService(),
      ),
      if (actions != null)
        droneCanNodesActionsProvider.overrideWith(() => actions),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DroneCanInstrumentsPage(),
    ),
  );
}

void main() {
  group('formatDroneCanLastSeen', () {
    final l10n = AppLocalizationsEn();

    test('shows hours, minutes and seconds with tenths', () {
      expect(
        formatDroneCanLastSeen(
          const Duration(hours: 2, minutes: 3, seconds: 4, milliseconds: 567),
          l10n,
        ),
        equals('2h 3m 4.5s'),
      );
      expect(
        formatDroneCanLastSeen(const Duration(milliseconds: 950), l10n),
        equals('0h 0m 0.9s'),
      );
      expect(
        formatDroneCanLastSeen(
          const Duration(minutes: 59, seconds: 59, milliseconds: 999),
          l10n,
        ),
        equals('0h 59m 59.9s'),
      );
    });

    test('truncates negative durations to zero', () {
      expect(
        formatDroneCanLastSeen(const Duration(seconds: -3), l10n),
        equals('0h 0m 0.0s'),
      );
    });
  });

  group('droneCanHealthColor', () {
    test('uses green for OK in both themes', () {
      expect(
        droneCanHealthColor(
          const ColorScheme.light(),
          DroneCanNodeHealth.ok,
          isDark: false,
        ),
        equals(const Color(0xFF2E7D32)),
      );
      expect(
        droneCanHealthColor(
          const ColorScheme.dark(),
          DroneCanNodeHealth.ok,
          isDark: true,
        ),
        equals(const Color(0xFF66BB6A)),
      );
    });
  });

  final node = DroneCanNode(
    nodeId: 42,
    name: 'com.example.ahrs',
    uniqueId: '0102030405060708090A0B0C0D0E0F10',
    health: DroneCanNodeHealth.ok,
    mode: DroneCanNodeMode.operational,
    uptimeSec: 3725,
    lastSeen: DateTime.now(),
    swMajor: 1,
    swMinor: 2,
    swOptionalFieldFlags: 5,
    swVcsCommit: 0xDEADBEEF,
    swImageCrc: '0123456789ABCDEF',
    hwMajor: 3,
    hwMinor: 4,
    certificateOfAuthenticity: 'AABB',
    vendorSpecificStatusCode: 0x1A2B,
  );

  testWidgets('renders the instrument table with node data', (tester) async {
    await tester.pumpWidget(_buildPage(nodes: [node], connected: true));
    await tester.pumpAndSettle();

    expect(find.text('DroneCAN instruments'), findsOneWidget);
    expect(find.text('Node ID'), findsOneWidget);
    expect(find.text('Unique ID'), findsOneWidget);
    expect(find.text('Last seen'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('com.example.ahrs'), findsOneWidget);
    expect(find.text('0102030405060708090A0B0C0D0E0F10'), findsOneWidget);
    expect(find.text('Operational'), findsOneWidget);
    expect(find.text('1h 2m 5s'), findsOneWidget);
  });

  testWidgets('opens node details dialog when the name is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(_buildPage(nodes: [node], connected: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('com.example.ahrs'));
    await tester.pumpAndSettle();

    final dialog = find.byType(BaseDetailsDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('ID 42')),
      findsOneWidget,
    );
    expect(find.text('Software version'), findsOneWidget);
    expect(find.text('1.2'), findsOneWidget);
    expect(find.text('VCS commit'), findsOneWidget);
    expect(find.text('0xDEADBEEF'), findsOneWidget);
    expect(find.text('Image CRC'), findsOneWidget);
    expect(find.text('0x0123456789ABCDEF'), findsOneWidget);
    expect(find.text('Hardware version'), findsOneWidget);
    expect(find.text('3.4'), findsOneWidget);
    expect(find.text('Certificate of authenticity'), findsOneWidget);
    expect(find.text('AABB'), findsOneWidget);
    expect(find.text('Vendor status code'), findsOneWidget);
    expect(find.text('0x1A2B'), findsOneWidget);

    // Data already shown in the table must not be duplicated in the dialog.
    for (final label in [
      'Node ID',
      'Name',
      'Unique ID',
      'Health',
      'Mode',
      'Uptime',
      'Last seen',
    ]) {
      expect(
        find.descendant(of: dialog, matching: find.text(label)),
        findsNothing,
      );
    }
    expect(find.text('com.example.ahrs'), findsNWidgets(2));
  });

  testWidgets('shows a message when GetNodeInfo data is missing', (
    tester,
  ) async {
    final nodeWithoutInfo = DroneCanNode(
      nodeId: 7,
      health: DroneCanNodeHealth.ok,
      mode: DroneCanNodeMode.offline,
      uptimeSec: 0,
      lastSeen: DateTime.now(),
      vendorSpecificStatusCode: 0x0042,
    );
    await tester.pumpWidget(
      _buildPage(nodes: [nodeWithoutInfo], connected: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('---').first);
    await tester.pumpAndSettle();

    expect(find.text('Details are not available yet.'), findsOneWidget);
    // The vendor status comes from the heartbeat, so it is shown regardless.
    expect(find.text('Vendor status code'), findsOneWidget);
    expect(find.text('0x0042'), findsOneWidget);
  });

  testWidgets('shows a disconnected state when no gateway is connected', (
    tester,
  ) async {
    await tester.pumpWidget(_buildPage(nodes: const [], connected: false));
    await tester.pumpAndSettle();

    expect(find.text('Not connected to a DroneCAN gateway'), findsOneWidget);
  });

  testWidgets('shows an empty state when connected without nodes', (
    tester,
  ) async {
    await tester.pumpWidget(_buildPage(nodes: const [], connected: true));
    await tester.pumpAndSettle();

    expect(find.text('No DroneCAN devices detected'), findsOneWidget);
  });

  group('refresh', () {
    Future<void> tapRefresh(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
    }

    testWidgets('reports how many nodes answered', (tester) async {
      await tester.pumpWidget(
        _buildPage(
          nodes: [node],
          connected: true,
          actions: _FakeNodesActions(
            const DroneCanSuccess(
              DroneCanNodeInfoRefresh(requested: 2, answered: 2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapRefresh(tester);

      expect(
        find.text('Node information refreshed for 2 nodes'),
        findsOneWidget,
      );
    });

    testWidgets('reports the nodes that did not answer', (tester) async {
      await tester.pumpWidget(
        _buildPage(
          nodes: [node],
          connected: true,
          actions: _FakeNodesActions(
            const DroneCanSuccess(
              DroneCanNodeInfoRefresh(requested: 3, answered: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapRefresh(tester);

      expect(find.text('Only 1 of 3 nodes answered'), findsOneWidget);
    });

    testWidgets('reports that there was nothing to refresh', (tester) async {
      await tester.pumpWidget(
        _buildPage(
          nodes: const [],
          connected: true,
          actions: _FakeNodesActions(
            const DroneCanSuccess(
              DroneCanNodeInfoRefresh(requested: 0, answered: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapRefresh(tester);

      expect(find.text('No DroneCAN node to refresh'), findsOneWidget);
    });

    testWidgets('reports a failed refresh', (tester) async {
      await tester.pumpWidget(
        _buildPage(
          nodes: [node],
          connected: true,
          actions: _FakeNodesActions(
            DroneCanFailure(StateError('transport gone')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapRefresh(tester);

      expect(find.text('Failed to refresh node information'), findsOneWidget);
    });
  });
}
