import 'dart:convert';

import 'package:clock/clock.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/notam.dart';
import '../../domain/repositories/notam_repository.dart';
import '../utils/notam_decoder.dart';

part 'notam_repository.g.dart';

class HttpNotamRepository implements NotamRepository {
  HttpNotamRepository({required this._client});

  final http.Client _client;

  // The public NOTAM Viewer browser client uses this value to unpack responses.
  static const _responseKey = 'NotamViewer@1.0.0-OZ_2026!#';

  static const _cacheDuration = Duration(hours: 1);
  static const _serverRetryDelay = Duration(seconds: 2);
  static const _retryDelay = Duration(minutes: 5);
  final _cache =
      <String, ({List<Notam> notams, DateTime fetchedAt, bool partial})>{};
  final _retryAfter = <String, DateTime>{};
  Future<void> _requestQueue = Future.value();

  @override
  NotamFetchResult cachedNotams(Iterable<String> locations) {
    final now = clock.now();
    final notams = <String, Notam>{};
    final failed = <String>[];
    final partial = <String>[];
    DateTime? oldestFetch;
    DateTime? nextRefresh;
    for (final location in locations) {
      final cached = _cache[location];
      final retry = _retryAfter[location];
      if (cached != null) {
        final fetchedAt = cached.fetchedAt;
        if (oldestFetch == null || fetchedAt.isBefore(oldestFetch)) {
          oldestFetch = fetchedAt;
        }
        for (final notam in cached.notams) {
          notams[notam.key] = notam;
        }
      }
      if (retry != null) failed.add(location);
      if (cached?.partial == true) partial.add(location);
      final due = retry ?? cached?.fetchedAt.add(_cacheDuration) ?? now;
      if (nextRefresh == null || due.isBefore(nextRefresh)) nextRefresh = due;
    }
    return NotamFetchResult(
      notams.values.toList(),
      failedLocations: failed,
      partialLocations: partial,
      oldestFetch: oldestFetch,
      nextRefresh: nextRefresh,
    );
  }

  @override
  Future<NotamFetchResult> fetchNotamsByLocations(
    Iterable<String> locations, {
    bool force = false,
    bool Function()? isCurrent,
    void Function(NotamFetchResult)? onProgress,
  }) async {
    final codes = locations.map((code) => code.toUpperCase()).toSet();
    // Keep fresh data for codes that can re-enter the selection, and retain
    // stale responses for selected codes so they can be shown during outages.
    final now = clock.now();
    _cache.removeWhere(
      (key, entry) =>
          !codes.contains(key) &&
          !entry.fetchedAt.add(_cacheDuration).isAfter(now),
    );
    _retryAfter.removeWhere(
      (key, until) => !codes.contains(key) && !until.isAfter(now),
    );
    for (final location in codes) {
      if (isCurrent?.call() == false) break;
      if (!force && !_isDue(location)) continue;
      await _queueFetch(location, force: force, isCurrent: isCurrent);
      if (isCurrent?.call() != false) onProgress?.call(cachedNotams(codes));
    }
    return cachedNotams(codes);
  }

  bool _isDue(String location) {
    final due =
        _retryAfter[location] ??
        _cache[location]?.fetchedAt.add(_cacheDuration);
    return due == null || !due.isAfter(clock.now());
  }

  Future<void> _queueFetch(
    String location, {
    required bool force,
    required bool Function()? isCurrent,
  }) {
    final request = _requestQueue.then((_) async {
      if (isCurrent?.call() == false || (!force && !_isDue(location))) return;
      try {
        final response = await _fetchLocation(location, isCurrent);
        _cache[location] = (
          notams: response.notams,
          fetchedAt: clock.now(),
          partial: response.partial,
        );
        _retryAfter.remove(location);
      } on Exception catch (error) {
        if (isCurrent?.call() == false) return;
        debugPrint('NOTAM $location: $error');
        _retryAfter[location] = clock.now().add(_retryDelay);
      }
    });
    _requestQueue = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return request;
  }

  Future<({List<Notam> notams, bool partial})> _fetchLocation(
    String location,
    bool Function()? isCurrent,
  ) async {
    final uri = Uri.parse(
      ApiConstants.notamSearchUrl,
    ).replace(queryParameters: {'location': location});
    Future<http.Response> request() =>
        _client.get(uri).timeout(const Duration(seconds: 15));

    var response = await request();
    if (response.statusCode >= 500 &&
        response.statusCode < 600 &&
        isCurrent?.call() != false) {
      await Future<void>.delayed(_serverRetryDelay);
      if (isCurrent?.call() != false) response = await request();
    }
    if (response.statusCode != 200) {
      throw http.ClientException('NOTAM HTTP ${response.statusCode}', uri);
    }

    final body = response.body.trim();
    final String payload;
    if (body.startsWith('{')) {
      payload = body;
    } else {
      final bytes = base64Decode(body);
      final key = _responseKey.codeUnits;
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] ^= key[i % key.length];
      }
      payload = utf8.decode(bytes);
    }

    final data = jsonDecode(payload);
    if (data case {'success': true, 'notams': List<dynamic> items}) {
      final notams = <Notam>[];
      var partial = false;
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          partial = true;
          continue;
        }
        try {
          notams.add(NotamDecoder.decode(item, location: location));
        } on FormatException catch (error) {
          partial = true;
          debugPrint('NOTAM $location: ${error.message}');
        }
      }
      if (items.isEmpty || notams.isNotEmpty) {
        return (notams: notams, partial: partial);
      }
    }
    throw FormatException('Invalid NOTAM response for $location');
  }
}

@Riverpod(keepAlive: true)
NotamRepository notamRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HttpNotamRepository(client: client);
}
