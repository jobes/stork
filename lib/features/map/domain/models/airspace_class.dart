enum AirspaceClass {
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  unclassified,
  unknown;

  static AirspaceClass fromInt(int val) => switch (val) {
    0 => AirspaceClass.a,
    1 => AirspaceClass.b,
    2 => AirspaceClass.c,
    3 => AirspaceClass.d,
    4 => AirspaceClass.e,
    5 => AirspaceClass.f,
    6 => AirspaceClass.g,
    8 => AirspaceClass.unclassified,
    9 => AirspaceClass.unknown,
    _ => AirspaceClass.unknown,
  };
}
