enum AirspaceActivity {
  none,
  parachuting,
  aerobatics,
  aeroclub,
  ulm,
  gliding,
  unknown;

  static AirspaceActivity fromInt(int val) {
    if (val >= 0 && val < AirspaceActivity.values.length - 1) {
      return AirspaceActivity.values[val];
    }
    return AirspaceActivity.unknown;
  }
}
