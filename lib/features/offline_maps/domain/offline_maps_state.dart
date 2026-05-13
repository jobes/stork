import 'package:maplibre/maplibre.dart';

class OfflineMapArea {
  final String id;
  final Geographic northwest;
  final Geographic southeast;

  OfflineMapArea({
    required this.id,
    required this.northwest,
    required this.southeast,
  });

  OfflineMapArea copyWith({
    String? id,
    Geographic? northwest,
    Geographic? southeast,
  }) {
    return OfflineMapArea(
      id: id ?? this.id,
      northwest: northwest ?? this.northwest,
      southeast: southeast ?? this.southeast,
    );
  }

  @override
  String toString() {
    return 'OfflineMapArea(id: $id, nw: ${northwest.lat}, ${northwest.lon}, se: ${southeast.lat}, ${southeast.lon})';
  }
}

class OfflineMapsState {
  final List<OfflineMapArea> regions;
  final DateTime? downloadDate;
  final bool isDownloaded;
  final int downloadedTiles;
  final int totalTiles;
  final int downloadedBytes;
  final int worldBytes;
  final int openAipBytes;
  final int terrainBytes;
  final bool isDownloading;

  // Metadata tracking
  final bool isDownloadingMetadata;
  final int metadataBytes;
  final int downloadedMetadataCountries;
  final int totalMetadataCountries;
  final bool hasError;

  OfflineMapsState({
    this.regions = const [],
    this.downloadDate,
    this.isDownloaded = false,
    this.downloadedTiles = 0,
    this.totalTiles = 0,
    this.downloadedBytes = 0,
    this.worldBytes = 0,
    this.openAipBytes = 0,
    this.terrainBytes = 0,
    this.isDownloading = false,
    this.isDownloadingMetadata = false,
    this.metadataBytes = 0,
    this.downloadedMetadataCountries = 0,
    this.totalMetadataCountries = 0,
    this.hasError = false,
  });

  OfflineMapsState copyWith({
    List<OfflineMapArea>? regions,
    DateTime? downloadDate,
    bool? isDownloaded,
    int? downloadedTiles,
    int? totalTiles,
    int? downloadedBytes,
    int? worldBytes,
    int? openAipBytes,
    int? terrainBytes,
    bool? isDownloading,
    bool? isDownloadingMetadata,
    int? metadataBytes,
    int? downloadedMetadataCountries,
    int? totalMetadataCountries,
    bool? hasError,
  }) {
    return OfflineMapsState(
      regions: regions ?? this.regions,
      downloadDate: downloadDate ?? this.downloadDate,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      totalTiles: totalTiles ?? this.totalTiles,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      worldBytes: worldBytes ?? this.worldBytes,
      openAipBytes: openAipBytes ?? this.openAipBytes,
      terrainBytes: terrainBytes ?? this.terrainBytes,
      isDownloading: isDownloading ?? this.isDownloading,
      isDownloadingMetadata:
          isDownloadingMetadata ?? this.isDownloadingMetadata,
      metadataBytes: metadataBytes ?? this.metadataBytes,
      downloadedMetadataCountries:
          downloadedMetadataCountries ?? this.downloadedMetadataCountries,
      totalMetadataCountries:
          totalMetadataCountries ?? this.totalMetadataCountries,
      hasError: hasError ?? this.hasError,
    );
  }
}
