import '../../domain/models/notam.dart';
import 'notam_translations.dart';

class NotamDecoder {
  static final _compoundAbbreviations = notamTranslations.keys
      .where((key) => key.contains(' ') || key.contains('/'))
      .map((key) => key.split(' ').map(RegExp.escape).join(r'\s+'))
      .join('|');
  static final _abbreviation = RegExp(
    '\\b(?:($_compoundAbbreviations)|[A-Z]+)\\b',
  );
  static final _whitespace = RegExp(r'\s+');

  static String decodeMessage(String msg) {
    return msg.replaceAllMapped(_abbreviation, (match) {
      final abbreviation = match[0]!;
      final key = match[1]?.replaceAll(_whitespace, ' ') ?? abbreviation;
      return notamTranslations[key] ?? abbreviation;
    });
  }

  static final _fields = RegExp(r'(?:^|\s)([A-GQ])\)');
  static final _date = RegExp(
    r'^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\s*EST)?$',
  );
  static final _coordinates = RegExp(
    r'^(\d{2})(\d{2})([NS])(\d{3})(\d{2})([EW])(\d{3})$',
  );

  static Map<String, String?> separateToParts(String rawMessage) {
    final parts = <String, String?>{};
    final fields = _fields.allMatches(rawMessage).toList();
    if (fields.isNotEmpty) {
      parts['id'] = rawMessage.substring(0, fields.first.start).trim();
      for (var i = 0; i < fields.length; i++) {
        final field = fields[i];
        final end = i + 1 < fields.length
            ? fields[i + 1].start
            : rawMessage.length;
        parts[field.group(1)!.toLowerCase()] = rawMessage
            .substring(field.end, end)
            .trim();
      }
    }
    if ([
      'q',
      'a',
      'b',
      'c',
      'e',
    ].any((name) => parts[name]?.isNotEmpty != true)) {
      throw const FormatException('Missing standard ICAO fields');
    }
    return parts;
  }

  static DateTime parseIcaoDate(String dateStr) {
    final match = _date.firstMatch(dateStr);
    if (match == null) throw const FormatException('Invalid ICAO date');
    final year = 2000 + int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final hour = int.parse(match[4]!);
    final minute = int.parse(match[5]!);
    final result = DateTime.utc(year, month, day, hour, minute);
    if (result.month != month ||
        result.day != day ||
        result.hour != hour ||
        result.minute != minute) {
      throw const FormatException('Invalid ICAO date');
    }
    return result;
  }

  static final _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final _markup = RegExp(
    r'</?(?:b|strong|p)[^>]*>',
    caseSensitive: false,
  );
  static final _sourceDate = RegExp(
    r'^(\d{2})/(\d{2})/(20\d{2}) (\d{4})(?:\s*EST)?$',
  );

  static String _plainText(String message) =>
      message.replaceAll(_lineBreak, '\n').replaceAll(_markup, '').trim();

  static DateTime _parseSourceDate(String value) {
    final match = _sourceDate.firstMatch(value.trim());
    if (match == null) throw const FormatException('Invalid NOTAM source date');
    return parseIcaoDate(
      '${match[3]!.substring(2)}${match[1]}${match[2]}${match[4]}',
    );
  }

  static Notam _decodeTextOnly(Map<String, dynamic> raw, String location) {
    final rawMessage = _plainText(
      (raw['text'] ?? raw['traditionalMessage'] ?? '').toString(),
    );
    final id = (raw['number'] ?? raw['id'] ?? '').toString().trim();
    final start = raw['startDate']?.toString() ?? '';
    final end = raw['endDate']?.toString() ?? '';
    if (id.isEmpty || rawMessage.isEmpty) {
      throw const FormatException('Missing NOTAM identifier or text');
    }

    return Notam(
      endDate: end,
      icaoMessage: rawMessage,
      id: id,
      issuer: location,
      from: _parseSourceDate(start),
      to: end == 'PERM' || end == 'UFN' ? null : _parseSourceDate(end),
      msg: rawMessage,
    );
  }

  static Notam decode(Map<String, dynamic> rawNotam, {String? location}) {
    final rawMessage =
        [
              rawNotam['icaoMessage'],
              rawNotam['text'],
              rawNotam['traditionalMessage'],
            ]
            .whereType<String>()
            .map(_plainText)
            .firstWhere((message) => message.isNotEmpty, orElse: () => '');
    if (location != null &&
        (rawNotam['type'] == 'D' ||
            rawNotam['type'] == 'F' ||
            rawNotam['type'] == 'LTA') &&
        !_fields.allMatches(rawMessage).any((field) => field[1] == 'Q')) {
      return _decodeTextOnly(rawNotam, location);
    }

    final parts = separateToParts(rawMessage);

    final header = parts['id'] ?? '';
    final idParts = header.split(RegExp(r'\s+'));
    // Some FDC messages begin at Q) and supply the identifier separately.
    final id = header.isNotEmpty
        ? idParts.first
        : (rawNotam['number'] ?? rawNotam['id'] ?? '').toString().trim();
    if (id.isEmpty) throw const FormatException('Missing NOTAM identifier');
    final type = idParts.length > 1 ? idParts[1] : '';

    final qFields = parts['q']!.split('/');
    if (qFields.length < 8) {
      throw FormatException('Invalid Q line fields count');
    }

    final fir = qFields[0];
    final lowerLimitFl = int.tryParse(qFields[5]) ?? 0;
    final upperLimitFl = int.tryParse(qFields[6]) ?? 999;
    final coordStr = qFields[7].trim();

    double lat = 0.0;
    double lon = 0.0;
    double radiusMeters = 0.0;

    final coordinates = _coordinates.firstMatch(coordStr);
    if (coordinates != null) {
      final latMinutes = int.parse(coordinates[2]!);
      final lonMinutes = int.parse(coordinates[5]!);
      lat =
          (int.parse(coordinates[1]!) + latMinutes / 60) *
          (coordinates[3] == 'S' ? -1 : 1);
      lon =
          (int.parse(coordinates[4]!) + lonMinutes / 60) *
          (coordinates[6] == 'W' ? -1 : 1);
      if (lat.abs() <= 90 &&
          lon.abs() <= 180 &&
          latMinutes < 60 &&
          lonMinutes < 60) {
        radiusMeters = int.parse(coordinates[7]!) * 1852.0;
      }
    }

    final fromDate = parseIcaoDate(parts['b']!);
    final end = parts['c']!;
    final toDate = end == 'PERM' || end == 'UFN' ? null : parseIcaoDate(end);

    final decodedMsg = decodeMessage(parts['e']!);

    return Notam(
      featureName: rawNotam['featureName']?.toString() ?? '',
      endDate: rawNotam['endDate']?.toString() ?? end,
      icaoMessage: rawMessage,
      id: id,
      type: type,
      issuer: parts['a']!,
      from: fromDate,
      to: toDate,
      schedule: parts['d'],
      msg: decodedMsg,
      lowerLimit2: parts['f'],
      upperLimit2: parts['g'],
      fir: fir,
      latitude: lat,
      longitude: lon,
      radius: radiusMeters,
      flightLevelLowerLimit: lowerLimitFl,
      flightLevelUpperLimit: upperLimitFl,
    );
  }
}
