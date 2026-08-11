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

  /// Traffic icon id — resolved from the app sprite (`assets/map_sprites/`,
  /// sprite id "default"). The icon is an SDF silhouette tinted per state via
  /// the `icon-color` expression on `traffic-layer`, and via the `color`
  /// parameter of `SpriteIcon` in the Flutter UI (e.g. the traffic details
  /// dialog). No separate PNG assets are bundled at runtime.
  String get trafficMapIconId => 'traffic-icon-$assetName';

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

  static AircraftType fromPureTrackType(int code) {
    return fromOgnCode(code);
  }

  /// Maps a GDL90 Traffic Report emitter category (GDL90 ICD §3.5.1.10) to an
  /// `AircraftType`.
  ///
  /// The GDL90 table differs from the ADS-B (DO-282) one: code 8 is reserved,
  /// **9 is glider / sailplane**, 10 is lighter-than-air, 11 is parachutist /
  /// skydiver, 12 is ultralight / hang glider / paraglider and 14 is UAV.
  /// SafeSky transmits gliders as category 9, so mapping 9 to anything other
  /// than `glider` would mislabel them.
  static AircraftType fromGdl90EmitterCategory(int code) {
    switch (code) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        return AircraftType.poweredAircraft;
      case 7:
        return AircraftType.helicopter;
      case 9: // Glider / sailplane
        return AircraftType.glider;
      case 10: // Lighter-than-air (balloon / airship)
        return AircraftType.balloon;
      case 11: // Parachutist / skydiver
        return AircraftType.skydiver;
      case 12: // Ultralight / hang glider / paraglider
        return AircraftType.paraglider;
      case 14: // Unmanned aerial vehicle
        return AircraftType.uav;
      default:
        return AircraftType.other;
    }
  }
}
