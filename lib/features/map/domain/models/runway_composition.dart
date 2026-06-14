enum RunwayComposition {
  asphalt, // 0
  concrete, // 1
  grass, // 2
  sand, // 3
  water, // 4
  bituminousTar, // 5
  brick, // 6
  macadam, // 7
  stone, // 8
  coral, // 9
  clay, // 10
  laterite, // 11
  gravel, // 12
  earth, // 13
  ice, // 14
  snow, // 15
  protectiveLaminate, // 16
  metal, // 17
  landingMat, // 18
  unknown, // 19
  wood; // 20

  static RunwayComposition fromInt(int val) {
    if (val >= 0 && val < RunwayComposition.values.length) {
      return RunwayComposition.values[val];
    }
    return RunwayComposition.unknown;
  }

  int toInt() {
    return index;
  }
}
