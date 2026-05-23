// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stork nav';

  @override
  String get mapLoadingError => 'Error loading map style';

  @override
  String get menu => 'Menu';

  @override
  String get offlineMaps => 'Offline maps';

  @override
  String get aircraft => 'Aircraft';

  @override
  String get pilot => 'Pilot';

  @override
  String get unknownAircraft => 'Unknown aircraft';

  @override
  String get anonymousPilot => 'Anonymous pilot';

  @override
  String get editSettings => 'Settings';

  @override
  String get pilotTotalHours => 'Pilot total';

  @override
  String get aircraftTotalHours => 'Aircraft total';

  @override
  String get downloadMaps => 'Download Maps';

  @override
  String get updateMaps => 'Update Maps';

  @override
  String lastUpdate(String date) {
    return 'Last update: $date';
  }

  @override
  String get addArea => 'Add Area';

  @override
  String get deleteArea => 'Delete Area';

  @override
  String get deleteAll => 'Delete All';

  @override
  String areaCount(int count) {
    return 'Areas to download: $count';
  }

  @override
  String get noAreasSelected => 'No areas to download';

  @override
  String get deleteConfirmationTitle => 'Delete All';

  @override
  String get deleteConfirmationContent =>
      'Are you sure you want to delete all areas and downloaded maps? This action is irreversible and will remove all data from storage.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String tileProgress(int downloaded, int total, String size) {
    return '$downloaded / $total tiles ($size)';
  }

  @override
  String get downloadingMetadata => 'Downloading country metadata...';

  @override
  String metadataProgress(int current, int total) {
    return '$current / $total files';
  }

  @override
  String lastUpdateDetail(
    String size,
    String world,
    String openaip,
    String terrain,
    String metadata,
  ) {
    return '($size - World: $world, openAIP: $openaip, Terrain: $terrain, Metadata: $metadata)';
  }

  @override
  String get cancelDownload => 'Cancel Download';

  @override
  String get downloadError =>
      'Error downloading maps. Please check your internet connection.';

  @override
  String get settings => 'Settings';

  @override
  String get mapFontSize => 'Map Font Size';

  @override
  String get mapDefaultZoom => 'Map Default Zoom';

  @override
  String get mapOverviewZoom => 'Map Overview Zoom';

  @override
  String get mapFollowZoom => 'Map Follow Zoom';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get gpsEnable => 'Enable GPS';

  @override
  String get gpsWaiting => 'Waiting for GPS...';

  @override
  String get gpsFollow => 'Follow location';

  @override
  String get gpsStopFollow => 'Stop following location';

  @override
  String get cannelloniGateway => 'Cannelloni Gateway';

  @override
  String get autoSelectDevice => 'Auto-select device';

  @override
  String get selectedDevice => 'Selected device';

  @override
  String get noneSelected => 'None';

  @override
  String get flightSettings => 'Flight Settings';

  @override
  String get inactiveThreshold => 'Inactive (Below minimum)';

  @override
  String get minErrorThreshold => 'Critically low';

  @override
  String get minWarningThreshold => 'Dangerously low';

  @override
  String get maxWarningThreshold => 'Dangerously high';

  @override
  String get maxErrorThreshold => 'Critically high';

  @override
  String get mapSettings => 'Map Settings';

  @override
  String get operationalThreshold => 'Operational (Normal)';

  @override
  String get flightSpeed => 'Flight Speed';

  @override
  String get flightSpeedMaxRange => 'Maximum slider range (km/h)';

  @override
  String get moveWidgets => 'Move widgets';

  @override
  String get resetWidgetLayout => 'Reset widget positions';

  @override
  String get speedUnitKmH => 'kph';

  @override
  String gsSpeedLabel(String value) {
    return 'GS $value kph';
  }

  @override
  String get gpsOnly => 'GPS ONLY';

  @override
  String get noGps => 'NO GPS';

  @override
  String get speedSuffix => ' kph';

  @override
  String get courseLineSettings => 'Course Line';

  @override
  String get courseLineSegmentsCount => 'Segments Count';

  @override
  String get courseLineSegmentDuration => 'Segment Duration (seconds)';
}
