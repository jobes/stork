class ApiConstants {
  static const openAipMetadataBaseUrl =
      'https://huggingface.co/datasets/jobes666/openaip-mptiles/resolve/main/geojsons';
  static const openAipImageBaseUrl =
      'https://api.core.openaip.net/api/files/images';
  static const openAipWebBaseUrl = 'https://www.openaip.net/data/airports';

  static const faaNotamSearchUrl =
      'https://notams.aim.faa.gov/notamSearch/search';
  static const webProxyNotamSearchUrl =
      'https://www.stork-nav.app/nocors.php?url=';

  // AUP/UUP (Airspace Use Plan / Updated Use Plan) sources.
  /// Slovak LzPS (AIS SR) — public ArcGIS FeatureServer with currently active
  /// airspace reservations. The `where` clause is applied by `SvkAupService`;
  /// see the laamap reference implementation.
  static const svkAupQueryUrl =
      'https://gis.lps.sk/server/rest/services/Hosted/Reservation_(Public)2/FeatureServer/0/query';

  /// Czech ŘLP (AMC ČR) — official AUP/UUP portal. The index page lists the
  /// currently valid AUP and its UUP updates as dated HTML documents under
  /// `data/` (e.g. `data/aup_04082026.htm`), parsed by `CzeAupService`.
  static const czeAupBaseUrl = 'https://aup.rlp.cz/';
}
