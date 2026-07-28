const int vhfRadioMinFrequencyKhz = 118000;
const int vhfRadioMaxFrequencyKhz = 136995;

final String vhfRadioFrequencyRangeLabel =
    '${(vhfRadioMinFrequencyKhz / 1000).toStringAsFixed(3)} - ${(vhfRadioMaxFrequencyKhz / 1000).toStringAsFixed(3)} MHz';

const Set<int> _validAviationOffsets = {
  0,
  5,
  10,
  15,
  25,
  30,
  35,
  40,
  50,
  55,
  60,
  65,
  75,
  80,
  85,
  90,
};

bool isVhfRadioFrequencyInBand(int frequencyKhz) {
  return frequencyKhz >= vhfRadioMinFrequencyKhz &&
      frequencyKhz <= vhfRadioMaxFrequencyKhz;
}

int? parseVhfRadioFrequency(String text) {
  if (!RegExp(r'^\d{3}\.\d{3}$').hasMatch(text.trim())) return null;

  final double? mhz = double.tryParse(text.trim());
  if (mhz == null) return null;

  final int totalKhzRounded = (mhz * 1000).round();
  if (!isVhfRadioFrequencyInBand(totalKhzRounded)) return null;
  if (!_validAviationOffsets.contains(totalKhzRounded % 100)) return null;

  return totalKhzRounded;
}
