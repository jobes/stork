import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/services/protomaps_resolver.dart';

void main() {
  test('refresh only selects an archive for the next app session', () async {
    SharedPreferences.setMockInitialValues({
      ProtomapsResolver.cacheKey:
          'https://build.protomaps.com/20261101.pmtiles',
    });
    final prefs = await SharedPreferences.getInstance();
    ProtomapsResolver.useCachedUrl(prefs);
    final selected = ProtomapsResolver.sessionUrl;
    expect(selected, 'https://build.protomaps.com/20261101.pmtiles');
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response(
        jsonEncode([
          {'key': '20261119.pmtiles'},
          {'key': '20261102.pmtiles'},
          {'key': '../invalid.json'},
        ]),
        200,
      );
    });
    addTearDown(client.close);
    expect(requests, 0);
    await ProtomapsResolver.refreshForNextLaunch(prefs, client: client);
    expect(requests, 1);
    expect(
      prefs.getString(ProtomapsResolver.cacheKey),
      'https://build.protomaps.com/20261119.pmtiles',
    );
    ProtomapsResolver.useCachedUrl(prefs);
    expect(ProtomapsResolver.sessionUrl, selected);

    final failing = MockClient((_) async => http.Response('offline', 503));
    addTearDown(failing.close);
    await ProtomapsResolver.refreshForNextLaunch(prefs, client: failing);
    expect(
      prefs.getString(ProtomapsResolver.cacheKey),
      'https://build.protomaps.com/20261119.pmtiles',
    );
    expect(ProtomapsResolver.sessionUrl, selected);
  });
}
