import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/airspace_activity_status.dart';
import '../../domain/services/aup_service.dart';
import '../utils/aup_parsing.dart';

/// AUP/UUP client for the Czech ŘLP (AMC ČR) source.
///
/// The official Czech AUP portal (`https://aup.rlp.cz/`) publishes the
/// currently valid Airspace Use Plan as dated HTML documents. The index page
/// lists the valid AUP followed by its UUP updates:
///
/// ```html
/// <LI><A HREF="data/aup_04082026.htm"> Platný AUP</A> ...</LI>
/// <DD><A HREF="data/uup_04082026_1304_1097994229.htm"> Platný UUP</A> ...</DD>
/// ```
///
/// Each document contains an HTML table (section C — "Prostory spravovane
/// AMC") with one row per AMC-managed airspace activation:
///
/// ```html
/// <TR><TD class="data">1.</TD><TD class="data">TSA2</TD><TD class="data">GND</TD>
/// <TD class="data">F095</TD><TD class="data">06:00</TD><TD class="data">20:00</TD>
/// <TD class="data">ARMY</TD><TD class="data">OAT</TD></TR>
/// ```
///
/// A UUP document only lists the changed rows; rows whose last column contains
/// `CNL` cancel the referenced activation, every other UUP row updates it.
///
/// The AUP portal publishes designators without the ICAO country prefix
/// (`TSA2`), while openAIP names the same airspace `LKTSA2` — parsed entries
/// are mapped to the openAIP form so the shared repository binding stays
/// country-agnostic.
class CzeAupService implements AupService {
  /// Stable source identifier for the activities produced by this service.
  static const String sourceCodeValue = 'CZE_RLP';

  /// openAIP ICAO prefix prepended to parsed Czech designators (`TSA2` ->
  /// `LKTSA2`).
  static const String _openAipDesignatorPrefix = 'LK';

  final http.Client _client;
  final bool _useWebProxy;

  CzeAupService({http.Client? client, bool? useWebProxy})
    : _client = client ?? http.Client(),
      _useWebProxy = useWebProxy ?? kIsWeb;

  @override
  String get sourceCode => sourceCodeValue;

  /// Czech FIRs (LK*), e.g. LKAA (Praha).
  @override
  List<String> get firPrefixes => const ['LK'];

  /// openAIP country code for Czech airspaces.
  @override
  String get countryCode => 'CZ';

  @override
  Future<List<AupAirspaceActivity>> fetchAupData(
    String countryOrFirCode,
  ) async {
    try {
      final indexBody = await _fetchText(
        ApiConstants.czeAupBaseUrl,
        'AUP index',
      );
      final index = parseAupIndex(indexBody);
      if (index == null) return const [];

      final aupBody = await _fetchText(
        '${ApiConstants.czeAupBaseUrl}data/${index.aup}',
        'AUP',
      );
      final aupActivities = parseAupDocument(aupBody, isUup: false);

      // UUP activation times refer to the AUP day, so resolve them against
      // the AUP validity window (the AUP itself starts at 06:00 UTC).
      final dayWindow = parseAupValidity(aupBody);

      // Merge the UUP updates over the base AUP: cancellations (`CNL`) become
      // inactive, every other UUP row updates the activation in place.
      final merged = <String, AupAirspaceActivity>{
        for (final activity in aupActivities) activity.designator: activity,
      };
      for (final uup in index.uups) {
        final uupBody = await _fetchText(
          '${ApiConstants.czeAupBaseUrl}data/$uup',
          'UUP',
        );
        final updates = parseAupDocument(
          uupBody,
          isUup: true,
          dayWindow: dayWindow,
        );
        for (final update in updates) {
          merged[update.designator] = update;
        }
      }
      return merged.values.toList();
    } on TimeoutException catch (e) {
      debugPrint('ŘLP AUP: timeout fetching $countryOrFirCode: $e');
      return const [];
    } on SocketException catch (e) {
      debugPrint('ŘLP AUP: network error fetching $countryOrFirCode: $e');
      return const [];
    } catch (e) {
      debugPrint('ŘLP AUP: failed to fetch $countryOrFirCode: $e');
      return const [];
    }
  }

