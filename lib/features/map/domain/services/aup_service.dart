import '../models/airspace_activity_status.dart';

/// Abstraction over an AUP/UUP (Airspace Use Plan / Updated Use Plan) data
/// source. Implementations live in the data layer and know how to fetch and
/// parse a specific provider's payload.
abstract class AupService {
  /// Stable source identifier for the activities produced by this service
  /// (e.g. `'SVK_LZPS'`, `'CZE_RLP'`). Each implementation owns its own value
  /// (see e.g. `SvkAupService.sourceCodeValue`) — there is no central registry
  /// to extend.
  String get sourceCode;

  /// ICAO prefix(es) of the FIR(s) this service covers (e.g. `['LZ']` for the
  /// Slovak LzPS, `['LK']` for the Czech ŘLP). A FIR is routed to this service
  /// when its ICAO code starts with one of the prefixes. Prefixes must be
  /// distinct across services; when several services match, the first one in
  /// the repository's service list wins.
  List<String> get firPrefixes;

  /// ISO 3166-1 alpha-2 country code of the FIR(s) covered by this service
  /// (e.g. `'SK'` for the Slovak LzPS, `'CZ'` for the Czech ŘLP). Used to pick
  /// the openAIP network metadata (`sk_asp.geojson` / `cz_asp.geojson`) when
  /// binding activities to openAIP airspace ids.
  String get countryCode;

  /// Fetches and parses the current AUP/UUP activity for the given country
  /// or FIR code (e.g. `'SK'`, `'LZBB'`).
  Future<List<AupAirspaceActivity>> fetchAupData(String countryOrFirCode);
}
