import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/database/database_service.dart';
import '../../domain/models/notam_catalog.dart';
import '../../domain/services/notam_service.dart';

part 'notam_catalog_repository.g.dart';

@Riverpod(keepAlive: true)
NotamCatalogRepository notamCatalogRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return NotamCatalogRepository(client);
}

class NotamCatalogRepository {
  NotamCatalogRepository(this._client);

  static const _airportFile = 'airports.geojson';
  static const _areaFile = 'notam-areas.json';
  static const files = [_airportFile, _areaFile];
  static const _metadataType = 'notam_catalog';

  final http.Client _client;
  Future<Uint8List>? _onlineAirports;
  Future<List<Uint8List>>? _onlineDocuments;
  Future<void> _selectionQueue = Future.value();

  /// Shares the in-memory airport download between NOTAM and map search.
  Future<Uint8List> loadOnlineAirports() async {
    final loading = _onlineAirports ??= _download(_airportFile);
    try {
      return await loading;
    } catch (_) {
      if (identical(_onlineAirports, loading)) _onlineAirports = null;
      rethrow;
    }
  }

  Future<Set<String>> selectLocations(
    List<Geographic> points, {
    required bool Function() isCurrent,
  }) {
    // Wait for the running worker to exit and skip superseded requests.
    final result = _selectionQueue.then(
      (_) => _selectLocations(points, isCurrent),
    );
    _selectionQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<Set<String>> _selectLocations(
    List<Geographic> points,
    bool Function() isCurrent,
  ) async {
    if (points.isEmpty || !isCurrent()) return const {};
    final offline = await DatabaseService.readOfflineMetadata(
      (path) => isCurrent()
          ? compute(_selectOffline, (path: path, points: points))
          : Future<Set<String>?>.value(null),
    );
    if (!isCurrent()) return const {};
    if (offline != null) {
      _onlineDocuments = null;
      return offline;
    }

    final loading = _onlineDocuments ??= Future.wait([
      loadOnlineAirports(),
      _download(_areaFile),
    ]);
    try {
      final documents = await loading;
      if (!isCurrent()) return const {};
      return await compute(_selectOnline, (
        documents: documents,
        points: points,
      ));
    } catch (_) {
      if (identical(_onlineDocuments, loading)) {
        _onlineDocuments = null;
        _onlineAirports = null;
      }
      rethrow;
    }
  }

  /// Downloads a fresh pair for offline maps and validates it before saving.
  /// [isCurrent] prevents a cancelled download from writing after map cleanup.
  Future<void> downloadForOffline({
    required bool Function() isCurrent,
    required VoidCallback onFileDownloaded,
  }) async {
    final documents = <Uint8List>[];
    for (final file in files) {
      if (!isCurrent()) return;
      final bytes = await _download(file);
      if (!isCurrent()) return;
      documents.add(bytes);
      onFileDownloaded();
    }

    if (!isCurrent()) return;
    final result = await compute(_validateDocuments, documents);
    if (!isCurrent()) return;
    await DatabaseService.insertOpenAipFeatures([
      for (var i = 0; i < files.length; i++)
        {
          'id': files[i],
          'json': result[i],
          'country': '',
          'type': _metadataType,
        },
    ], shouldWrite: isCurrent);
    if (isCurrent()) {
      _onlineDocuments = null;
      _onlineAirports = null;
    }
  }

  Future<Uint8List> _download(String file) async {
    final uri = Uri.parse('${ApiConstants.openAipDatasetBaseUrl}/$file');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'NOTAM catalog HTTP ${response.statusCode}',
        uri,
      );
    }
    return response.bodyBytes;
  }
}

NotamCatalog _parseCatalog(List<String> documents) => NotamCatalog.fromGeoJson(
  jsonDecode(documents[0]) as Map<String, dynamic>,
  jsonDecode(documents[1]) as Map<String, dynamic>,
);

List<String> _validateDocuments(List<Uint8List> documents) {
  final bodies = documents.map(utf8.decode).toList();
  _parseCatalog(bodies);
  return bodies;
}

Set<String>? _selectOffline(({String path, List<Geographic> points}) input) {
  final documents = DatabaseService.readOfflineMetadataPair(
    input.path,
    NotamCatalogRepository._metadataType,
    NotamCatalogRepository.files,
  );
  if (documents == null) return null;
  return selectNotamLocations(_parseCatalog(documents), input.points);
}

Set<String> _selectOnline(
  ({List<Uint8List> documents, List<Geographic> points}) input,
) => selectNotamLocations(
  _parseCatalog(input.documents.map(utf8.decode).toList()),
  input.points,
);