  Future<String> _fetchText(String rawUrl, String label) async {
    final url = _useWebProxy
        ? '${ApiConstants.webProxyNotamSearchUrl}${Uri.encodeComponent(rawUrl)}'
        : rawUrl;
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
        'ŘLP AUP $label request failed: HTTP ${response.statusCode}',
      );
    }
    // The data documents are windows-1250 encoded (ASCII in practice), the
    // index page is UTF-8; latin1 decodes both without throwing on high bytes.
    return latin1.decode(response.bodyBytes);
  }

  /// Parses the AUP index page into the currently valid AUP file and the
  /// list of valid UUP update files. Returns `null` when no valid AUP link is
  /// found (the "Následující AUP" — next day's plan — is ignored).
  static ({String aup, List<String> uups})? parseAupIndex(String body) {
    final links = RegExp(
      r'<A\s+HREF="data/([a-z0-9_]+\.htm)"',
      caseSensitive: false,
    ).allMatches(body).map((match) => match.group(1)!).toList();

    String? aup;
    final uups = <String>[];
    for (final link in links) {
      if (link.startsWith('aup_')) {
        aup ??= link;
      } else if (link.startsWith('uup_')) {
        uups.add(link);
      }
    }
    if (aup == null) return null;
    return (aup: aup, uups: uups);
  }

  /// Parses the AUP validity window (`OD ... DO ...` in UTC) from a document.
  static ({DateTime validFrom, DateTime validTo})? parseAupValidity(
    String body,
  ) {
    final match = RegExp(
      r'OD\s+(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})\s+(\d{1,2}):(\d{2})\s+DO\s+'
      r'(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})\s+(\d{1,2}):(\d{2})',
      caseSensitive: false,
    ).firstMatch(body);
    if (match == null) return null;
    return (
      validFrom: DateTime.utc(
        int.parse(match.group(3)!),
        int.parse(match.group(2)!),
        int.parse(match.group(1)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
      ),
      validTo: DateTime.utc(
        int.parse(match.group(8)!),
        int.parse(match.group(7)!),
        int.parse(match.group(6)!),
        int.parse(match.group(9)!),
        int.parse(match.group(10)!),
      ),
    );
  }

  /// Parses the document issue time ("Datum a cas vydani") in UTC.
  static DateTime? parseAupIssuedAt(String body) {
    final match = RegExp(
      r'vydani:\s*(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})\s+(\d{1,2}):(\d{2})'
      r'(?::(\d{2}))?',
      caseSensitive: false,
    ).firstMatch(body);
    if (match == null) return null;
    return DateTime.utc(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6) ?? '0'),
    );
  }

  /// Parses the AMC-managed airspace activations (section C) of an AUP or UUP
  /// document into [AupAirspaceActivity] entries.
  ///
  /// Every row becomes an `active` entry with the activation window derived
  /// from the document validity. In a UUP document, rows whose "Dopl.info"
  /// column contains `CNL` cancel the referenced activation and are parsed as
  /// `inactive`. [dayWindow] is the base AUP validity window used to resolve
  /// the activation day for UUP rows (which otherwise carry only times).
  static List<AupAirspaceActivity> parseAupDocument(
    String body, {
    required bool isUup,
    ({DateTime validFrom, DateTime validTo})? dayWindow,
  }) {
    final validity = dayWindow ?? parseAupValidity(body);
    if (validity == null) return const [];
    final issuedAt = parseAupIssuedAt(body) ?? clock.now();

    final section = _sectionC(body);
    if (section.isEmpty) return const [];

    final result = <AupAirspaceActivity>[];
    for (final cells in _tableRows(section)) {
      if (cells.length < 6) continue;
      final rawDesignator = cells[1].trim().toUpperCase();
      if (!_isAmaDesignator(rawDesignator)) continue;
      // Map to the openAIP form (`TSA2` -> `LKTSA2`) so the shared repository
      // binding matches openAIP names without country-specific logic.
      final designator = '$_openAipDesignatorPrefix$rawDesignator';

      final fromTime = _parseTime(cells[4]);
      final toTime = _parseTime(cells[5]);
      if (fromTime == null || toTime == null) continue;

      final detail = cells.length > 7 ? cells[7].trim().toUpperCase() : '';
      final cancelled = isUup && detail.contains('CNL');
      final window = _resolveWindow(validity, fromTime, toTime);

      result.add(
        AupAirspaceActivity(
          airspaceId: designator,
          designator: designator,
          name: designator,
          status: cancelled
              ? AirspaceActivityStatus.inactive
              : AirspaceActivityStatus.active,
          validFrom: window.$1,
          validTo: window.$2,
          lowerLimit: parseAupLimit(cells[2].trim()),
          upperLimit: parseAupLimit(cells[3].trim()),
          source: sourceCodeValue,
          updatedAt: issuedAt,
        ),
      );
    }
    return result;
  }

  /// Extracts the section C ("Prostory spravovane AMC") HTML fragment.
  static String _sectionC(String body) {
    final cMatch = RegExp(
      r'C/\s*Prostory',
      caseSensitive: false,
    ).firstMatch(body);
    if (cMatch == null) return '';
    final dMatches = RegExp(
      r'D/\s*Prostory',
      caseSensitive: false,
    ).allMatches(body, cMatch.end);
    final end = dMatches.isEmpty ? body.length : dMatches.first.start;
    return body.substring(cMatch.end, end);
  }

  /// Extracts `<TD>` cells of every `<TR>` row in [html].
  static List<List<String>> _tableRows(String html) {
    final rowPattern = RegExp(
      r'<TR[^>]*>(.*?)</TR>',
      caseSensitive: false,
      dotAll: true,
    );
    final cellPattern = RegExp(
      r'<TD[^>]*>(.*?)</TD>',
      caseSensitive: false,
      dotAll: true,
    );
    final result = <List<String>>[];
    for (final row in rowPattern.allMatches(html)) {
      final cells = <String>[];
      for (final cell in cellPattern.allMatches(row.group(1)!)) {
        cells.add(
          cell
              .group(1)!
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim(),
        );
      }
      if (cells.isNotEmpty) result.add(cells);
    }
    return result;
  }

  /// Matches AMA designators such as `TSA2`, `TSA2A`, `TRA12`, `TRA7`.
  static final RegExp _designatorPattern = RegExp(r'^[A-Z]{1,4}\d{1,3}[A-Z]?$');

  static bool _isAmaDesignator(String designator) {
    if (designator.isEmpty || designator == 'PROSTOR') return false;
    return _designatorPattern.hasMatch(designator);
  }

  static Duration? _parseTime(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    if (hours > 24 || minutes > 59) return null;
    if (hours == 24 && minutes != 0) return null;
    return Duration(hours: hours, minutes: minutes);
  }

  /// Resolves an activation window (`Od`/`Do` times) against the AUP validity
  /// window in UTC. Windows whose "from" time precedes the day boundary (the
  /// AUP validity start, e.g. 06:00) belong to the last day of the validity
  /// period (e.g. `TRA7 05:00-05:59` is 05:00 on the validity end day).
  static (DateTime, DateTime) _resolveWindow(
    ({DateTime validFrom, DateTime validTo}) validity,
    Duration fromTime,
    Duration toTime,
  ) {
    final boundaryMinutes =
        validity.validFrom.hour * 60 + validity.validFrom.minute;
    final base = fromTime.inMinutes < boundaryMinutes
        ? validity.validTo
        : validity.validFrom;
    var from = DateTime.utc(
      base.year,
      base.month,
      base.day,
      fromTime.inHours,
      fromTime.inMinutes % 60,
    );
    var to = DateTime.utc(
      base.year,
      base.month,
      base.day,
      toTime.inHours,
      toTime.inMinutes % 60,
    );
    if (!to.isAfter(from)) {
      to = to.add(const Duration(days: 1));
    }
    return (from, to);
  }
}
