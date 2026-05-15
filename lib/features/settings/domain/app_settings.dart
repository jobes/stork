class AppSettings {
  final double mapFontSize;
  final double mapDefaultZoom;
  final double mapOverviewZoom;
  final double mapFollowZoom;
  final double flightMinSpeed;

  const AppSettings({
    this.mapFontSize = 1.0,
    this.mapDefaultZoom = 6.0,
    this.mapOverviewZoom = 10.0,
    this.mapFollowZoom = 12.0,
    this.flightMinSpeed = 15.0,
  });

  AppSettings copyWith({
    double? mapFontSize,
    double? mapDefaultZoom,
    double? mapOverviewZoom,
    double? mapFollowZoom,
    double? flightMinSpeed,
  }) {
    return AppSettings(
      mapFontSize: mapFontSize ?? this.mapFontSize,
      mapDefaultZoom: mapDefaultZoom ?? this.mapDefaultZoom,
      mapOverviewZoom: mapOverviewZoom ?? this.mapOverviewZoom,
      mapFollowZoom: mapFollowZoom ?? this.mapFollowZoom,
      flightMinSpeed: flightMinSpeed ?? this.flightMinSpeed,
    );
  }

  @override
  String toString() =>
      'AppSettings(mapFontSize: $mapFontSize, mapDefaultZoom: $mapDefaultZoom, mapOverviewZoom: $mapOverviewZoom, mapFollowZoom: $mapFollowZoom)';
}
