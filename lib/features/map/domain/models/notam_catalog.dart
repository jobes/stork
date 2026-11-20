import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:maplibre/maplibre.dart';

part 'notam_catalog.freezed.dart';

typedef NotamPolygon = List<List<List<double>>>;

@freezed
abstract class NotamCatalog with _$NotamCatalog {
  const factory NotamCatalog(
    List<({String icao, Geographic position})> airports,
    List<({String icao, List<NotamPolygon> polygons})> areas,
  ) = _NotamCatalog;

  factory NotamCatalog.fromGeoJson(
    Map<String, dynamic> airportIndex,
    Map<String, dynamic> areaIndex,
  ) {
    final airports = <({String icao, Geographic position})>[];
    final areas = <({String icao, List<NotamPolygon> polygons})>[];

    for (final feature in _features(airportIndex)) {
      final icao = _icao(feature);
      // The airport index also includes sites without ICAO.
      if (icao == null) continue;
      if (feature['geometry'] case {
        'type': 'Point',
        'coordinates': final coords,
      }) {
        final point = _coordinate(coords);
        airports.add((
          icao: icao,
          position: Geographic(lon: point[0], lat: point[1]),
        ));
      } else {
        throw const FormatException('Invalid airport geometry');
      }
    }

    for (final feature in _features(areaIndex)) {
      final icao = _icao(feature);
      if (icao == null) throw const FormatException('Missing NOTAM area ICAO');
      final polygons = switch (feature['geometry']) {
        {'type': 'Polygon', 'coordinates': final Object coordinates} => [
          _polygon(coordinates),
        ],
        {'type': 'MultiPolygon', 'coordinates': List<dynamic> coordinates}
            when coordinates.isNotEmpty =>
          coordinates.map(_polygon).toList(),
        _ => throw const FormatException('Invalid NOTAM area geometry'),
      };
      areas.add((icao: icao, polygons: polygons));
    }

    if (airports.isEmpty || areas.isEmpty) {
      throw const FormatException('Empty NOTAM catalog');
    }
    return NotamCatalog(airports, areas);
  }

  static List<Map<String, dynamic>> _features(Map<String, dynamic> json) {
    if (json case {
      'type': 'FeatureCollection',
      'features': List<dynamic> features,
    }) {
      return [
        for (final feature in features)
          if (feature is Map<String, dynamic>)
            feature
          else
            throw const FormatException('Invalid GeoJSON feature'),
      ];
    }
    throw const FormatException('Expected a GeoJSON FeatureCollection');
  }

  static final _icaoPattern = RegExp(r'^[A-Z]{4}$');

  static String? _icao(Map<String, dynamic> feature) {
    if (feature['properties'] case {'icao': String value}) {
      final code = value.trim().toUpperCase();
      if (_icaoPattern.hasMatch(code)) return code;
    }
    return null;
  }

  static NotamPolygon _polygon(Object? input) {
    if (input is! List || input.isEmpty) {
      throw const FormatException('Missing NOTAM area rings');
    }
    return [
      for (final ring in input)
        if (ring is List && ring.length >= 4)
          ring.map(_coordinate).toList()
        else
          throw const FormatException('Invalid NOTAM area ring'),
    ];
  }

  static List<double> _coordinate(Object? input) {
    if (input case [num lon, num lat, ...]
        when lon >= -180 && lon <= 180 && lat >= -90 && lat <= 90) {
      return [lon.toDouble(), lat.toDouble()];
    }
    throw const FormatException('Invalid NOTAM catalog coordinate');
  }
}
