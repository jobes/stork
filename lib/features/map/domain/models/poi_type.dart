/// A point of interest (POI) that can be displayed as a marker on the map.
///
/// Each value maps to a map-pin badge icon provided by the app sprite
/// (`assets/map_sprites/`, sprite id "default") under [mapIconId]
/// (`poi-icon-<name>`). The same sprite frame is used on the map and in the
/// Flutter UI (favourites list and dialogs, via `SpriteIcon`) — no separate
/// PNG assets are bundled at runtime.
enum PoiType {
  home('home'),
  thermal('thermal'),
  airfield('airfield'),
  outlanding('outlanding'),
  fuel('fuel'),
  restaurant('restaurant'),
  viewpoint('viewpoint'),
  camping('camping'),
  hospital('hospital'),
  parking('parking');

  final String assetName;

  const PoiType(this.assetName);

  String get mapIconId => 'poi-icon-$assetName';
}
