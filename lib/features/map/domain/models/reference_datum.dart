enum ReferenceDatum {
  gnd, // 0
  msl, // 1
  std, // 2
  unknown;

  static ReferenceDatum fromInt(int val) => switch (val) {
    0 => ReferenceDatum.gnd,
    1 => ReferenceDatum.msl,
    2 => ReferenceDatum.std,
    _ => ReferenceDatum.unknown,
  };
}
