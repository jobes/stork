enum OpenAipUnit {
  meters, // 0
  feet, // 1
  mhz, // 2
  flightLevel, // 6
  khz, // 7
  unknown;

  static OpenAipUnit fromInt(int val) => switch (val) {
    0 => OpenAipUnit.meters,
    1 => OpenAipUnit.feet,
    2 => OpenAipUnit.mhz,
    6 => OpenAipUnit.flightLevel,
    7 => OpenAipUnit.khz,
    _ => OpenAipUnit.unknown,
  };

  int toInt() => switch (this) {
    OpenAipUnit.meters => 0,
    OpenAipUnit.feet => 1,
    OpenAipUnit.mhz => 2,
    OpenAipUnit.flightLevel => 6,
    OpenAipUnit.khz => 7,
    _ => -1,
  };

  String get symbol => switch (this) {
    OpenAipUnit.meters => 'm',
    OpenAipUnit.feet => 'ft',
    OpenAipUnit.mhz => 'MHz',
    OpenAipUnit.flightLevel => 'FL',
    OpenAipUnit.khz => 'kHz',
    _ => '',
  };
}
