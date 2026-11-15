part of 'map_camera_provider.dart';

const _notamLayerUpdateInterval = Duration(seconds: 1);
typedef _NotamMapFeature = ({
  String key,
  String id,
  String title,
  double lat,
  double lon,
  double radius,
});

/// Keeps the NOTAM map source in sync with the latest selected notices.
extension MapCameraNotam on MapCamera {
  void updateNotamsOnMap() {
    _notamLayerDirty = true;
    if (_notamLayerTimer == null) _flushNotamLayer();
  }

  void _flushNotamLayer() {
    if (!_notamLayerDirty || _notamLayerWriting) return;
    _notamLayerDirty = false;
    final style = _notamStyle;
    if (!refAccess.mounted || style == null || style != _mapController?.style) {
      return;
    }

    final notamsAsync = refAccess.read(notamsProvider);
    final notams = notamsAsync.hasError ? [] : notamsAsync.value?.notams ?? [];
    final visible = <_NotamMapFeature>[
      for (final notam in notams)
        if (notam.radius > 0)
          (
            key: notam.key,
            id: notam.id,
            title: notam.featureName.isEmpty ? notam.msg : notam.featureName,
            lat: notam.latitude,
            lon: notam.longitude,
            radius: notam.radius,
          ),
    ];
    if (listEquals(_lastNotamMapFeatures, visible)) return;

    final features = <Map<String, dynamic>>[];
    for (final notam in visible) {
      final center = Geographic(lat: notam.lat, lon: notam.lon);
      const segments = 32;
      final ring = <List<double>>[];
      for (var i = 0; i < segments; i++) {
        final point = GeoUtils.calculateDestination(
          center,
          i * 360.0 / segments,
          notam.radius,
        );
        ring.add([point.lon, point.lat]);
      }
      ring.add(ring.first);

      features.add({
        'type': 'Feature',
        'id': notam.key,
        'properties': {'key': notam.key, 'id': notam.id, 'title': notam.title},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
      });
    }

    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    _lastNotamMapFeatures = visible;
    _notamLayerWriting = true;
    _notamLayerTimer = Timer(_notamLayerUpdateInterval, () {
      _notamLayerTimer = null;
      _flushNotamLayer();
    });
    unawaited(_writeNotamLayer(style, geojson));
  }

  Future<void> _writeNotamLayer(StyleController style, String geojson) async {
    try {
      await style.updateGeoJsonSource(id: 'notams-source', data: geojson);
    } catch (error) {
      if (refAccess.mounted && identical(style, _notamStyle)) {
        _lastNotamMapFeatures = null;
        _notamLayerDirty = true;
      }
      debugPrint('NOTAM map layer update failed: $error');
    } finally {
      _notamLayerWriting = false;
      if (_notamLayerTimer == null) _flushNotamLayer();
    }
  }
}
