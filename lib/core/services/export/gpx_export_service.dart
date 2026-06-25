import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../features/telemetry/domain/repositories/black_box_repository.dart';
import '../../../features/telemetry/domain/models/flight.dart';
import '../../../features/telemetry/domain/models/telemetry_entry.dart';
import '../../../features/telemetry/domain/models/telemetry_state.dart';

class GpxExportService {
  static Future<File?> generateFlightGpx(
    Flight flight,
    BlackBoxRepository repo,
  ) async {
    final entries = await repo.getGpxTelemetryForFlight(flight.uuid);
    if (entries.isEmpty) {
      return null;
    }

    final gpxString = _generateGpx(flight, entries);
    final tempDir = await getTemporaryDirectory();
    final safeName = flight.name.replaceAll(RegExp(r'[^\w\-_]'), '_');
    final file = File('${tempDir.path}/$safeName.gpx');
    await file.writeAsString(gpxString);
    return file;
  }

  static String _generateGpx(Flight flight, List<TelemetryEntry> entries) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<gpx version="1.1" creator="Stork"');
    sb.writeln('     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    sb.writeln('     xmlns="http://www.topografix.com/GPX/1/1"');
    sb.writeln(
      '     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">',
    );

    sb.writeln('  <metadata>');
    sb.writeln('    <name>${_escapeXml(flight.name)}</name>');
    sb.writeln(
      '    <time>${flight.startTime.toUtc().toIso8601String()}</time>',
    );
    sb.writeln('  </metadata>');

    sb.writeln('  <trk>');
    sb.writeln('    <name>${_escapeXml(flight.name)}</name>');
    sb.writeln('    <trkseg>');

    double? currentLat;
    double? currentLon;
    double? currentAlt;
    DateTime? lastPointTime;

    for (final entry in entries) {
      final entryLat = entry.getFieldValue(TelemetryField.latitude);
      final entryLon = entry.getFieldValue(TelemetryField.longitude);
      final entryAlt = entry.getFieldValue(TelemetryField.gpsAltitude);

      if (entryLat != null) {
        currentLat = (entryLat as num).toDouble();
      }
      if (entryLon != null) {
        currentLon = (entryLon as num).toDouble();
      }
      if (entryAlt != null) {
        currentAlt = (entryAlt as num).toDouble();
      }

      if (currentLat != null && currentLon != null) {
        if (lastPointTime == null ||
            entry.timestamp.difference(lastPointTime).inMilliseconds >= 1000) {
          sb.write('      <trkpt lat="$currentLat" lon="$currentLon">');
          if (currentAlt != null) {
            sb.write('<ele>$currentAlt</ele>');
          }
          sb.write('<time>${entry.timestamp.toUtc().toIso8601String()}</time>');
          sb.writeln('</trkpt>');
          lastPointTime = entry.timestamp;
        }
      }
    }

    sb.writeln('    </trkseg>');
    sb.writeln('  </trk>');
    sb.writeln('</gpx>');

    return sb.toString();
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
