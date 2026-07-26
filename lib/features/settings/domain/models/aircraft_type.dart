import '../../../../l10n/app_localizations.dart';

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

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case AircraftType.glider:
        return l10n.gliderType;
      case AircraftType.towPlane:
        return l10n.towPlaneType;
      case AircraftType.helicopter:
        return l10n.helicopterType;
      case AircraftType.skydiver:
        return l10n.skydiverType;
      case AircraftType.dropPlane:
        return l10n.dropPlaneType;
      case AircraftType.hangGlider:
        return l10n.hangGliderType;
      case AircraftType.paraglider:
        return l10n.paragliderType;
      case AircraftType.poweredAircraft:
        return l10n.poweredAircraftType;
      case AircraftType.jet:
        return l10n.jetType;
      case AircraftType.balloon:
        return l10n.balloonType;
      case AircraftType.airship:
        return l10n.airshipType;
      case AircraftType.uav:
        return l10n.uavType;
      case AircraftType.other:
        return l10n.otherType;
    }
  }

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
