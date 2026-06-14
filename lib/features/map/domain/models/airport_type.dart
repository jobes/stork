enum AirportType {
  airport, // 0
  gliderSite, // 1
  airfieldCivil, // 2
  internationalAirport, // 3
  heliportMilitary, // 4
  militaryAerodrome, // 5
  ultralightFlyingSite, // 6
  heliportCivil, // 7
  aerodromeClosed, // 8
  ifr, // 9
  airfieldWater, // 10
  landingStrip, // 11
  agriculturalLandingStrip, // 12
  altiport, // 13
  unknown;

  static AirportType fromInt(int val) {
    if (val >= 0 && val < AirportType.values.length - 1) {
      return AirportType.values[val];
    }
    return AirportType.unknown;
  }

  int toInt() {
    return index;
  }
}
