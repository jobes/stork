import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/pages/offline_maps_page.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

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
        mapStyleProvider.overrideWith((ref) => Completer<String>().future),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OfflineMapsPage(),
      ),
    ),
  );
  return maps;
}

void main() {
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
