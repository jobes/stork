import '../../../../support/prepared_map_style.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart'
    as platform;
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/pages/offline_maps_page.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/l10n/localizations.dart';

import '../../../../support/map_style_backend.dart';

class _Platform extends platform.MapLibrePlatform {
  late _NativeMap map;
  @override
  platform.MapLibreMapState createWidgetState() => map = _NativeMap();
}

class _NativeMap extends platform.MapLibreMapState {
  @override
  final TestStyle style = TestStyle();
  @override
  void initState() {
    super.initState();
    camera = const CameraPosition(
      center: Geographic(lon: 17, lat: 48),
      zoom: 6,
      bearing: 0,
      pitch: 0,
    );
    isInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMapCreated?.call(this);
    });
  }

  void display(double longitude) => setState(() {
    camera = CameraPosition(
      center: Geographic(lon: longitude, lat: 48),
      zoom: 6,
      bearing: 0,
      pitch: 0,
    );
  });
  @override
  Offset toScreenLocation(Geographic point) =>
      Offset(point.lon + camera!.center.lon, point.lat);
  @override
  Widget buildPlatformWidget(BuildContext context) => const SizedBox.expand();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _OfflineMaps extends OfflineMapsNotifier {
  @override
  OfflineMapsState build() => OfflineMapsState();

  @override
  Future<void> startDownload() async {
    state = state.copyWith(isDownloading: true);
  }

  void finishDownload() {
    state = state.copyWith(isDownloading: false, isDownloaded: true);
  }
}

Future<_OfflineMaps> _pumpPage(WidgetTester tester) async {
  final maps = _OfflineMaps();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineMapsProvider.overrideWith(() => maps),
        mapStyleProvider.overrideWith(
          (ref) => Completer<PreparedMapStyle>().future,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OfflineMapsPage(),
      ),
    ),
  );
  return maps;
}

void main() {
  testWidgets(
    'region outlines and handles follow displayed frames without camera-move events',
    (tester) async {
      final original = platform.MapLibrePlatform.instance;
      final native = _Platform();
      platform.MapLibrePlatform.instance = native;
      addTearDown(() => platform.MapLibrePlatform.instance = original);
      final maps = _OfflineMaps();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineMapsProvider.overrideWith(() => maps),
            mapStyleProvider.overrideWith(
              (_) async =>
                  testPreparedStyle('{"version":8,"sources":{},"layers":[]}'),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OfflineMapsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      maps.addRegion(
        const Geographic(lon: 17, lat: 48),
        const Geographic(lon: 18, lat: 47),
      );
      await tester.pump();
      native.map.widget.onClick?.call(
        const MapEventClick(
          point: Geographic(lon: 17.5, lat: 47.5),
          screenPoint: Offset(34, 47),
        ),
      );
      await tester.pump();
      final handles = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 40 &&
            widget.constraints?.maxHeight == 40,
      );
      expect(handles, findsNWidgets(4));
      final before = tester.getTopLeft(handles.first);
      final painter = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is RegionPainter,
      );
      final oldPainter = tester.widget<CustomPaint>(painter).painter;
      expect(native.map.widget.onCameraMove, isNull);
      native.map.display(27);
      await tester.pump();
      expect(
        tester.getTopLeft(handles.first).dx - before.dx,
        closeTo(10, 1e-9),
      );
      expect(
        tester.widget<CustomPaint>(painter).painter,
        isNot(same(oldPainter)),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('empty state opens and cancels map area selection', (
    tester,
  ) async {
    await _pumpPage(tester);

    final selectArea = find.widgetWithText(ElevatedButton, 'Select area');
    final hint = find.text('Drag on the map to draw the area to download.');
    expect(selectArea, findsOneWidget);
    expect(hint, findsNothing);

    await tester.tap(selectArea);
    await tester.pump();
    expect(hint, findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel'));
    await tester.pump();
    expect(hint, findsNothing);
    expect(selectArea, findsOneWidget);
  });

  testWidgets('shows offline readiness for the current selection', (
    tester,
  ) async {
    final maps = await _pumpPage(tester);
    final id = maps.addRegion(
      Geographic(lon: 17, lat: 48),
      Geographic(lon: 18, lat: 47),
    );
    await tester.pump();

    final pending = find.text('Download required for the selected areas');
    final ready = find.text('Ready to use offline');
    expect(pending, findsOneWidget);
    expect(ready, findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Download Maps'));
    await tester.pump();
    expect(find.text('Cancel Download'), findsOneWidget);
    expect(find.byTooltip('Add Area'), findsNothing);

    maps.finishDownload();
    await tester.pump();
    expect(ready, findsOneWidget);

    maps.updateRegion(id, se: Geographic(lon: 19, lat: 47));
    await tester.pump();
    expect(ready, findsNothing);
    expect(pending, findsOneWidget);
  });
}
