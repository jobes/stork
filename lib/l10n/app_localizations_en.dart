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
  String get airportDetails => 'Airport Details';

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
  String get flightSpeedMaxRange => 'Maximum slider range';

  @override
  String get moveWidgets => 'Move widgets';

  @override
  String get resetWidgetLayout => 'Reset widget positions';

  @override
  String get speedUnitKmH => 'kph';

  @override
  String gsSpeedLabel(String value, String unit) {
    return 'GS $value $unit';
  }

  @override
  String get gpsOnly => 'GPS ONLY';

  @override
  String get noGps => 'NO GPS';

  @override
  String get speedUnitSettings => 'Speed Unit';

  @override
  String get speedUnitMs => 'm/s';

  @override
  String get speedUnitMph => 'mph';

  @override
  String get speedUnitKnots => 'knots';

  @override
  String get speedUnitKnotsAbbreviation => 'kt';

  @override
  String get courseLineSettings => 'Course Line';

  @override
  String get courseLineSegmentsCount => 'Segment Count';

  @override
  String get courseLineSegmentDuration => 'Segment Duration (seconds)';

  @override
  String get durationSuffix => ' s';

  @override
  String get speedDetailsTitle => 'Speed Details';

  @override
  String get iasAvailable => 'IAS Available';

  @override
  String get gpsSpeedAvailable => 'GPS Speed Available';

  @override
  String get gpsAccuracy => 'GPS Accuracy';

  @override
  String get horizontalAccuracy => 'Horizontal Accuracy';

  @override
  String get verticalAccuracy => 'Vertical Accuracy';

  @override
  String get satelliteCount => 'Satellite Count';

  @override
  String get gpsAltitude => 'GPS Altitude';

  @override
  String get valueYes => 'Yes';

  @override
  String get valueNo => 'No';

  @override
  String get valueNotAvailable => 'N/A';

  @override
  String get iasShortTitle => 'IAS';

  @override
  String get gsShortTitle => 'GS';

  @override
  String get indicatedAirSpeedShort => 'Indicated Airspeed (IAS)';

  @override
  String get groundSpeedShort => 'Ground Speed (GS)';

  @override
  String get speedSource => 'Speed Source';

  @override
  String get activeThreshold => 'Active Speed Threshold';

  @override
  String get gpsSourceInternal => 'Internal GPS (Phone)';

  @override
  String get gpsSourceDroneCan => 'DroneCAN (Receiver)';

  @override
  String get gpsNotificationTitle => 'Stork GPS Service';

  @override
  String get gpsNotificationText => 'Tracking location in background';

  @override
  String get altitude => 'Altitude';

  @override
  String get altitudeSourceBaro => 'BARO (DroneCAN)';

  @override
  String get altitudeSourceGpsReceiver => 'GPS (DroneCAN)';

  @override
  String get altitudeSourceGpsPhone => 'GPS (Mobile)';

  @override
  String get altitudeSourceNone => 'N/A';

  @override
  String get altitudeUnitMeters => 'm';

  @override
  String get altitudeUnitSettings => 'Altitude Unit';

  @override
  String get altitudeUnitMetersMsl => 'm MSL';

  @override
  String get altitudeUnitFeetMsl => 'ft MSL';

  @override
  String get altitudeUnitMetersGnd => 'm AGL';

  @override
  String get altitudeUnitFeetGnd => 'ft AGL';

  @override
  String get heightUnitSettings => 'Height Unit (AGL)';

  @override
  String get altitudeDetailsTitle => 'Altitude Details';

  @override
  String get altitudeSource => 'Altitude Source';

  @override
  String get autoQnhLabel => 'Automatic QNH Calculation';

  @override
  String get currentQnhLabel => 'Current QNH';

  @override
  String get autoQnhHelpTooltip =>
      'QNH is automatically set at startup on the ground and will be adjusted from GPS during flight because atmospheric pressure changes with weather.';

  @override
  String get qnhSetting => 'QNH Setting';

  @override
  String get invalidQnhNumber => 'Invalid number';

  @override
  String qnhOutOfRange(String min, String max) {
    return 'Out of range ($min - $max)';
  }

  @override
  String get terrainElevation => 'Terrain Elevation';

  @override
  String get terrainUnderPosition => 'Terrain under position';

  @override
  String get close => 'Close';

  @override
  String get airport => 'Airport';

  @override
  String get tune => 'TUNE';

  @override
  String get mainRunway => 'Main runway';

  @override
  String get airportLoadingDetails => 'Loading details...';

  @override
  String get airportFailedToLoad => 'Failed to load airport details.';

  @override
  String airportNameLabel(String name) {
    return 'Name: $name';
  }

  @override
  String airportIcao(String icao) {
    return 'ICAO: $icao';
  }

  @override
  String get airportElevation => 'Elevation';

  @override
  String get airportFrequencies => 'Frequencies';

  @override
  String get airportRunways => 'Runways';

  @override
  String get airportPpr => 'PPR';

  @override
  String get airportPrivate => 'Private';

  @override
  String get airportSkydiveActivity => 'Skydive';

  @override
  String get airportWinchOnly => 'Winch';

  @override
  String airportRunwayDimension(String length, String width, String unit) {
    return '${length}x$width $unit';
  }

  @override
  String get airportSurface => 'Surface';

  @override
  String get airportTypeLabel => 'Type';

  @override
  String get airportViewOnOpenAip => 'View on openAIP';

  @override
  String get airportTypeAirport => 'Airport';

  @override
  String get airportTypeGliderSite => 'Glider Site';

  @override
  String get airportTypeAirfieldCivil => 'Airfield Civil';

  @override
  String get airportTypeInternationalAirport => 'International Airport';

  @override
  String get airportTypeHeliportMilitary => 'Heliport Military';

  @override
  String get airportTypeMilitaryAerodrome => 'Military Aerodrome';

  @override
  String get airportTypeUltralightFlyingSite => 'Ultralight Flying Site';

  @override
  String get airportTypeHeliportCivil => 'Heliport Civil';

  @override
  String get airportTypeAerodromeClosed => 'Aerodrome Closed';

  @override
  String get airportTypeIfr => 'IFR';

  @override
  String get airportTypeAirfieldWater => 'Airfield Water';

  @override
  String get airportTypeLandingStrip => 'Landing Strip';

  @override
  String get airportTypeAgriculturalLandingStrip =>
      'Agricultural Landing Strip';

  @override
  String get airportTypeAltiport => 'Altiport';

  @override
  String airportTypeUnknown(String type) {
    return 'Unknown ($type)';
  }

  @override
  String get frequencyTypeApproach => 'Approach';

  @override
  String get frequencyTypeApron => 'Apron';

  @override
  String get frequencyTypeArrival => 'Arrival';

  @override
  String get frequencyTypeCenter => 'Center';

  @override
  String get frequencyTypeCtaf => 'CTAF';

  @override
  String get frequencyTypeDelivery => 'Delivery';

  @override
  String get frequencyTypeDeparture => 'Departure';

  @override
  String get frequencyTypeFis => 'FIS';

  @override
  String get frequencyTypeGliding => 'Gliding';

  @override
  String get frequencyTypeGround => 'Ground';

  @override
  String get frequencyTypeInfo => 'Info';

  @override
  String get frequencyTypeMulticom => 'Multicom';

  @override
  String get frequencyTypeUnicom => 'Unicom';

  @override
  String get frequencyTypeRadar => 'Radar';

  @override
  String get frequencyTypeTower => 'Tower';

  @override
  String get frequencyTypeAtis => 'ATIS';

  @override
  String get frequencyTypeRadio => 'Radio';

  @override
  String get frequencyTypeOther => 'Other';

  @override
  String get frequencyTypeAirmet => 'AIRMET';

  @override
  String get frequencyTypeAwos => 'AWOS';

  @override
  String get frequencyTypeLights => 'Lights';

  @override
  String get frequencyTypeVolmet => 'VOLMET';

  @override
  String frequencyTypeUnknown(String type) {
    return 'Unknown ($type)';
  }

  @override
  String get surfaceAsphalt => 'Asphalt';

  @override
  String get surfaceConcrete => 'Concrete';

  @override
  String get surfaceGrass => 'Grass';

  @override
  String get surfaceSand => 'Sand';

  @override
  String get surfaceWater => 'Water';

  @override
  String get surfaceBituminousTar => 'Bituminous Tar';

  @override
  String get surfaceBrick => 'Brick';

  @override
  String get surfaceMacadam => 'Macadam';

  @override
  String get surfaceStone => 'Stone';

  @override
  String get surfaceCoral => 'Coral';

  @override
  String get surfaceClay => 'Clay';

  @override
  String get surfaceLaterite => 'Laterite';

  @override
  String get surfaceGravel => 'Gravel';

  @override
  String get surfaceEarth => 'Earth';

  @override
  String get surfaceIce => 'Ice';

  @override
  String get surfaceSnow => 'Snow';

  @override
  String get surfaceProtectiveLaminate => 'Protective Laminate';

  @override
  String get surfaceMetal => 'Metal';

  @override
  String get surfaceLandingMat => 'Landing Mat';

  @override
  String get surfaceUnknown => 'Unknown';

  @override
  String get surfaceWood => 'Wood';

  @override
  String surfaceUnknownType(String type) {
    return 'Unknown ($type)';
  }

  @override
  String get airspace => 'Airspace';

  @override
  String get airspacesTitle => 'Airspaces';

  @override
  String get airspaceClass => 'Class';

  @override
  String get airspaceType => 'Type';

  @override
  String get airspaceLimits => 'Limits';

  @override
  String get airspaceLimitLower => 'Lower Limit';

  @override
  String get airspaceLimitUpper => 'Upper Limit';

  @override
  String get airspaceActivity => 'Activity';

  @override
  String get airspaceFrequencies => 'Frequencies';

  @override
  String get airspaceViewOnOpenAip => 'View on openAIP';

  @override
  String get airspacesLoadingDetails => 'Loading airspace details...';

  @override
  String get airspacesFailedToLoad => 'Failed to load airspace details.';

  @override
  String get airspacesAtLocation => 'Airspaces at this location';

  @override
  String get airspaceFlagByNotam => 'BY NOTAM';

  @override
  String get airspaceFlagOnRequest => 'ON REQUEST';

  @override
  String get airspaceFlagOnDemand => 'ON DEMAND';

  @override
  String get airspaceClassA => 'Class A';

  @override
  String get airspaceClassB => 'Class B';

  @override
  String get airspaceClassC => 'Class C';

  @override
  String get airspaceClassD => 'Class D';

  @override
  String get airspaceClassE => 'Class E';

  @override
  String get airspaceClassF => 'Class F';

  @override
  String get airspaceClassG => 'Class G';

  @override
  String get airspaceClassUnclassified => 'Unclassified / SUA';

  @override
  String get airspaceClassUnknown => 'Unknown class';

  @override
  String get airspaceTypeOther => 'Other';

  @override
  String get airspaceTypeRestricted => 'Restricted';

  @override
  String get airspaceTypeDanger => 'Danger';

  @override
  String get airspaceTypeProhibited => 'Prohibited';

  @override
  String get airspaceTypeCtr => 'CTR';

  @override
  String get airspaceTypeTmz => 'TMZ';

  @override
  String get airspaceTypeRmz => 'RMZ';

  @override
  String get airspaceTypeTma => 'TMA';

  @override
  String get airspaceTypeTra => 'TRA';

  @override
  String get airspaceTypeTsa => 'TSA';

  @override
  String get airspaceTypeFir => 'FIR';

  @override
  String get airspaceTypeUir => 'UIR';

  @override
  String get airspaceTypeAdiz => 'ADIZ';

  @override
  String get airspaceTypeAtz => 'ATZ';

  @override
  String get airspaceTypeMatz => 'MATZ';

  @override
  String get airspaceTypeAirway => 'Airway';

  @override
  String get airspaceTypeMtr => 'MTR';

  @override
  String get airspaceTypeAlert => 'Alert Area';

  @override
  String get airspaceTypeWarning => 'Warning Area';

  @override
  String get airspaceTypeProtected => 'Protected Area';

  @override
  String get airspaceTypeHtz => 'HTZ';

  @override
  String get airspaceTypeGliding => 'Gliding Sector';

  @override
  String get airspaceTypeTrp => 'TRP';

  @override
  String get airspaceTypeTiz => 'TIZ';

  @override
  String get airspaceTypeTia => 'TIA';

  @override
  String get airspaceTypeMta => 'MTA';

  @override
  String get airspaceTypeCta => 'CTA';

  @override
  String get airspaceTypeAcc => 'ACC Sector';

  @override
  String get airspaceTypeSport => 'Sport / Recreational Activity';

  @override
  String get airspaceTypeLowOverflight => 'Low Altitude Restriction';

  @override
  String get airspaceTypeMrt => 'MRT';

  @override
  String get airspaceTypeTfr => 'TFR';

  @override
  String get airspaceTypeVfr => 'VFR Sector';

  @override
  String get airspaceTypeFis => 'FIS Sector';

  @override
  String get airspaceTypeLta => 'LTA';

  @override
  String get airspaceTypeUta => 'UTA';

  @override
  String get airspaceTypeMctr => 'MCTR';

  @override
  String get airspaceTypeUnknown => 'Unknown';

  @override
  String get airspaceActivityNone => 'None';

  @override
  String get airspaceActivityParachuting => 'Parachuting';

  @override
  String get airspaceActivityAerobatics => 'Aerobatics';

  @override
  String get airspaceActivityAeroclub => 'Aeroclub';

  @override
  String get airspaceActivityUlm => 'ULM';

  @override
  String get airspaceActivityGliding => 'Gliding';

  @override
  String get airspaceActivityUnknown => 'Unknown';
}
