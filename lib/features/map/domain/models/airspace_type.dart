enum AirspaceType {
  other, // 0
  restricted, // 1
  danger, // 2
  prohibited, // 3
  ctr, // 4
  tmz, // 5
  rmz, // 6
  tma, // 7
  tra, // 8
  tsa, // 9
  fir, // 10
  uir, // 11
  adiz, // 12
  atz, // 13
  matz, // 14
  airway, // 15
  mtr, // 16
  alert, // 17
  warning, // 18
  protected, // 19
  htz, // 20
  gliding, // 21
  trp, // 22
  tiz, // 23
  tia, // 24
  mta, // 25
  cta, // 26
  acc, // 27
  sport, // 28
  lowOverflight, // 29
  mrt, // 30
  tfr, // 31
  vfr, // 32
  fis, // 33
  lta, // 34
  uta, // 35
  mctr, // 36
  unknown;

  static AirspaceType fromInt(int val) {
    if (val >= 0 && val < AirspaceType.values.length - 1) {
      return AirspaceType.values[val];
    }
    return AirspaceType.unknown;
  }
}
