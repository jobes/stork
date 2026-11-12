import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/features/map/data/repositories/radar_repository.dart';
import 'package:stork/features/map/presentation/providers/map_radar.dart';

int get _recentTime =>
    clock.now().millisecondsSinceEpoch ~/ (_step * 1000) * _step - _step;

http.Response _tile() =>
    http.Response.bytes([137, 80, 78, 71, 13, 10, 26, 10], 200);
const _step = 600;

DateTime _utc(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

http.Response _manifest(
  int latest, {
  String host = 'https://tilecache.rainviewer.com',
  int frameCount = 9,
}) => http.Response(
  jsonEncode({
    'host': host,
    'radar': {
      'past': [
        for (var index = 0; index < frameCount; index++)
          {
            'time': latest - index * _step,
            'path': '/v2/radar/${latest - index * _step}',
          },
      ],
    },
  }),
  200,
);

class _Style implements StyleController {
  bool autoLoad = true;
  int _nextRoute = 0;
  final _tiles = <String, Future<Uint8List?> Function(int, int, int)>{};

  ({String template, void Function() close}) registerTiles(
    Future<Uint8List?> Function(int, int, int) load,
  ) {
    final template = 'http://localhost/${_nextRoute++}/{z}/{x}/{y}.png';
    _tiles[template] = load;
    return (template: template, close: () => _tiles.remove(template));
  }

  Future<Uint8List?> loadTile(RasterSource source) =>
      _tiles[source.tiles!.single]!(0, 0, 0);

  final sources = <String, RasterSource>{};
  final layers = <String, RasterStyleLayer>{};
  final shown = <String>[];

  @override
  Future<void> addSource(Source source) async {
    expectSync(sources, isNot(contains(source.id)));
    sources[source.id] = source as RasterSource;
  }

  @override
  Future<void> addLayer(
    StyleLayer layer, {
    String? belowLayerId,
    String? aboveLayerId,
    int? atIndex,
  }) async {
    expectSync(belowLayerId, 'obstacle_clicktarget');
    expectSync(layers, isNot(contains(layer.id)));
    final raster = layer as RasterStyleLayer;
    expectSync(sources, contains(raster.sourceId));
    layers[raster.id] = raster;
    if (raster.id.endsWith('-visible')) {
      shown.add(raster.sourceId);
    } else if (autoLoad) {
      unawaited(loadTile(sources[raster.sourceId]!));
    }
  }

  @override
  Future<void> removeLayer(String id) async {
    expectSync(layers.remove(id), isNotNull);
  }

  @override
  Future<void> removeSource(String id) async {
    expectSync(
      layers.values.map((layer) => layer.sourceId),
      isNot(contains(id)),
    );
    expectSync(sources.remove(id), isNotNull);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MapRadar _radar(_Style style, http.Client client) {
  final repository = RadarRepository(client: client);
  addTearDown(repository.close);
  return MapRadar(repository: repository, registerTiles: style.registerTiles);
}

void main() {
  testWidgets('uses a changed HTTPS tile server at the same timestamp', (
    tester,
  ) async {
    final latest = _recentTime;
    var host = 'https://tiles.example.org/rain/';
    final tileRequests = <Uri>[];
    final style = _Style();
    final radar = _radar(
      style,
      MockClient((request) async {
        if (request.url.host == 'api.rainviewer.com') {
          return _manifest(latest, host: host);
        }
        tileRequests.add(request.url);
        return _tile();
      }),
    );
    radar.attachStyle(style);
    await tester.pump();
    expect(
      tileRequests.single.toString(),
      'https://tiles.example.org/rain/v2/radar/$latest/256/0/0/0/2/1_1.png',
    );

    host = 'https://other-tiles.example.org';
    await radar.refresh(force: true);
    expect(radar.value.latest, _utc(latest));
    expect(tileRequests.last.host, 'other-tiles.example.org');
    expect(style.sources, hasLength(1));
    radar.dispose();
  });

  testWidgets('loads history on demand and restores the latest raster', (
    tester,
  ) async {
    final style = _Style();
    final latest = _recentTime;
    final radar = _radar(
      style,
      MockClient(
        (request) async => request.url.host == 'api.rainviewer.com'
            ? _manifest(latest)
            : _tile(),
      ),
    );
    radar.attachStyle(style);
    await tester.pump();
    expect(radar.value.latest, _utc(latest));
    final latestSource = style.sources.values.single;
    expect(latestSource.maxZoom, 7);

    final playback = radar.play();
    await tester.pump();
    expect(radar.value.preparing, isFalse);
    expect(style.sources, hasLength(7));

    for (var offset = 6; offset > 0; offset--) {
      expect(radar.value.playing, _utc(latest - offset * _step));
      await tester.pump(const Duration(milliseconds: 750));
    }
    await playback;
    expect(radar.value.playing, isNull);
    expect(style.sources.keys, [latestSource.id]);
    expect(style.shown.last, latestSource.id);
    radar.dispose();
  });

  testWidgets('gesture stops playback and a later refresh can replace latest', (
    tester,
  ) async {
    final initial = _recentTime;
    var latest = initial;
    final style = _Style();
    final radar = _radar(
      style,
      MockClient(
        (request) async => request.url.host == 'api.rainviewer.com'
            ? _manifest(latest)
            : _tile(),
      ),
    );
    radar.attachStyle(style);
    await tester.pump();

    final playback = radar.play();
    await tester.pump();
    expect(radar.value.playing, isNotNull);

    radar.onMapEvent(
      const MapEventStartMoveCamera(reason: CameraChangeReason.apiGesture),
    );
    await tester.pump();
    await playback;
    expect(radar.value.playing, isNull);
    expect(style.sources, hasLength(1));

    latest += _step;
    expect(radar.value.latest, _utc(initial));
    await radar.refresh(force: true);
    expect(radar.value.latest, _utc(latest));
    expect(style.sources, hasLength(1));
    radar.dispose();
  });

  testWidgets(
    'waits for actual tiles and hides the radar on a later tile error',
    (tester) async {
      final latest = _recentTime;
      final style = _Style()..autoLoad = false;
      var failTile = false;
      final radar = _radar(
        style,
        MockClient((request) async {
          if (request.url.host == 'api.rainviewer.com') {
            return _manifest(latest);
          }
          return failTile ? http.Response('unavailable', 503) : _tile();
        }),
      );
      radar.attachStyle(style);
      await tester.pump();
      expect(radar.value.latest, isNull);
      expect(style.shown, isEmpty);

      await style.loadTile(style.sources.values.single);
      await tester.pump();
      expect(radar.value.latest, _utc(latest));

      failTile = true;
      await style.loadTile(style.sources.values.single);
      await tester.pump();
      expect(radar.value.unavailable, isTrue);
      expect(radar.value.latest, isNull);
      expect(style.layers, isEmpty);
      expect(style.sources, isEmpty);

      failTile = false;
      style.autoLoad = true;
      await radar.refresh(force: true);
      expect(radar.value.unavailable, isFalse);
      expect(radar.value.latest, _utc(latest));
      radar.dispose();
    },
  );

  testWidgets('hides a stale frame and recovers on a fresh manifest', (
    tester,
  ) async {
    var latest = _recentTime;
    final style = _Style();
    final radar = _radar(
      style,
      MockClient(
        (request) async => request.url.host == 'api.rainviewer.com'
            ? _manifest(latest)
            : _tile(),
      ),
    );
    radar.attachStyle(style);
    await tester.pump();
    expect(radar.value.latest, _utc(latest));

    await tester.pump(const Duration(minutes: 20));
    expect(radar.value.unavailable, isTrue);
    expect(style.layers, isEmpty);
    await radar.refresh(force: true);
    expect(radar.value.unavailable, isTrue);

    latest = _recentTime;
    await radar.refresh(force: true);
    expect(radar.value.unavailable, isFalse);
    expect(radar.value.latest, _utc(latest));
    radar.dispose();
  });

  testWidgets(
    'a missing history keeps the live frame and reports history only',
    (tester) async {
      final latest = _recentTime;
      final style = _Style();
      final radar = _radar(
        style,
        MockClient(
          (request) async => request.url.host == 'api.rainviewer.com'
              ? _manifest(latest, frameCount: 1)
              : _tile(),
        ),
      );
      radar.attachStyle(style);
      await tester.pump();
      final live = style.sources.values.single;

      await radar.play();

      expect(radar.value.latest, _utc(latest));
      expect(radar.value.unavailable, isFalse);
      expect(radar.value.historyUnavailable, isTrue);
      expect(style.sources.values.single, same(live));
      expect(style.shown, [live.id]);
      radar.dispose();
    },
  );

  testWidgets('HTTP 429 during history keeps the live radar visible', (
    tester,
  ) async {
    final latest = _recentTime;
    final style = _Style();
    final radar = _radar(
      style,
      MockClient((request) async {
        if (request.url.host == 'api.rainviewer.com') {
          return _manifest(latest);
        }
        return request.url.path.startsWith('/v2/radar/$latest/')
            ? _tile()
            : http.Response('Too Many Requests', 429);
      }),
    );
    radar.attachStyle(style);
    await tester.pump();
    final live = style.sources.values.single;

    final playback = radar.play();
    await tester.pump();
    await playback;

    expect(radar.value.historyUnavailable, isTrue);
    expect(radar.value.unavailable, isFalse);
    expect(style.sources.values.single, same(live));
    expect(style.shown, [live.id]);

    expect(await style.loadTile(live), isNotNull);
    radar.dispose();
  });

  testWidgets('gives a late tile request its own 15-second HTTP budget', (
    tester,
  ) async {
    final latest = clock.now().millisecondsSinceEpoch ~/ 1000;
    final style = _Style()..autoLoad = false;
    final tile = Completer<http.Response>();
    final radar = _radar(
      style,
      MockClient(
        (request) async => request.url.host == 'api.rainviewer.com'
            ? _manifest(latest)
            : tile.future,
      ),
    );
    radar.attachStyle(style);
    await tester.pump();
    await tester.pump(const Duration(seconds: 14));
    final loading = style.loadTile(style.sources.values.single);
    await tester.pump(const Duration(seconds: 14));

    expect(radar.value.unavailable, isFalse);
    expect(style.shown, isEmpty);
    tile.complete(_tile());
    expect(await loading, isNotNull);
    await tester.pump();
    expect(radar.value.latest, _utc(latest));
    radar.dispose();
  });
}
