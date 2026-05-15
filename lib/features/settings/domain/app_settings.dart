class AppSettings {
  final double mapFontSize;
  final double mapDefaultZoom;
  final double mapOverviewZoom;
  final double mapFollowZoom;

  const AppSettings({
    this.mapFontSize = 1.0,
    this.mapDefaultZoom = 6.0,
    this.mapOverviewZoom = 10.0,
    this.mapFollowZoom = 12.0,
  });

  AppSettings copyWith({
    double? mapFontSize,
    double? mapDefaultZoom,
    double? mapOverviewZoom,
    double? mapFollowZoom,
  }) {
    return AppSettings(
      mapFontSize: mapFontSize ?? this.mapFontSize,
      mapDefaultZoom: mapDefaultZoom ?? this.mapDefaultZoom,
      mapOverviewZoom: mapOverviewZoom ?? this.mapOverviewZoom,
      mapFollowZoom: mapFollowZoom ?? this.mapFollowZoom,
    );
  }

  @override
  String toString() =>
      'AppSettings(mapFontSize: $mapFontSize, mapDefaultZoom: $mapDefaultZoom, mapOverviewZoom: $mapOverviewZoom, mapFollowZoom: $mapFollowZoom)';
}
