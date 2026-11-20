import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart';

/// Uses MapLibre's real collections so tests exercise the 0.4 validation too.
class TestStyle extends Fake
    with ChangeNotifier
    implements StyleController, StyleBackend {
  @override
  late final StyleSources sources = StyleSources(this, layers: () => layers);
  @override
  late final StyleLayers layers = StyleLayers(this, sources: sources);

  void loadStyle(Map<String, dynamic> json) {
    sources.load((json['sources'] as Map? ?? {}).cast<String, Object?>());
    layers.load((json['layers'] as List? ?? []).cast<Map<String, Object?>>());
  }

  @override
  Future<void> addSource(Source source) async {}
  @override
  Future<void> removeSource(String id) async {}
  @override
  Future<void> addLayer(
    Map<String, Object?> json, {
    String? belowLayerId,
  }) async {}
  @override
  Future<void> removeLayer(String id) async {}
  @override
  Future<void> setGeoJsonData(String id, GeoJsonData data) async {}
}
