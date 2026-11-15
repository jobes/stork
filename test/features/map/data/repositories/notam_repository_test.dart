import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/features/map/data/repositories/notam_repository.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';

void main() {
  const rawNotam =
      'A1234/26 NOTAMN\r\n'
      'Q) LZBB/QFAXX/IV/NBO/A/000/999/4810N01710E025\r\n'
      'A) LZIB B) 2611130000 C) PERM\r\n'
      'D) DAILY 0800-1600\r\n'
      'E) WIP ON APRON\r\n'
      'F) GND G) 1500FT AGL';

  test(
    'queries each ICAO code once and decodes the NOTAM Viewer response',
    () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        expect(request.method, 'GET');
        final bytes = utf8.encode(
          jsonEncode({
            'success': true,
            'notams': [
              {'location': 'LZIB', 'number': 'A1234/26', 'text': rawNotam},
            ],
          }),
        );
        const key = 'NotamViewer@1.0.0-OZ_2026!#';
        final encoded = base64Encode([
          for (var i = 0; i < bytes.length; i++)
            bytes[i] ^ key.codeUnitAt(i % key.length),
        ]);
        return http.Response(encoded, 200);
      });
      final repository = HttpNotamRepository(client: client);
      final notams = await repository.fetchNotamsByLocations([
        'lzbb',
        'LZIB',
        'LZBB',
      ]);

      expect(requests.map((uri) => uri.host), everyElement('notams.online'));
      expect(requests.map((uri) => uri.path), everyElement('/api/notams.php'));
      expect(requests.map((uri) => uri.queryParameters['location']), [
        'LZBB',
        'LZIB',
      ]);
      final notam = notams.notams.single;
      expect(notam.key, 'LZBB:LZIB:A1234/26');
      expect(notam.from, DateTime.utc(2026, 11, 13));
      expect(notam.to, isNull);
      expect(notam.schedule, 'DAILY 0800-1600');
      expect(notam.upperLimit2, '1500FT AGL');
      expect(notam.icaoMessage, rawNotam);
    },
  );

  test('retains successful results and backs off failed locations', () async {
    final requests = <String>[];
    final repository = HttpNotamRepository(
      client: MockClient((request) async {
        final location = request.url.queryParameters['location']!;
        requests.add(location);
        if (location == 'LZIB') return http.Response('{"error":true}', 200);
        return http.Response(
          jsonEncode({
            'success': true,
            'notams': [
              {'location': 'LZBB', 'number': 'A1234/26', 'text': rawNotam},
            ],
          }),
          200,
        );
      }),
    );
    final first = await repository.fetchNotamsByLocations(['LZBB', 'LZIB']);
    expect(first.notams, hasLength(1));
    expect(first.failedLocations, ['LZIB']);
    expect(repository.cachedNotams(['lzbb', 'lzib', 'LzIb']), first);

    final second = await repository.fetchNotamsByLocations(['lzbb', 'lzib']);
    expect(second.notams, hasLength(1));
    expect(second.failedLocations, ['LZIB']);
    expect(requests, ['LZBB', 'LZIB']);
  });

  test(
    'retries a transient NOTAM Viewer server error for the same ICAO',
    () async {
      final requests = <String>[];
      final repository = HttpNotamRepository(
        client: MockClient((request) async {
          requests.add(request.url.queryParameters['location']!);
          if (requests.length == 1) {
            return http.Response(
              '{"error":true,"message":"Failed to fetch NOTAMs from FAA API"}',
              500,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'notams': [
                {'text': rawNotam},
              ],
            }),
            200,
          );
        }),
      );

      final result = await repository.fetchNotamsByLocations(['LZIB']);
      expect(requests, ['LZIB', 'LZIB']);
      expect(result.notams.single.id, 'A1234/26');
      expect(result.hasIssue, isFalse);
    },
  );

  test(
    'refreshes only new or one-hour-old ICAOs and retains stale results on failure',
    () async {
      var now = DateTime.utc(2026, 11, 14);
      final start = now;
      final requests = <String>[];
      var failLzbb = false;
      final repository = HttpNotamRepository(
        client: MockClient((request) async {
          final code = request.url.queryParameters['location']!;
          requests.add(code);
          if (code == 'LZBB' && failLzbb) {
            return http.Response('Unavailable', 503);
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'notams': [
                if (code == 'LZBB')
                  {'location': code, 'number': 'A1234/26', 'text': rawNotam},
              ],
            }),
            200,
          );
        }),
      );
      await withClock(Clock(() => now), () async {
        await repository.fetchNotamsByLocations(['LZBB']);
        now = start.add(const Duration(minutes: 59));
        await repository.fetchNotamsByLocations(['LZBB', 'LZIB']);
        await repository.fetchNotamsByLocations(['LZIB']);
        expect(repository.cachedNotams(['LZIB']).notams, isEmpty);
        expect(requests, ['LZBB', 'LZIB']);

        now = start.add(const Duration(hours: 1));
        failLzbb = true;
        final stale = await repository.fetchNotamsByLocations(['LZBB', 'LZIB']);
        expect(requests, ['LZBB', 'LZIB', 'LZBB', 'LZBB']);
        expect(stale.notams.single.id, 'A1234/26');
        expect(stale.oldestFetch, start);
        expect(stale.failedLocations, ['LZBB']);
        expect(stale.nextRefresh, now.add(const Duration(minutes: 5)));

        failLzbb = false;
        final fresh = await repository.fetchNotamsByLocations([
          'LZBB',
          'LZIB',
        ], force: true);
        expect(requests, ['LZBB', 'LZIB', 'LZBB', 'LZBB', 'LZBB', 'LZIB']);
        expect(fresh.failedLocations, isEmpty);
        expect(fresh.oldestFetch, now);
      });
    },
  );
  test(
    'publishes partial responses before remaining ICAO requests finish',
    () async {
      final pending = Completer<http.Response>();
      final first = Completer<NotamFetchResult>();
      final repository = HttpNotamRepository(
        client: MockClient((request) async {
          if (request.url.queryParameters['location'] == 'LKAA') {
            return pending.future;
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'notams': [
                {'text': rawNotam},
                {
                  'icaoMessage': rawNotam
                      .replaceAll('\r\n', '<br>\n')
                      .replaceFirst('Q)', '<b>Q) </b>')
                      .replaceFirst('A1234', 'A1235'),
                },
                {
                  'number': '10/514',
                  'type': 'D',
                  'text': '!JFK 10/514 JFK TWY A13 LGT U/S',
                  'startDate': '10/29/2026 0400',
                  'endDate': '12/31/2026 2359',
                },
                {
                  'number': '6/3765',
                  'type': 'F',
                  'icaoMessage': rawNotam.substring(rawNotam.indexOf('Q)')),
                },
                {'text': 'Unsupported record'},
              ],
            }),
            200,
          );
        }),
      );
      final result = repository.fetchNotamsByLocations(
        ['KJFK', 'LKAA'],
        onProgress: (value) {
          if (!first.isCompleted) first.complete(value);
        },
      );
      final progress = await first.future;
      expect(progress.notams.map((n) => n.id), [
        'A1234/26',
        'A1235/26',
        '10/514',
        '6/3765',
      ]);
      expect(progress.notams[1].radius, greaterThan(0));
      expect(progress.notams[2].radius, 0);
      expect(progress.partialLocations, ['KJFK']);
      expect(progress.failedLocations, isEmpty);
      pending.complete(http.Response('Unavailable', 503));
      final completed = await result;
      expect(completed.partialLocations, ['KJFK']);
      expect(completed.failedLocations, ['LKAA']);
    },
  );
}
