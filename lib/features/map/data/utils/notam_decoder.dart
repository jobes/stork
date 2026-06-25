import '../../domain/models/notam.dart';
import 'notam_translations.dart';

class NotamDecoder {
  static String decodeMessage(String msg) {
    return msg.replaceAllMapped(RegExp(r'\b[A-Z]+\b'), (match) {
      final key = match.group(0)!;
      return notamTranslations[key] ?? key;
    });
  }

  static Map<String, String?> separateToParts(String rawMessage) {
    final qStart = rawMessage.indexOf('Q)');
    final aStart = rawMessage.indexOf('A)');
    final bStart = rawMessage.indexOf('B)');
    final cStart = rawMessage.indexOf('C)');
    final dStart = rawMessage.indexOf('D)');
    final eStart = rawMessage.indexOf('E)');
    final fStart = rawMessage.indexOf('F)');
    final gStart = rawMessage.indexOf('G)');

    if (qStart == -1 ||
        aStart == -1 ||
        bStart == -1 ||
        cStart == -1 ||
        eStart == -1) {
      throw FormatException(
        'Invalid ICAO NOTAM format: missing standard fields',
      );
    }

    final idStr = rawMessage.substring(0, qStart).trim();
    final qStr = rawMessage.substring(qStart + 2, aStart).trim();
    final aStr = rawMessage.substring(aStart + 2, bStart).trim();
    final bStr = rawMessage.substring(bStart + 2, cStart).trim();

    final int cEnd = (dStart == -1) ? eStart : dStart;
    final cStr = rawMessage.substring(cStart + 2, cEnd).trim();

    String? dStr;
    if (dStart != -1) {
      dStr = rawMessage.substring(dStart + 2, eStart).trim();
    }

    final int eEnd = (fStart == -1) ? rawMessage.length : fStart;
    final eStr = rawMessage.substring(eStart + 2, eEnd).trim();

    String? fStr;
    if (fStart != -1) {
      final int fEnd = (gStart == -1) ? rawMessage.length : gStart;
      fStr = rawMessage.substring(fStart + 2, fEnd).trim();
    }

    String? gStr;
    if (gStart != -1) {
      gStr = rawMessage.substring(gStart + 2).trim();
    }

    return {
      'id': idStr,
      'q': qStr,
      'a': aStr,
      'b': bStr,
      'c': cStr,
      'd': dStr,
      'e': eStr,
      'f': fStr,
      'g': gStr,
    };
  }

  static DateTime parseIcaoDate(String dateStr) {
    // Format B) or C) is YYMMDDHHMM (e.g. 2603251315)
    final clean = dateStr.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) {
      throw FormatException('Invalid ICAO date format');
    }
    final yy = clean.substring(0, 2);
    final mm = clean.substring(2, 4);
    final dd = clean.substring(4, 6);
    final hh = clean.substring(6, 8);
    final min = clean.substring(8, 10);
    return DateTime.parse('20$yy-$mm-${dd}T$hh:$min:00Z');
  }

  static Notam decode(Map<String, dynamic> rawNotam) {
    final rawMessage =
        rawNotam['icaoMessage'] as String? ??
        rawNotam['traditionalMessage'] as String? ??
        '';
    final parts = separateToParts(rawMessage);

    final idParts = parts['id']!.split(RegExp(r'\s+'));
    final id = idParts[0];
    final type = idParts.length > 1 ? idParts[1] : '';
    final linkedNotam = idParts.length > 2 ? idParts[2] : null;

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

    if (coordStr.length >= 14) {
      final latDeg = double.tryParse(coordStr.substring(0, 2)) ?? 0.0;
      final latMin = double.tryParse(coordStr.substring(2, 4)) ?? 0.0;
      final latDir = coordStr.substring(4, 5);
      final lonDeg = double.tryParse(coordStr.substring(5, 8)) ?? 0.0;
      final lonMin = double.tryParse(coordStr.substring(8, 10)) ?? 0.0;
      final lonDir = coordStr.substring(10, 11);
      final radNm = double.tryParse(coordStr.substring(11)) ?? 0.0;

      lat = (latDeg + latMin / 60.0) * (latDir == 'S' ? -1 : 1);
      lon = (lonDeg + lonMin / 60.0) * (lonDir == 'W' ? -1 : 1);
      radiusMeters = radNm * 1852.0;
    }

    final fromDate = parseIcaoDate(parts['b']!);
    DateTime toDate;
    try {
      toDate = parseIcaoDate(parts['c']!);
    } catch (_) {
      // Default to fromDate + 3 months if parsing failed (e.g. UFN/EST)
      toDate = fromDate.add(const Duration(days: 90));
    }

    final decodedMsg = decodeMessage(parts['e']!);

    return Notam(
      facilityDesignator: rawNotam['facilityDesignator'] as String? ?? '',
      notamNumber: rawNotam['notamNumber'] as String? ?? '',
      featureName: rawNotam['featureName'] as String? ?? '',
      issueDate: rawNotam['issueDate'] as String? ?? '',
      startDate: rawNotam['startDate'] as String? ?? '',
      endDate: rawNotam['endDate'] as String? ?? '',
      icaoMessage: rawMessage,
      status: rawNotam['status'] as String?,
      keyword: rawNotam['keyword'] as String?,
      airportName: rawNotam['airportName'] as String?,
      id: id,
      type: type,
      linkedNotam: linkedNotam,
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
