import 'dart:convert';
import 'package:maplibre/maplibre.dart';
import '../../../../core/theme/stork_colors.dart';
import 'traffic_colors.dart';

// Icon sizes relative to the sprite frames (see
// documentation/architecture/map-sprite.md). Kept as named constants so a
// sprite regeneration that changes frame sizes only needs updating here.
const double kAircraftIconSize = 0.88; // 192px frame -> previous size (676/4)
const double kTrafficIconSize = 0.40; // 128px SDF frame
const double kPoiIconSize = 0.64; // 64px frame

const forecastSource = 'flight-weather-source';
const forecastHitLayer = 'flight-weather-hit';
const forecastWindLayer = 'flight-weather-wind';
const forecastLabelLayer = 'flight-weather-label';
typedef ForecastPalette = ({
  String text,
  String halo,
  String marker,
  String waypoint,
  String sample,
});
const forecastLight = (
  text: '#152E43',
  halo: '#FFFFFF',
  marker: '#FFFFFF',
  waypoint: '#D66900',
  sample: '#34576C',
);
const forecastDark = (
  text: '#E4F2FC',
  halo: '#15202B',
  marker: '#203344',
  waypoint: '#FFB15C',
  sample: '#9CC9E2',
);

/// Shared by initial style preparation and subsequent style reloads.
class MapOverlayStyle {
  const MapOverlayStyle({required this.sources, required this.layers});
  final List<GeoJsonSource> sources;
  final List<StyleLayer> layers;

