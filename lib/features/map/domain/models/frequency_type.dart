enum FrequencyType {
  approach, // 0
  apron, // 1
  arrival, // 2
  center, // 3
  ctaf, // 4
  delivery, // 5
  departure, // 6
  fis, // 7
  gliding, // 8
  ground, // 9
  info, // 10
  multicom, // 11
  unicom, // 12
  radar, // 13
  tower, // 14
  atis, // 15
  radio, // 16
  other, // 17
  airmet, // 18
  awos, // 19
  lights, // 20
  volmet, // 21
  unknown;

  static FrequencyType fromInt(int val) {
    if (val >= 0 && val < FrequencyType.values.length - 1) {
      return FrequencyType.values[val];
    }
    return FrequencyType.unknown;
  }

  int toInt() {
    return index;
  }
}
