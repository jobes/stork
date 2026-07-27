enum AircraftType {
  glider(1, 'glider'),
  towPlane(2, 'tow_plane'),
  helicopter(3, 'helicopter'),
  skydiver(4, 'skydiver'),
  dropPlane(5, 'drop_plane'),
  hangGlider(6, 'hang_glider'),
  paraglider(7, 'paraglider'),
  poweredAircraft(8, 'powered_aircraft'),
  jet(9, 'jet'),
  balloon(11, 'balloon'),
  airship(12, 'airship'),
  uav(13, 'uav'),
  other(0, 'other');

  final int ognCode;
  final String assetName;

  const AircraftType(this.ognCode, this.assetName);

  String get assetPath => 'assets/images/aircraft_types/$assetName.png';

  String get mapIconId => 'aircraft-icon-$assetName';
  String get trafficMapIconId => 'traffic-icon-$assetName';
  String get inactiveTrafficMapIconId => 'traffic-icon-inactive-$assetName';
  String get threatTrafficMapIconId => 'traffic-icon-threat-$assetName';

  static AircraftType fromOgnCode(int code) {
    switch (code) {
      case 1:
        return AircraftType.glider;
      case 2:
        return AircraftType.towPlane;
      case 3:
        return AircraftType.helicopter;
      case 4:
        return AircraftType.skydiver;
      case 5:
        return AircraftType.dropPlane;
      case 6:
        return AircraftType.hangGlider;
      case 7:
        return AircraftType.paraglider;
      case 8:
        return AircraftType.poweredAircraft;
      case 9:
        return AircraftType.jet;
      case 11:
        return AircraftType.balloon;
      case 12:
        return AircraftType.airship;
      case 13:
        return AircraftType.uav;
      default:
        return AircraftType.other;
    }
  }
}
