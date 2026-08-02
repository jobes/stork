class CanonicalId {
  /// Normalizes an aircraft identifier by removing source-specific prefixes
  /// (e.g., 'ICAO:', 'FLR:', 'OGN:', 'ICA', 'FLR', 'OGN') and converting the
  /// result to a clean, lowercase hexadecimal string.
  static String normalize(String rawId) {
    String trimmed = rawId.trim();
    if (trimmed.isEmpty) return '';

    // Remove prefixes like ICAO:, FLR:, OGN: (case-insensitive)
    trimmed = trimmed.replaceAll(
      RegExp(r'^(ICAO|FLR|OGN):', caseSensitive: false),
      '',
    );

    // Remove prefixes like ICA, FLR, OGN if directly concatenated before 6-digit hex
    trimmed = trimmed.replaceAll(
      RegExp(r'^(ICAO|ICA|FLR|OGN)(?=[0-9A-Fa-f]{6}$)', caseSensitive: false),
      '',
    );

    return trimmed.toLowerCase();
  }

  /// Returns true if [id] is a 6-character hexadecimal string (FLARM ID or
  /// ICAO 24-bit address). Used as a best-effort hint for cross-source
  /// deduplication (e.g. GDL90 sends the bare ICAO, OGN may use a FLARM ID).
  static bool isIcaoHex(String id) {
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(id.trim());
  }
}
