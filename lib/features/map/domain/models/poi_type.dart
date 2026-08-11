/// A point of interest (POI) that can be displayed as a marker on the map.
///
/// Each value maps to a PNG asset rendered as a map-pin badge (see
/// `assets/images/poi/`). Icons are registered in the map style via
/// `MapCameraStyle.handleStyleLoaded`.
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

  String get assetPath => 'assets/images/poi/$assetName.png';

  String get mapIconId => 'poi-icon-$assetName';
}
