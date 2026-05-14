class AppSettings {
  final double mapFontSize;
  final double mapDefaultZoom;

  const AppSettings({
    this.mapFontSize = 1.0,
    this.mapDefaultZoom = 6.0,
  });

  AppSettings copyWith({
    double? mapFontSize,
    double? mapDefaultZoom,
  }) {
    return AppSettings(
      mapFontSize: mapFontSize ?? this.mapFontSize,
      mapDefaultZoom: mapDefaultZoom ?? this.mapDefaultZoom,
    );
  }

  @override
  String toString() => 'AppSettings(mapFontSize: $mapFontSize, mapDefaultZoom: $mapDefaultZoom)';
}