  factory MapOverlayStyle.build({
    required Map<String, String> data,
    required double fontScale,
    required ForecastPalette palette,
  }) {
    final notamColor = mapColorHex(StorkColors.notam);
    final mapFontSize = fontScale * 1.5;
    final windArrowSize = 36.0 * fontScale;
    final windLabelSize = 15.0 * fontScale;
    final windOffsetX = 66.0 * fontScale;
    final windLabelOffsetY = 20.0 * fontScale;
    final pointArrowOffsetX = 22.0 * fontScale;
    final pointLabelOffsetX = 38.0 * fontScale;
    return MapOverlayStyle(
      sources: [
        for (final entry in data.entries)
          GeoJsonSource(id: entry.key, data: entry.value),
      ],
      layers: [
        LineStyleLayer(
          id: 'course-line-border',
          sourceId: 'course-line-source',
          paint: {'line-color': '#000000', 'line-width': 5.0},
        ),
        LineStyleLayer(
          id: 'course-line-white',
          sourceId: 'course-line-source',
          filter: ['==', 'isEven', false],
          paint: {'line-color': '#FFFFFF', 'line-width': 3.0},
        ),
        LineStyleLayer(
          id: 'navigation-route-border',
          sourceId: 'navigation-route-source',
          paint: {'line-color': '#000000', 'line-width': 6.0},
        ),
        LineStyleLayer(
          id: 'navigation-route-line',
          sourceId: 'navigation-route-source',
          paint: {'line-color': '#FF9800', 'line-width': 3.5},
        ),
        FillStyleLayer(
          id: 'notams-fill-layer',
          sourceId: 'notams-source',
          paint: {'fill-color': notamColor, 'fill-opacity': 0.25},
        ),
        LineStyleLayer(
          id: 'notams-line-layer',
          sourceId: 'notams-source',
          paint: {
            'line-color': notamColor,
            'line-width': 2.0,
            'line-dasharray': [2.0, 2.0],
          },
        ),
        SymbolStyleLayer(
          id: 'aircraft-layer',
          sourceId: 'aircraft-source',
          layout: {
            'icon-image': 'aircraft-icon',
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-pitch-alignment': 'viewport',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
            'icon-size': kAircraftIconSize,
          },
        ),
        SymbolStyleLayer(
          id: 'traffic-possible-layer',
          sourceId: 'traffic-source',
          layout: {
            'icon-image': 'possibleLoc',
            'icon-size': ['get', 'possiblePositionRatio'],
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-pitch-alignment': 'map',
            'icon-allow-overlap': true,
            'icon-ignore-placement': false,
            'icon-optional': false,
            'icon-anchor': 'bottom',
          },
        ),
        SymbolStyleLayer(
          id: 'traffic-layer',
          sourceId: 'traffic-source',
          layout: {
            'icon-image': ['get', 'icon-image'],
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-pitch-alignment': 'viewport',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
            'icon-size': kTrafficIconSize,
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-field': ['get', 'altitudeTag'],
            'text-size': 11.0 * mapFontSize,
            'text-offset': [1.4, 0],
            'text-anchor': 'left',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'icon-color': [
              'case',
              [
                '==',
                ['get', 'isThreat'],
                true,
              ],
              mapColorHex(kTrafficThreatColor),
              [
                '==',
                ['get', 'isFlying'],
                true,
              ],
              mapColorHex(kTrafficFlyingColor),
              mapColorHex(kTrafficInactiveColor),
            ],
            'text-color': [
              'case',
              [
                '==',
                ['get', 'isThreat'],
                true,
              ],
              mapColorHex(kTrafficThreatColor),
              '#FFFFFF',
            ],
            'text-halo-color': '#000000',
            'text-halo-width': 1.5,
          },
        ),
        SymbolStyleLayer(
          id: 'favorites-layer',
          sourceId: 'favorites-source',
          layout: {
            'icon-image': ['get', 'icon-image'],
            'icon-size': kPoiIconSize,
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
            'text-font': ['Roboto Mono Regular,Noto Sans Regular'],
            'text-field': ['get', 'name'],
            'text-size': 12.0 * mapFontSize,
            'text-offset': [0, 0.8],
            'text-anchor': 'top',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {'text-color': '#000000', 'text-halo-width': 0},
        ),
        const CircleStyleLayer(
          id: forecastHitLayer,
          sourceId: forecastSource,
          filter: ['!=', 'kind', 'aircraft'],
          paint: {'circle-radius': 14.0, 'circle-opacity': 0.0},
        ),
        CircleStyleLayer(
          id: 'flight-weather-markers',
          sourceId: forecastSource,
          filter: ['in', 'kind', 'waypoint', 'sample'],
          paint: {
            'circle-radius': [
              'match',
              ['get', 'kind'],
              'waypoint',
              5.0,
              3.0,
            ],
            'circle-color': palette.marker,
            'circle-stroke-color': [
              'match',
              ['get', 'kind'],
              'waypoint',
              palette.waypoint,
              palette.sample,
            ],
            'circle-stroke-width': 1.5,
          },
        ),
        SymbolStyleLayer(
          id: 'flight-weather-point-wind',
          sourceId: forecastSource,
          filter: ['!=', 'kind', 'aircraft'],
          layout: {
            'text-field': ['get', 'arrow'],
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-size': windArrowSize,
            'text-rotate': ['get', 'direction'],
            'text-rotation-alignment': 'map',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'text-color': palette.text,
            'text-halo-color': palette.halo,
            'text-halo-width': 2.0 * fontScale,
            'text-translate': [pointArrowOffsetX, 0.0],
            'text-translate-anchor': 'viewport',
          },
        ),
        SymbolStyleLayer(
          id: 'flight-weather-point-label',
          sourceId: forecastSource,
          filter: ['!=', 'kind', 'aircraft'],
          layout: {
            'text-field': ['get', 'label'],
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-size': windLabelSize,
            'text-anchor': 'left',
            'text-line-height': 0.95,
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'text-color': palette.text,
            'text-halo-color': palette.halo,
            'text-halo-width': 2.0 * fontScale,
            'text-translate': [pointLabelOffsetX, 0.0],
            'text-translate-anchor': 'viewport',
          },
        ),
        SymbolStyleLayer(
          id: forecastWindLayer,
          sourceId: forecastSource,
          filter: ['==', 'kind', 'aircraft'],
          layout: {
            'text-field': ['get', 'arrow'],
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-size': windArrowSize,
            'text-rotate': ['get', 'direction'],
            'text-rotation-alignment': 'map',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'text-color': palette.text,
            'text-halo-color': palette.halo,
            'text-halo-width': 2.0 * fontScale,
            // Paint translation keeps the rotated arrow in place while moving it
            // away from the aircraft; text-offset would rotate with the glyph.
            'text-translate': [windOffsetX, 0.0],
            'text-translate-anchor': 'viewport',
          },
        ),
        SymbolStyleLayer(
          id: forecastLabelLayer,
          sourceId: forecastSource,
          filter: ['==', 'kind', 'aircraft'],
          layout: {
            'text-field': ['get', 'label'],
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-size': windLabelSize,
            'text-anchor': 'top',
            'text-line-height': 0.95,
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'text-color': palette.text,
            'text-halo-color': palette.halo,
            'text-halo-width': 2.0 * fontScale,
            'text-translate': [windOffsetX, windLabelOffsetY],
            'text-translate-anchor': 'viewport',
          },
        ),
      ],
    );
  }

  String embedIn(
    String baseStyle, {
    Map<String, List<Object>> filters = const {},
  }) {
    final style = jsonDecode(baseStyle) as Map<String, dynamic>;
    final styleSources = style['sources'] as Map<String, dynamic>;
    for (final source in sources) {
      styleSources[source.id] = {
        'type': 'geojson',
        'data': jsonDecode(source.data),
        'maxzoom': source.maxZoom,
        'tolerance': source.tolerance,
      };
    }
    for (final layer in style['layers'] as List) {
      final filter = filters[layer['id']];
      if (filter != null) layer['filter'] = filter;
    }
    (style['layers'] as List).addAll(layers.map(layerJson));
    return jsonEncode(style);
  }

  static Map<String, dynamic> layerJson(StyleLayer layer) => {
    'id': layer.id,
    'type': switch (layer) {
      LineStyleLayer() => 'line',
      FillStyleLayer() => 'fill',
      SymbolStyleLayer() => 'symbol',
      CircleStyleLayer() => 'circle',
      _ => throw UnsupportedError('Unsupported overlay ${layer.runtimeType}'),
    },
    if (layer is StyleLayerWithSource) 'source': layer.sourceId,
    'minzoom': layer.minZoom,
    'maxzoom': layer.maxZoom,
    if (layer.filter != null) 'filter': layer.filter,
    'layout': layer.layout,
    'paint': layer.paint,
  };
}
