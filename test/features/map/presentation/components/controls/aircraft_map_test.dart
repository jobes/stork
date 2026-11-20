import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart'
    as platform;
import 'package:stork/features/map/presentation/components/controls/aircraft_map.dart';
import 'package:stork/features/map/presentation/providers/map_overlay_style.dart';
import 'package:stork/features/map/presentation/providers/map_style_preparer.dart';

import '../../../../../support/map_style_backend.dart';

class _Platform extends platform.MapLibrePlatform {
  late _Map map;
  @override
  platform.MapLibreMapState createWidgetState() => map = _Map();
}

class _Map extends platform.MapLibreMapState {
  @override
  final TestStyle style = TestStyle();
  final requested = <ml.MapStyle>[];

  @override
  void initState() {
    super.initState();
    camera = const ml.CameraPosition(
      center: ml.Geographic(lon: 17, lat: 48),
      zoom: 6,
      pitch: 0,
      bearing: 0,
    );
    requested.add(options.style);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMapCreated?.call(this);
    });
  }

  @override
  void didUpdateWidget(covariant platform.MapLibreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.style != options.style) requested.add(options.style);
  }

  void finishLoading() => widget.onStyleLoaded?.call(style);

  @override
  Widget buildPlatformWidget(BuildContext context) => const SizedBox.expand();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

PreparedMapStyle _prepared(int revision, {String? json}) => PreparedMapStyle(
  json:
      json ??
      jsonEncode({
        'version': 8,
        'sources': {},
        'layers': [],
        'name': '$revision',
      }),
  snapshot: PreparedOverlaySnapshot(
    inputs: (revision: revision),
    sources: {},
    palette: forecastLight,
    notams: [],
    activeIds: [],
    inactiveIds: [],
  ),
);

void main() {
  testWidgets('failed overlay initialization never reports readiness', (
    tester,
  ) async {
    final original = platform.MapLibrePlatform.instance;
    final native = _Platform();
    platform.MapLibrePlatform.instance = native;
    addTearDown(() => platform.MapLibrePlatform.instance = original);
    final initialized = Completer<void>();
    final errors = <Object>[];
    var ready = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AircraftMap(
          style: _prepared(1),
          onMapCreated: (_) {},
          onStyleLoaded: (_, _) => initialized.future,
          onInitialViewReady: () => ready = true,
          onInitialViewError: errors.add,
          onEvent: (_) {},
          onUserInteraction: () {},
        ),
      ),
    );
    native.map.finishLoading();
    native.map.widget.onRenderMap?.call(
      const ml.MapEventRenderMap(fullyRendered: true),
    );
    initialized.completeError(StateError('overlay initialization failed'));
    await tester.pump();
    expect(errors.single.toString(), contains('overlay initialization failed'));
    expect(ready, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'waits for full rendering, style initialization and a composited frame',
    (tester) async {
      final original = platform.MapLibrePlatform.instance;
      final native = _Platform();
      platform.MapLibrePlatform.instance = native;
      addTearDown(() => platform.MapLibrePlatform.instance = original);
      final initialized = Completer<void>();
      var ready = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AircraftMap(
            style: _prepared(1),
            onMapCreated: (_) {},
            onStyleLoaded: (_, _) => initialized.future,
            onInitialViewReady: () => ready++,
            onEvent: (_) {},
            onUserInteraction: () {},
          ),
        ),
      );
      native.map.finishLoading();
      native.map.widget.onRenderFrame?.call(
        const ml.MapEventRenderFrame(fullyRendered: false),
      );
      await tester.pump();
      expect(ready, 0);
      native.map.widget.onRenderMap?.call(
        const ml.MapEventRenderMap(fullyRendered: true),
      );
      await tester.pump();
      expect(ready, 0);
      initialized.complete();
      await tester.pump();
      await tester.pump();
      expect(ready, 1);
      native.map.widget.onRenderFrame?.call(
        const ml.MapEventRenderFrame(fullyRendered: true),
      );
      await tester.pump();
      expect(ready, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'initial fatal map errors are reported without waiting for a frame',
    (tester) async {
      final original = platform.MapLibrePlatform.instance;
      final native = _Platform();
      platform.MapLibrePlatform.instance = native;
      addTearDown(() => platform.MapLibrePlatform.instance = original);
      final errors = <Object>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AircraftMap(
            style: _prepared(1),
            onMapCreated: (_) {},
            onStyleLoaded: (_, _) {},
            onInitialViewError: errors.add,
            onEvent: (_) {},
            onUserInteraction: () {},
          ),
        ),
      );
      native.map.widget.onError?.call(
        const ml.MapEventError(
          kind: ml.MapErrorKind.style,
          message: 'Bad style',
        ),
      );
      expect(errors.single.toString(), contains('Bad style'));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('coalesces styles and hands off the snapshot actually loaded', (
    tester,
  ) async {
    final original = platform.MapLibrePlatform.instance;
    final native = _Platform();
    platform.MapLibrePlatform.instance = native;
    addTearDown(() => platform.MapLibrePlatform.instance = original);
    final loaded = <PreparedMapStyle>[];
    Widget view(PreparedMapStyle prepared) => Directionality(
      textDirection: TextDirection.ltr,
      child: AircraftMap(
        style: prepared,
        onMapCreated: (_) {},
        onStyleLoaded: (_, prepared) => loaded.add(prepared),
        onEvent: (_) {},
        onUserInteraction: () {},
      ),
    );
    final first = _prepared(1);
    final second = _prepared(2);
    final latest = _prepared(3);
    await tester.pumpWidget(view(first));
    await tester.pumpWidget(view(second));
    await tester.pumpWidget(view(latest));
    expect(native.map.requested, [ml.MapStyle.json(first.json)]);
    native.map.finishLoading();
    await tester.pump();
    expect(loaded, isEmpty);
    expect(native.map.requested, [
      ml.MapStyle.json(first.json),
      ml.MapStyle.json(latest.json),
    ]);
    native.map.finishLoading();
    expect(loaded.single, same(latest));

    // A fresh snapshot with identical JSON must not wait for a native reload.
    await tester.pumpWidget(view(_prepared(4, json: latest.json)));
    expect(native.map.requested, hasLength(2));
    final next = _prepared(5);
    await tester.pumpWidget(view(next));
    expect(native.map.requested.last, ml.MapStyle.json(next.json));
    native.map.finishLoading();
    expect(loaded.last, same(next));
    await tester.pumpWidget(const SizedBox());
  });
}
