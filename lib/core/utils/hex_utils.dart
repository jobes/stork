/// Hexadecimal formatting helpers shared by the DroneCAN transport and UI.
///
/// All functions produce upper-case digits because node IDs, unique IDs and
/// image checksums are shown (and compared) in that form.
library;

/// Formats [value] as an upper-case hexadecimal number with at least [digits]
/// digits, e.g. `formatHexInt(0x2A, digits: 4) == '002A'`.
String formatHexInt(int value, {int digits = 1}) =>
    value.toRadixString(16).padLeft(digits, '0').toUpperCase();

/// Formats the 64-bit [value] as an upper-case hexadecimal number with at least
/// [digits] digits.
String formatHexBigInt(BigInt value, {int digits = 1}) =>
    value.toRadixString(16).padLeft(digits, '0').toUpperCase();

/// Formats [bytes] as one upper-case hexadecimal string without separators,
/// e.g. `formatHexBytes([0x01, 0xAB]) == '01AB'`.
String formatHexBytes(Iterable<int> bytes) =>
    bytes.map((byte) => formatHexInt(byte, digits: 2)).join();
