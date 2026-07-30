import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sk'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Stork nav'**
  String get appTitle;

  /// Message displayed when the map style fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading map style'**
  String get mapLoadingError;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @offlineMaps.
  ///
  /// In en, this message translates to:
  /// **'Offline maps'**
  String get offlineMaps;

  /// No description provided for @aircraft.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get aircraft;

  /// No description provided for @pilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot'**
  String get pilot;

  /// No description provided for @unknownAircraft.
  ///
  /// In en, this message translates to:
  /// **'Unknown aircraft'**
  String get unknownAircraft;

  /// No description provided for @anonymousPilot.
  ///
  /// In en, this message translates to:
  /// **'Anonymous pilot'**
  String get anonymousPilot;

  /// No description provided for @unknownPilotWithId.
  ///
  /// In en, this message translates to:
  /// **'Unknown pilot ({id})'**
  String unknownPilotWithId(String id);

  /// No description provided for @unknownAircraftWithId.
  ///
  /// In en, this message translates to:
  /// **'Unknown aircraft ({id})'**
  String unknownAircraftWithId(String id);

  /// No description provided for @filterAllPilots.
  ///
  /// In en, this message translates to:
  /// **'All pilots'**
  String get filterAllPilots;

  /// No description provided for @filterAllAircraft.
  ///
  /// In en, this message translates to:
  /// **'All aircraft'**
  String get filterAllAircraft;

  /// No description provided for @editSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get editSettings;

  /// No description provided for @pilotTotalHours.
  ///
  /// In en, this message translates to:
  /// **'Pilot total'**
  String get pilotTotalHours;

  /// No description provided for @aircraftTotalHours.
  ///
  /// In en, this message translates to:
  /// **'Aircraft total'**
  String get aircraftTotalHours;

  /// No description provided for @airportDetails.
  ///
  /// In en, this message translates to:
  /// **'Airport Details'**
  String get airportDetails;

  /// No description provided for @downloadMaps.
  ///
  /// In en, this message translates to:
  /// **'Download Maps'**
  String get downloadMaps;

  /// No description provided for @updateMaps.
  ///
  /// In en, this message translates to:
  /// **'Update Maps'**
  String get updateMaps;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update: {date}'**
  String lastUpdate(String date);

  /// No description provided for @addArea.
  ///
  /// In en, this message translates to:
  /// **'Add Area'**
  String get addArea;

  /// No description provided for @deleteArea.
  ///
  /// In en, this message translates to:
  /// **'Delete Area'**
  String get deleteArea;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @areaCount.
  ///
  /// In en, this message translates to:
  /// **'Areas to download: {count}'**
  String areaCount(int count);

  /// No description provided for @noAreasSelected.
  ///
  /// In en, this message translates to:
  /// **'No areas to download'**
  String get noAreasSelected;

  /// No description provided for @deleteConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteConfirmationTitle;

  /// No description provided for @deleteConfirmationContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all areas and downloaded maps? This action is irreversible and will remove all data from storage.'**
  String get deleteConfirmationContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tileProgress.
  ///
  /// In en, this message translates to:
  /// **'{downloaded} / {total} tiles ({size})'**
  String tileProgress(int downloaded, int total, String size);

  /// No description provided for @downloadingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Downloading country metadata...'**
  String get downloadingMetadata;

  /// No description provided for @metadataProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} files'**
  String metadataProgress(int current, int total);

  /// No description provided for @lastUpdateDetail.
  ///
  /// In en, this message translates to:
  /// **'({size} - World: {world}, openAIP: {openaip}, Terrain: {terrain}, Metadata: {metadata})'**
  String lastUpdateDetail(
    String size,
    String world,
    String openaip,
    String terrain,
    String metadata,
  );

  /// Button to cancel the current map download
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancelDownload;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Error downloading maps. Please check your internet connection.'**
  String get downloadError;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @mapFontSize.
  ///
  /// In en, this message translates to:
  /// **'Map Font Size'**
  String get mapFontSize;

  /// No description provided for @mapDefaultZoom.
  ///
  /// In en, this message translates to:
  /// **'Map Default Zoom'**
  String get mapDefaultZoom;

  /// No description provided for @mapOverviewZoom.
  ///
  /// In en, this message translates to:
  /// **'Map Overview Zoom'**
  String get mapOverviewZoom;

  /// No description provided for @mapFollowZoom.
  ///
  /// In en, this message translates to:
  /// **'Map Follow Zoom'**
  String get mapFollowZoom;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @gpsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS'**
  String get gpsEnable;

  /// No description provided for @gpsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS...'**
  String get gpsWaiting;

  /// No description provided for @gpsFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow location'**
  String get gpsFollow;

  /// No description provided for @gpsStopFollow.
  ///
  /// In en, this message translates to:
  /// **'Stop following location'**
  String get gpsStopFollow;

  /// No description provided for @cannelloniGateway.
  ///
  /// In en, this message translates to:
  /// **'Cannelloni Gateway'**
  String get cannelloniGateway;

  /// No description provided for @autoSelectDevice.
  ///
  /// In en, this message translates to:
  /// **'Auto-select device'**
  String get autoSelectDevice;

  /// No description provided for @selectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Selected device'**
  String get selectedDevice;

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneSelected;

  /// No description provided for @flightSettings.
  ///
  /// In en, this message translates to:
  /// **'Flight Settings'**
  String get flightSettings;

  /// No description provided for @inactiveThreshold.
  ///
  /// In en, this message translates to:
  /// **'Inactive (Below minimum)'**
  String get inactiveThreshold;

  /// No description provided for @minErrorThreshold.
  ///
  /// In en, this message translates to:
  /// **'Critically low'**
  String get minErrorThreshold;

  /// No description provided for @minWarningThreshold.
  ///
  /// In en, this message translates to:
  /// **'Dangerously low'**
  String get minWarningThreshold;

  /// No description provided for @maxWarningThreshold.
  ///
  /// In en, this message translates to:
  /// **'Dangerously high'**
  String get maxWarningThreshold;

  /// No description provided for @maxErrorThreshold.
  ///
  /// In en, this message translates to:
  /// **'Critically high'**
  String get maxErrorThreshold;

  /// No description provided for @mapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map Settings'**
  String get mapSettings;

  /// No description provided for @operationalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Operational (Normal)'**
  String get operationalThreshold;

  /// No description provided for @flightSpeed.
  ///
  /// In en, this message translates to:
  /// **'Flight Speed'**
  String get flightSpeed;

  /// No description provided for @flightSpeedMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum slider range'**
  String get flightSpeedMaxRange;

  /// No description provided for @moveWidgets.
  ///
  /// In en, this message translates to:
  /// **'Move widgets'**
  String get moveWidgets;

  /// No description provided for @resetWidgetLayout.
  ///
  /// In en, this message translates to:
  /// **'Reset widget positions'**
  String get resetWidgetLayout;

  /// Speed unit in kilometers per hour
  ///
  /// In en, this message translates to:
  /// **'kph'**
  String get speedUnitKmH;

  /// Ground speed label with speed value and unit
  ///
  /// In en, this message translates to:
  /// **'GS {value} {unit}'**
  String gsSpeedLabel(String value, String unit);

  /// Indicator when only GPS speed is available
  ///
  /// In en, this message translates to:
  /// **'GPS ONLY'**
  String get gpsOnly;

  /// Indicator when GPS is not available
  ///
  /// In en, this message translates to:
  /// **'NO GPS'**
  String get noGps;

  /// No description provided for @speedUnitSettings.
  ///
  /// In en, this message translates to:
  /// **'Speed Unit'**
  String get speedUnitSettings;

  /// No description provided for @speedUnitMs.
  ///
  /// In en, this message translates to:
  /// **'m/s'**
  String get speedUnitMs;

  /// No description provided for @speedUnitMph.
  ///
  /// In en, this message translates to:
  /// **'mph'**
  String get speedUnitMph;

  /// No description provided for @speedUnitKnots.
  ///
  /// In en, this message translates to:
  /// **'knots'**
  String get speedUnitKnots;

  /// Speed unit abbreviation for knots
  ///
  /// In en, this message translates to:
  /// **'kt'**
  String get speedUnitKnotsAbbreviation;

  /// No description provided for @courseLineSettings.
  ///
  /// In en, this message translates to:
  /// **'Course Line'**
  String get courseLineSettings;

  /// No description provided for @courseLineSegmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Segment Count'**
  String get courseLineSegmentsCount;

  /// No description provided for @courseLineSegmentDuration.
  ///
  /// In en, this message translates to:
  /// **'Segment Duration (seconds)'**
  String get courseLineSegmentDuration;

  /// Suffix for duration values with a leading space
  ///
  /// In en, this message translates to:
  /// **' s'**
  String get durationSuffix;

  /// No description provided for @speedDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Details'**
  String get speedDetailsTitle;

  /// No description provided for @iasAvailable.
  ///
  /// In en, this message translates to:
  /// **'IAS Available'**
  String get iasAvailable;

  /// No description provided for @gpsSpeedAvailable.
  ///
  /// In en, this message translates to:
  /// **'GPS Speed Available'**
  String get gpsSpeedAvailable;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS Accuracy'**
  String get gpsAccuracy;

  /// No description provided for @horizontalAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Accuracy'**
  String get horizontalAccuracy;

  /// No description provided for @verticalAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Vertical Accuracy'**
  String get verticalAccuracy;

  /// No description provided for @satelliteCount.
  ///
  /// In en, this message translates to:
  /// **'Satellite Count'**
  String get satelliteCount;

  /// No description provided for @gpsAltitude.
  ///
  /// In en, this message translates to:
  /// **'GPS Altitude'**
  String get gpsAltitude;

  /// No description provided for @valueYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get valueYes;

  /// No description provided for @valueNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get valueNo;

  /// No description provided for @valueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get valueNotAvailable;

  /// No description provided for @iasShortTitle.
  ///
  /// In en, this message translates to:
  /// **'IAS'**
  String get iasShortTitle;

  /// No description provided for @gsShortTitle.
  ///
  /// In en, this message translates to:
  /// **'GS'**
  String get gsShortTitle;

  /// No description provided for @indicatedAirSpeedShort.
  ///
  /// In en, this message translates to:
  /// **'Indicated Airspeed (IAS)'**
  String get indicatedAirSpeedShort;

  /// No description provided for @groundSpeedShort.
  ///
  /// In en, this message translates to:
  /// **'Ground Speed (GS)'**
  String get groundSpeedShort;

  /// No description provided for @speedSource.
  ///
  /// In en, this message translates to:
  /// **'Speed Source'**
  String get speedSource;

  /// No description provided for @activeThreshold.
  ///
  /// In en, this message translates to:
  /// **'Active Speed Threshold'**
  String get activeThreshold;

  /// No description provided for @gpsSourceInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal GPS (Phone)'**
  String get gpsSourceInternal;

  /// No description provided for @gpsSourceDroneCan.
  ///
  /// In en, this message translates to:
  /// **'DroneCAN (Receiver)'**
  String get gpsSourceDroneCan;

  /// No description provided for @gpsNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Stork GPS Service'**
  String get gpsNotificationTitle;

  /// No description provided for @gpsNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Tracking location in background'**
  String get gpsNotificationText;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @altitudeSourceBaro.
  ///
  /// In en, this message translates to:
  /// **'BARO (DroneCAN)'**
  String get altitudeSourceBaro;

  /// No description provided for @altitudeSourceGpsReceiver.
  ///
  /// In en, this message translates to:
  /// **'GPS (DroneCAN)'**
  String get altitudeSourceGpsReceiver;

  /// No description provided for @altitudeSourceGpsPhone.
  ///
  /// In en, this message translates to:
  /// **'GPS (Mobile)'**
  String get altitudeSourceGpsPhone;

  /// No description provided for @altitudeSourceNone.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get altitudeSourceNone;

  /// No description provided for @altitudeUnitMeters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get altitudeUnitMeters;

  /// No description provided for @altitudeUnitSettings.
  ///
  /// In en, this message translates to:
  /// **'Altitude Unit'**
  String get altitudeUnitSettings;

  /// No description provided for @altitudeUnitMetersMsl.
  ///
  /// In en, this message translates to:
  /// **'m MSL'**
  String get altitudeUnitMetersMsl;

  /// No description provided for @altitudeUnitFeetMsl.
  ///
  /// In en, this message translates to:
  /// **'ft MSL'**
  String get altitudeUnitFeetMsl;

  /// No description provided for @altitudeUnitMetersGnd.
  ///
  /// In en, this message translates to:
  /// **'m AGL'**
  String get altitudeUnitMetersGnd;

  /// No description provided for @altitudeUnitFeetGnd.
  ///
  /// In en, this message translates to:
  /// **'ft AGL'**
  String get altitudeUnitFeetGnd;

  /// No description provided for @heightUnitSettings.
  ///
  /// In en, this message translates to:
  /// **'Height Unit (AGL)'**
  String get heightUnitSettings;

  /// No description provided for @altitudeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Altitude Details'**
  String get altitudeDetailsTitle;

  /// No description provided for @altitudeSource.
  ///
  /// In en, this message translates to:
  /// **'Altitude Source'**
  String get altitudeSource;

  /// No description provided for @autoQnhLabel.
  ///
  /// In en, this message translates to:
  /// **'Automatic QNH Calculation'**
  String get autoQnhLabel;

  /// Label for the current QNH value
  ///
  /// In en, this message translates to:
  /// **'Current QNH'**
  String get currentQnhLabel;

  /// No description provided for @autoQnhHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'QNH is automatically set at startup on the ground and will be adjusted from GPS during flight because atmospheric pressure changes with weather.'**
  String get autoQnhHelpTooltip;

  /// No description provided for @qnhSetting.
  ///
  /// In en, this message translates to:
  /// **'QNH Setting'**
  String get qnhSetting;

  /// No description provided for @invalidQnhNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidQnhNumber;

  /// No description provided for @qnhOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range ({min} - {max})'**
  String qnhOutOfRange(String min, String max);

  /// No description provided for @terrainElevation.
  ///
  /// In en, this message translates to:
  /// **'Terrain Elevation'**
  String get terrainElevation;

  /// No description provided for @terrainUnderPosition.
  ///
  /// In en, this message translates to:
  /// **'Terrain under position'**
  String get terrainUnderPosition;

  /// Fallback name for airport
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get airport;

  /// Label for frequency badge
  ///
  /// In en, this message translates to:
  /// **'TUNE'**
  String get tune;

  /// Label for the main runway
  ///
  /// In en, this message translates to:
  /// **'Main runway'**
  String get mainRunway;

  /// No description provided for @airportLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading details...'**
  String get airportLoadingDetails;

  /// No description provided for @airportFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load airport details.'**
  String get airportFailedToLoad;

  /// No description provided for @airportNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String airportNameLabel(String name);

  /// No description provided for @airportIcao.
  ///
  /// In en, this message translates to:
  /// **'ICAO: {icao}'**
  String airportIcao(String icao);

  /// No description provided for @airportElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get airportElevation;

  /// No description provided for @airportFrequencies.
  ///
  /// In en, this message translates to:
  /// **'Frequencies'**
  String get airportFrequencies;

  /// No description provided for @airportRunways.
  ///
  /// In en, this message translates to:
  /// **'Runways'**
  String get airportRunways;

  /// No description provided for @airportPpr.
  ///
  /// In en, this message translates to:
  /// **'PPR'**
  String get airportPpr;

  /// No description provided for @airportPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get airportPrivate;

  /// No description provided for @airportSkydiveActivity.
  ///
  /// In en, this message translates to:
  /// **'Skydive'**
  String get airportSkydiveActivity;

  /// No description provided for @airportWinchOnly.
  ///
  /// In en, this message translates to:
  /// **'Winch'**
  String get airportWinchOnly;

  /// No description provided for @airportRunwayDimension.
  ///
  /// In en, this message translates to:
  /// **'{length}x{width} {unit}'**
  String airportRunwayDimension(String length, String width, String unit);

  /// No description provided for @airportSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get airportSurface;

  /// No description provided for @airportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get airportTypeLabel;

  /// No description provided for @airportViewOnOpenAip.
  ///
  /// In en, this message translates to:
  /// **'View on openAIP'**
  String get airportViewOnOpenAip;

  /// No description provided for @airportTypeAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get airportTypeAirport;

  /// No description provided for @airportTypeGliderSite.
  ///
  /// In en, this message translates to:
  /// **'Glider Site'**
  String get airportTypeGliderSite;

  /// No description provided for @airportTypeAirfieldCivil.
  ///
  /// In en, this message translates to:
  /// **'Airfield Civil'**
  String get airportTypeAirfieldCivil;

  /// No description provided for @airportTypeInternationalAirport.
  ///
  /// In en, this message translates to:
  /// **'International Airport'**
  String get airportTypeInternationalAirport;

  /// No description provided for @airportTypeHeliportMilitary.
  ///
  /// In en, this message translates to:
  /// **'Heliport Military'**
  String get airportTypeHeliportMilitary;

  /// No description provided for @airportTypeMilitaryAerodrome.
  ///
  /// In en, this message translates to:
  /// **'Military Aerodrome'**
  String get airportTypeMilitaryAerodrome;

  /// No description provided for @airportTypeUltralightFlyingSite.
  ///
  /// In en, this message translates to:
  /// **'Ultralight Flying Site'**
  String get airportTypeUltralightFlyingSite;

  /// No description provided for @airportTypeHeliportCivil.
  ///
  /// In en, this message translates to:
  /// **'Heliport Civil'**
  String get airportTypeHeliportCivil;

  /// No description provided for @airportTypeAerodromeClosed.
  ///
  /// In en, this message translates to:
  /// **'Aerodrome Closed'**
  String get airportTypeAerodromeClosed;

  /// No description provided for @airportTypeIfr.
  ///
  /// In en, this message translates to:
  /// **'IFR'**
  String get airportTypeIfr;

  /// No description provided for @airportTypeAirfieldWater.
  ///
  /// In en, this message translates to:
  /// **'Airfield Water'**
  String get airportTypeAirfieldWater;

  /// No description provided for @airportTypeLandingStrip.
  ///
  /// In en, this message translates to:
  /// **'Landing Strip'**
  String get airportTypeLandingStrip;

  /// No description provided for @airportTypeAgriculturalLandingStrip.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Landing Strip'**
  String get airportTypeAgriculturalLandingStrip;

  /// No description provided for @airportTypeAltiport.
  ///
  /// In en, this message translates to:
  /// **'Altiport'**
  String get airportTypeAltiport;

  /// No description provided for @airportTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown ({type})'**
  String airportTypeUnknown(String type);

  /// No description provided for @frequencyTypeApproach.
  ///
  /// In en, this message translates to:
  /// **'Approach'**
  String get frequencyTypeApproach;

  /// No description provided for @frequencyTypeApron.
  ///
  /// In en, this message translates to:
  /// **'Apron'**
  String get frequencyTypeApron;

  /// No description provided for @frequencyTypeArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get frequencyTypeArrival;

  /// No description provided for @frequencyTypeCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get frequencyTypeCenter;

  /// No description provided for @frequencyTypeCtaf.
  ///
  /// In en, this message translates to:
  /// **'CTAF'**
  String get frequencyTypeCtaf;

  /// No description provided for @frequencyTypeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get frequencyTypeDelivery;

  /// No description provided for @frequencyTypeDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get frequencyTypeDeparture;

  /// No description provided for @frequencyTypeFis.
  ///
  /// In en, this message translates to:
  /// **'FIS'**
  String get frequencyTypeFis;

  /// No description provided for @frequencyTypeGliding.
  ///
  /// In en, this message translates to:
  /// **'Gliding'**
  String get frequencyTypeGliding;

  /// No description provided for @frequencyTypeGround.
  ///
  /// In en, this message translates to:
  /// **'Ground'**
  String get frequencyTypeGround;

  /// No description provided for @frequencyTypeInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get frequencyTypeInfo;

  /// No description provided for @frequencyTypeMulticom.
  ///
  /// In en, this message translates to:
  /// **'Multicom'**
  String get frequencyTypeMulticom;

  /// No description provided for @frequencyTypeUnicom.
  ///
  /// In en, this message translates to:
  /// **'Unicom'**
  String get frequencyTypeUnicom;

  /// No description provided for @frequencyTypeRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get frequencyTypeRadar;

  /// No description provided for @frequencyTypeTower.
  ///
  /// In en, this message translates to:
  /// **'Tower'**
  String get frequencyTypeTower;

  /// No description provided for @frequencyTypeAtis.
  ///
  /// In en, this message translates to:
  /// **'ATIS'**
  String get frequencyTypeAtis;

  /// No description provided for @frequencyTypeRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get frequencyTypeRadio;

  /// No description provided for @frequencyTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get frequencyTypeOther;

  /// No description provided for @frequencyTypeAirmet.
  ///
  /// In en, this message translates to:
  /// **'AIRMET'**
  String get frequencyTypeAirmet;

  /// No description provided for @frequencyTypeAwos.
  ///
  /// In en, this message translates to:
  /// **'AWOS'**
  String get frequencyTypeAwos;

  /// No description provided for @frequencyTypeLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get frequencyTypeLights;

  /// No description provided for @frequencyTypeVolmet.
  ///
  /// In en, this message translates to:
  /// **'VOLMET'**
  String get frequencyTypeVolmet;

  /// No description provided for @frequencyTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown ({type})'**
  String frequencyTypeUnknown(String type);

  /// No description provided for @surfaceAsphalt.
  ///
  /// In en, this message translates to:
  /// **'Asphalt'**
  String get surfaceAsphalt;

  /// No description provided for @surfaceConcrete.
  ///
  /// In en, this message translates to:
  /// **'Concrete'**
  String get surfaceConcrete;

  /// No description provided for @surfaceGrass.
  ///
  /// In en, this message translates to:
  /// **'Grass'**
  String get surfaceGrass;

  /// No description provided for @surfaceSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get surfaceSand;

  /// No description provided for @surfaceWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get surfaceWater;

  /// No description provided for @surfaceBituminousTar.
  ///
  /// In en, this message translates to:
  /// **'Bituminous Tar'**
  String get surfaceBituminousTar;

  /// No description provided for @surfaceBrick.
  ///
  /// In en, this message translates to:
  /// **'Brick'**
  String get surfaceBrick;

  /// No description provided for @surfaceMacadam.
  ///
  /// In en, this message translates to:
  /// **'Macadam'**
  String get surfaceMacadam;

  /// No description provided for @surfaceStone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get surfaceStone;

  /// No description provided for @surfaceCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get surfaceCoral;

  /// No description provided for @surfaceClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get surfaceClay;

  /// No description provided for @surfaceLaterite.
  ///
  /// In en, this message translates to:
  /// **'Laterite'**
  String get surfaceLaterite;

  /// No description provided for @surfaceGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get surfaceGravel;

  /// No description provided for @surfaceEarth.
  ///
  /// In en, this message translates to:
  /// **'Earth'**
  String get surfaceEarth;

  /// No description provided for @surfaceIce.
  ///
  /// In en, this message translates to:
  /// **'Ice'**
  String get surfaceIce;

  /// No description provided for @surfaceSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get surfaceSnow;

  /// No description provided for @surfaceProtectiveLaminate.
  ///
  /// In en, this message translates to:
  /// **'Protective Laminate'**
  String get surfaceProtectiveLaminate;

  /// No description provided for @surfaceMetal.
  ///
  /// In en, this message translates to:
  /// **'Metal'**
  String get surfaceMetal;

  /// No description provided for @surfaceLandingMat.
  ///
  /// In en, this message translates to:
  /// **'Landing Mat'**
  String get surfaceLandingMat;

  /// No description provided for @surfaceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get surfaceUnknown;

  /// No description provided for @surfaceWood.
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get surfaceWood;

  /// No description provided for @surfaceUnknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown ({type})'**
  String surfaceUnknownType(String type);

  /// Fallback name for airspace
  ///
  /// In en, this message translates to:
  /// **'Airspace'**
  String get airspace;

  /// No description provided for @airspacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Airspaces'**
  String get airspacesTitle;

  /// No description provided for @airspaceClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get airspaceClass;

  /// No description provided for @airspaceType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get airspaceType;

  /// No description provided for @airspaceLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get airspaceLimits;

  /// No description provided for @airspaceLimitLower.
  ///
  /// In en, this message translates to:
  /// **'Lower Limit'**
  String get airspaceLimitLower;

  /// No description provided for @airspaceLimitUpper.
  ///
  /// In en, this message translates to:
  /// **'Upper Limit'**
  String get airspaceLimitUpper;

  /// No description provided for @airspaceActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get airspaceActivity;

  /// No description provided for @airspaceFrequencies.
  ///
  /// In en, this message translates to:
  /// **'Frequencies'**
  String get airspaceFrequencies;

  /// No description provided for @airspaceViewOnOpenAip.
  ///
  /// In en, this message translates to:
  /// **'View on openAIP'**
  String get airspaceViewOnOpenAip;

  /// No description provided for @airspacesLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading airspace details...'**
  String get airspacesLoadingDetails;

  /// No description provided for @airspacesFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load airspace details.'**
  String get airspacesFailedToLoad;

  /// No description provided for @airspacesAtLocation.
  ///
  /// In en, this message translates to:
  /// **'Airspaces at this location'**
  String get airspacesAtLocation;

  /// No description provided for @airspaceFlagByNotam.
  ///
  /// In en, this message translates to:
  /// **'BY NOTAM'**
  String get airspaceFlagByNotam;

  /// No description provided for @airspaceFlagOnRequest.
  ///
  /// In en, this message translates to:
  /// **'ON REQUEST'**
  String get airspaceFlagOnRequest;

  /// No description provided for @airspaceFlagOnDemand.
  ///
  /// In en, this message translates to:
  /// **'ON DEMAND'**
  String get airspaceFlagOnDemand;

  /// No description provided for @airspaceClassA.
  ///
  /// In en, this message translates to:
  /// **'Class A'**
  String get airspaceClassA;

  /// No description provided for @airspaceClassB.
  ///
  /// In en, this message translates to:
  /// **'Class B'**
  String get airspaceClassB;

  /// No description provided for @airspaceClassC.
  ///
  /// In en, this message translates to:
  /// **'Class C'**
  String get airspaceClassC;

  /// No description provided for @airspaceClassD.
  ///
  /// In en, this message translates to:
  /// **'Class D'**
  String get airspaceClassD;

  /// No description provided for @airspaceClassE.
  ///
  /// In en, this message translates to:
  /// **'Class E'**
  String get airspaceClassE;

  /// No description provided for @airspaceClassF.
  ///
  /// In en, this message translates to:
  /// **'Class F'**
  String get airspaceClassF;

  /// No description provided for @airspaceClassG.
  ///
  /// In en, this message translates to:
  /// **'Class G'**
  String get airspaceClassG;

  /// No description provided for @airspaceClassUnclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified / SUA'**
  String get airspaceClassUnclassified;

  /// No description provided for @airspaceClassUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown class'**
  String get airspaceClassUnknown;

  /// No description provided for @airspaceTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get airspaceTypeOther;

  /// No description provided for @airspaceTypeRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get airspaceTypeRestricted;

  /// No description provided for @airspaceTypeDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get airspaceTypeDanger;

  /// No description provided for @airspaceTypeProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited'**
  String get airspaceTypeProhibited;

  /// No description provided for @airspaceTypeCtr.
  ///
  /// In en, this message translates to:
  /// **'CTR'**
  String get airspaceTypeCtr;

  /// No description provided for @airspaceTypeTmz.
  ///
  /// In en, this message translates to:
  /// **'TMZ'**
  String get airspaceTypeTmz;

  /// No description provided for @airspaceTypeRmz.
  ///
  /// In en, this message translates to:
  /// **'RMZ'**
  String get airspaceTypeRmz;

  /// No description provided for @airspaceTypeTma.
  ///
  /// In en, this message translates to:
  /// **'TMA'**
  String get airspaceTypeTma;

  /// No description provided for @airspaceTypeTra.
  ///
  /// In en, this message translates to:
  /// **'TRA'**
  String get airspaceTypeTra;

  /// No description provided for @airspaceTypeTsa.
  ///
  /// In en, this message translates to:
  /// **'TSA'**
  String get airspaceTypeTsa;

  /// No description provided for @airspaceTypeFir.
  ///
  /// In en, this message translates to:
  /// **'FIR'**
  String get airspaceTypeFir;

  /// No description provided for @airspaceTypeUir.
  ///
  /// In en, this message translates to:
  /// **'UIR'**
  String get airspaceTypeUir;

  /// No description provided for @airspaceTypeAdiz.
  ///
  /// In en, this message translates to:
  /// **'ADIZ'**
  String get airspaceTypeAdiz;

  /// No description provided for @airspaceTypeAtz.
  ///
  /// In en, this message translates to:
  /// **'ATZ'**
  String get airspaceTypeAtz;

  /// No description provided for @airspaceTypeMatz.
  ///
  /// In en, this message translates to:
  /// **'MATZ'**
  String get airspaceTypeMatz;

  /// No description provided for @airspaceTypeAirway.
  ///
  /// In en, this message translates to:
  /// **'Airway'**
  String get airspaceTypeAirway;

  /// No description provided for @airspaceTypeMtr.
  ///
  /// In en, this message translates to:
  /// **'MTR'**
  String get airspaceTypeMtr;

  /// No description provided for @airspaceTypeAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert Area'**
  String get airspaceTypeAlert;

  /// No description provided for @airspaceTypeWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning Area'**
  String get airspaceTypeWarning;

  /// No description provided for @airspaceTypeProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected Area'**
  String get airspaceTypeProtected;

  /// No description provided for @airspaceTypeHtz.
  ///
  /// In en, this message translates to:
  /// **'HTZ'**
  String get airspaceTypeHtz;

  /// No description provided for @airspaceTypeGliding.
  ///
  /// In en, this message translates to:
  /// **'Gliding Sector'**
  String get airspaceTypeGliding;

  /// No description provided for @airspaceTypeTrp.
  ///
  /// In en, this message translates to:
  /// **'TRP'**
  String get airspaceTypeTrp;

  /// No description provided for @airspaceTypeTiz.
  ///
  /// In en, this message translates to:
  /// **'TIZ'**
  String get airspaceTypeTiz;

  /// No description provided for @airspaceTypeTia.
  ///
  /// In en, this message translates to:
  /// **'TIA'**
  String get airspaceTypeTia;

  /// No description provided for @airspaceTypeMta.
  ///
  /// In en, this message translates to:
  /// **'MTA'**
  String get airspaceTypeMta;

  /// No description provided for @airspaceTypeCta.
  ///
  /// In en, this message translates to:
  /// **'CTA'**
  String get airspaceTypeCta;

  /// No description provided for @airspaceTypeAcc.
  ///
  /// In en, this message translates to:
  /// **'ACC Sector'**
  String get airspaceTypeAcc;

  /// No description provided for @airspaceTypeSport.
  ///
  /// In en, this message translates to:
  /// **'Sport / Recreational Activity'**
  String get airspaceTypeSport;

  /// No description provided for @airspaceTypeLowOverflight.
  ///
  /// In en, this message translates to:
  /// **'Low Altitude Restriction'**
  String get airspaceTypeLowOverflight;

  /// No description provided for @airspaceTypeMrt.
  ///
  /// In en, this message translates to:
  /// **'MRT'**
  String get airspaceTypeMrt;

  /// No description provided for @airspaceTypeTfr.
  ///
  /// In en, this message translates to:
  /// **'TFR'**
  String get airspaceTypeTfr;

  /// No description provided for @airspaceTypeVfr.
  ///
  /// In en, this message translates to:
  /// **'VFR Sector'**
  String get airspaceTypeVfr;

  /// No description provided for @airspaceTypeFis.
  ///
  /// In en, this message translates to:
  /// **'FIS Sector'**
  String get airspaceTypeFis;

  /// No description provided for @airspaceTypeLta.
  ///
  /// In en, this message translates to:
  /// **'LTA'**
  String get airspaceTypeLta;

  /// No description provided for @airspaceTypeUta.
  ///
  /// In en, this message translates to:
  /// **'UTA'**
  String get airspaceTypeUta;

  /// No description provided for @airspaceTypeMctr.
  ///
  /// In en, this message translates to:
  /// **'MCTR'**
  String get airspaceTypeMctr;

  /// No description provided for @airspaceTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get airspaceTypeUnknown;

  /// No description provided for @airspaceActivityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get airspaceActivityNone;

  /// No description provided for @airspaceActivityParachuting.
  ///
  /// In en, this message translates to:
  /// **'Parachuting'**
  String get airspaceActivityParachuting;

  /// No description provided for @airspaceActivityAerobatics.
  ///
  /// In en, this message translates to:
  /// **'Aerobatics'**
  String get airspaceActivityAerobatics;

  /// No description provided for @airspaceActivityAeroclub.
  ///
  /// In en, this message translates to:
  /// **'Aeroclub'**
  String get airspaceActivityAeroclub;

  /// No description provided for @airspaceActivityUlm.
  ///
  /// In en, this message translates to:
  /// **'ULM'**
  String get airspaceActivityUlm;

  /// No description provided for @airspaceActivityGliding.
  ///
  /// In en, this message translates to:
  /// **'Gliding'**
  String get airspaceActivityGliding;

  /// No description provided for @airspaceActivityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get airspaceActivityUnknown;

  /// No description provided for @flightTime.
  ///
  /// In en, this message translates to:
  /// **'Flight Time'**
  String get flightTime;

  /// No description provided for @flightDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flight Details'**
  String get flightDetailsTitle;

  /// No description provided for @flightDuration.
  ///
  /// In en, this message translates to:
  /// **'Flight Duration'**
  String get flightDuration;

  /// No description provided for @flightDistance.
  ///
  /// In en, this message translates to:
  /// **'Flight Distance'**
  String get flightDistance;

  /// No description provided for @flightStartTime.
  ///
  /// In en, this message translates to:
  /// **'Flight Start Time'**
  String get flightStartTime;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @navigateToPoint.
  ///
  /// In en, this message translates to:
  /// **'Navigate to point'**
  String get navigateToPoint;

  /// No description provided for @addPointToNavigation.
  ///
  /// In en, this message translates to:
  /// **'Add point to navigation'**
  String get addPointToNavigation;

  /// No description provided for @averageSpeed.
  ///
  /// In en, this message translates to:
  /// **'Expected flight speed'**
  String get averageSpeed;

  /// No description provided for @groundSpeed.
  ///
  /// In en, this message translates to:
  /// **'Ground speed'**
  String get groundSpeed;

  /// No description provided for @navigationRequiresLocation.
  ///
  /// In en, this message translates to:
  /// **'Navigation requires current location.'**
  String get navigationRequiresLocation;

  /// No description provided for @noNavigationPoints.
  ///
  /// In en, this message translates to:
  /// **'No navigation points. Tap on the map to add points.'**
  String get noNavigationPoints;

  /// No description provided for @leg.
  ///
  /// In en, this message translates to:
  /// **'Leg'**
  String get leg;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @navigationActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get navigationActive;

  /// No description provided for @navigationStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get navigationStopped;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startNavigation;

  /// No description provided for @stopNavigation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopNavigation;

  /// No description provided for @clearNavigation.
  ///
  /// In en, this message translates to:
  /// **'Clear route'**
  String get clearNavigation;

  /// No description provided for @clearNavigationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the navigation route?'**
  String get clearNavigationConfirm;

  /// No description provided for @navigationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation Details'**
  String get navigationDetailsTitle;

  /// No description provided for @nearestPoint.
  ///
  /// In en, this message translates to:
  /// **'Nearest Point'**
  String get nearestPoint;

  /// No description provided for @destinationPoint.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationPoint;

  /// No description provided for @activeSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed for ETA: {value} {unit}'**
  String activeSpeedLabel(String value, String unit);

  /// No description provided for @waypointsList.
  ///
  /// In en, this message translates to:
  /// **'Waypoints List'**
  String get waypointsList;

  /// No description provided for @placeholderDash.
  ///
  /// In en, this message translates to:
  /// **'---'**
  String get placeholderDash;

  /// No description provided for @minutesAbbrev.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesAbbrev;

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get etaLabel;

  /// No description provided for @notamsTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTAMs'**
  String get notamsTitle;

  /// No description provided for @notamDetails.
  ///
  /// In en, this message translates to:
  /// **'NOTAM Details'**
  String get notamDetails;

  /// No description provided for @notamStart.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get notamStart;

  /// No description provided for @notamEnd.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get notamEnd;

  /// No description provided for @notamFir.
  ///
  /// In en, this message translates to:
  /// **'FIR'**
  String get notamFir;

  /// No description provided for @notamLimits.
  ///
  /// In en, this message translates to:
  /// **'Vertical Limits'**
  String get notamLimits;

  /// No description provided for @hideNotam.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideNotam;

  /// No description provided for @flightRecords.
  ///
  /// In en, this message translates to:
  /// **'Flight Records'**
  String get flightRecords;

  /// No description provided for @flightRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flight Records'**
  String get flightRecordsTitle;

  /// No description provided for @flightName.
  ///
  /// In en, this message translates to:
  /// **'Flight Name'**
  String get flightName;

  /// No description provided for @pilotId.
  ///
  /// In en, this message translates to:
  /// **'Pilot ID'**
  String get pilotId;

  /// No description provided for @airplaneId.
  ///
  /// In en, this message translates to:
  /// **'Aircraft ID'**
  String get airplaneId;

  /// No description provided for @editFlight.
  ///
  /// In en, this message translates to:
  /// **'Edit Flight'**
  String get editFlight;

  /// No description provided for @shareGpx.
  ///
  /// In en, this message translates to:
  /// **'Share GPX'**
  String get shareGpx;

  /// No description provided for @downloadGpx.
  ///
  /// In en, this message translates to:
  /// **'Download GPX'**
  String get downloadGpx;

  /// No description provided for @flightRecordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No flight records found'**
  String get flightRecordsEmpty;

  /// No description provided for @flightDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get flightDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Failed to share GPX file'**
  String get shareError;

  /// No description provided for @shareSuccess.
  ///
  /// In en, this message translates to:
  /// **'GPX file shared successfully'**
  String get shareSuccess;

  /// No description provided for @maxAltitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max altitude'**
  String get maxAltitudeLabel;

  /// No description provided for @totalAscentLabel.
  ///
  /// In en, this message translates to:
  /// **'Total ascent'**
  String get totalAscentLabel;

  /// No description provided for @totalDescentLabel.
  ///
  /// In en, this message translates to:
  /// **'Total descent'**
  String get totalDescentLabel;

  /// No description provided for @avgAltitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Average altitude'**
  String get avgAltitudeLabel;

  /// No description provided for @maxSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Max speed'**
  String get maxSpeedLabel;

  /// No description provided for @avgSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get avgSpeedLabel;

  /// No description provided for @flownDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Flown distance'**
  String get flownDistanceLabel;

  /// No description provided for @maxDistanceTakeoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Max distance from takeoff'**
  String get maxDistanceTakeoffLabel;

  /// No description provided for @avgRpmLabel.
  ///
  /// In en, this message translates to:
  /// **'Average engine RPM'**
  String get avgRpmLabel;

  /// No description provided for @failedToAddNavigationPoint.
  ///
  /// In en, this message translates to:
  /// **'Failed to add navigation point'**
  String get failedToAddNavigationPoint;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @deleteFlightConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteFlightConfirmation(String name);

  /// No description provided for @noTelemetryRecords.
  ///
  /// In en, this message translates to:
  /// **'No telemetry records found for this flight.'**
  String get noTelemetryRecords;

  /// No description provided for @durationHoursSuffix.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get durationHoursSuffix;

  /// No description provided for @durationMinutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get durationMinutesSuffix;

  /// No description provided for @durationSecondsSuffix.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get durationSecondsSuffix;

  /// No description provided for @flightRecordsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load flight records'**
  String get flightRecordsLoadError;

  /// Number of takeoffs/flights
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 takeoff} other{{count} takeoffs}}'**
  String takeoffsCount(int count);

  /// No description provided for @flightNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get flightNotes;

  /// No description provided for @enterPilotPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN code for pilot \"{name}\":'**
  String enterPilotPin(String name);

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get pinCode;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN code!'**
  String get incorrectPin;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @selectPilotTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Pilot'**
  String get selectPilotTitle;

  /// No description provided for @deletePilotTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Pilot'**
  String get deletePilotTitle;

  /// No description provided for @deletePilotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete pilot \"{name}\"? This action is irreversible and will delete all their settings.'**
  String deletePilotConfirm(String name);

  /// No description provided for @deletePilotPinPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete Pilot'**
  String get deletePilotPinPrompt;

  /// No description provided for @pilotDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Pilot \"{name}\" has been deleted.'**
  String pilotDeletedSnackbar(String name);

  /// Error message for settings update failure
  ///
  /// In en, this message translates to:
  /// **'Failed to update settings: {error}'**
  String settingsUpdateFailed(String error);

  /// Dialog title for creating a new aircraft
  ///
  /// In en, this message translates to:
  /// **'Add Aircraft'**
  String get addAircraftTitle;

  /// No description provided for @aircraftNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Mark / Name'**
  String get aircraftNameLabel;

  /// No description provided for @aircraftNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter aircraft name!'**
  String get aircraftNameRequired;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @switchAircraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Aircraft'**
  String get switchAircraftTitle;

  /// No description provided for @addNewAircraft.
  ///
  /// In en, this message translates to:
  /// **'Add new aircraft'**
  String get addNewAircraft;

  /// No description provided for @savedAircraftsSection.
  ///
  /// In en, this message translates to:
  /// **'Saved Aircraft'**
  String get savedAircraftsSection;

  /// No description provided for @noAircraftsCreated.
  ///
  /// In en, this message translates to:
  /// **'No aircraft have been created yet.'**
  String get noAircraftsCreated;

  /// No description provided for @deselectAircraft.
  ///
  /// In en, this message translates to:
  /// **'Deselect Aircraft (Unknown)'**
  String get deselectAircraft;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get errorPrefix;

  /// No description provided for @aircraftSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Aircraft Settings'**
  String get aircraftSettingsTitle;

  /// No description provided for @initialFlightHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial Flight Hours'**
  String get initialFlightHoursLabel;

  /// No description provided for @hoursExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10.5'**
  String get hoursExampleHint;

  /// No description provided for @invalidFlightHours.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid flight hours!'**
  String get invalidFlightHours;

  /// No description provided for @initialHoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Initial flight hours saved.'**
  String get initialHoursSaved;

  /// No description provided for @initialFlightsLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial Flights'**
  String get initialFlightsLabel;

  /// No description provided for @flightsExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 24'**
  String get flightsExampleHint;

  /// No description provided for @invalidFlights.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid number of flights!'**
  String get invalidFlights;

  /// No description provided for @initialFlightsSaved.
  ///
  /// In en, this message translates to:
  /// **'Initial number of flights saved.'**
  String get initialFlightsSaved;

  /// No description provided for @deleteAircraftButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Aircraft'**
  String get deleteAircraftButton;

  /// No description provided for @deleteAircraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete aircraft \"{name}\"?'**
  String deleteAircraftConfirm(String name);

  /// No description provided for @aircraftDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Aircraft \"{name}\" has been deleted.'**
  String aircraftDeletedSnackbar(String name);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @addPilotTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Pilot'**
  String get addPilotTitle;

  /// No description provided for @pilotNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Pilot Name'**
  String get pilotNameLabel;

  /// No description provided for @pilotNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter pilot name!'**
  String get pilotNameRequired;

  /// No description provided for @optionalPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional PIN code (digits only)'**
  String get optionalPinLabel;

  /// No description provided for @switchPilotTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Pilot'**
  String get switchPilotTitle;

  /// No description provided for @addNewPilot.
  ///
  /// In en, this message translates to:
  /// **'Add new pilot'**
  String get addNewPilot;

  /// No description provided for @savedProfilesSection.
  ///
  /// In en, this message translates to:
  /// **'Saved Profiles'**
  String get savedProfilesSection;

  /// No description provided for @noPilotsCreated.
  ///
  /// In en, this message translates to:
  /// **'No pilots have been created yet.'**
  String get noPilotsCreated;

  /// No description provided for @protectedByPin.
  ///
  /// In en, this message translates to:
  /// **'Protected by PIN'**
  String get protectedByPin;

  /// No description provided for @noPin.
  ///
  /// In en, this message translates to:
  /// **'No PIN'**
  String get noPin;

  /// No description provided for @profileAndAircraftPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Aircraft'**
  String get profileAndAircraftPageTitle;

  /// No description provided for @pilotUppercase.
  ///
  /// In en, this message translates to:
  /// **'PILOT'**
  String get pilotUppercase;

  /// No description provided for @aircraftUppercase.
  ///
  /// In en, this message translates to:
  /// **'AIRCRAFT'**
  String get aircraftUppercase;

  /// No description provided for @accessSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Settings'**
  String get accessSettingsTitle;

  /// No description provided for @noPilotSelected.
  ///
  /// In en, this message translates to:
  /// **'No Pilot Selected'**
  String get noPilotSelected;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get notLoggedIn;

  /// No description provided for @localProfile.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localProfile;

  /// No description provided for @hoursFlown.
  ///
  /// In en, this message translates to:
  /// **'Hours flown: {hours}'**
  String hoursFlown(String hours);

  /// No description provided for @noActivePilot.
  ///
  /// In en, this message translates to:
  /// **'No Active Pilot'**
  String get noActivePilot;

  /// No description provided for @noActivePilotInstructions.
  ///
  /// In en, this message translates to:
  /// **'To view flight statistics and configure settings, select an active pilot from the list above.'**
  String get noActivePilotInstructions;

  /// No description provided for @pilotFlightStats.
  ///
  /// In en, this message translates to:
  /// **'Pilot Flight Statistics'**
  String get pilotFlightStats;

  /// No description provided for @aircraftFlightStats.
  ///
  /// In en, this message translates to:
  /// **'Aircraft Flight Statistics'**
  String get aircraftFlightStats;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get overall;

  /// No description provided for @statsCalcError.
  ///
  /// In en, this message translates to:
  /// **'Failed to calculate statistics'**
  String get statsCalcError;

  /// No description provided for @aircraftStatsCalcError.
  ///
  /// In en, this message translates to:
  /// **'Failed to calculate aircraft statistics'**
  String get aircraftStatsCalcError;

  /// No description provided for @pilotSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pilot Settings'**
  String get pilotSettingsTitle;

  /// No description provided for @pinSecurityLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN Code Security'**
  String get pinSecurityLabel;

  /// No description provided for @newPinHint.
  ///
  /// In en, this message translates to:
  /// **'New PIN (empty to disable)'**
  String get newPinHint;

  /// No description provided for @pilotPinUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Pilot PIN code has been updated.'**
  String get pilotPinUpdatedSnackbar;

  /// No description provided for @deselectPilot.
  ///
  /// In en, this message translates to:
  /// **'Deselect Pilot'**
  String get deselectPilot;

  /// No description provided for @hoursMinutesFormat.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String hoursMinutesFormat(int hours, int minutes);

  /// No description provided for @hoursMinutesFallback.
  ///
  /// In en, this message translates to:
  /// **'---h --m'**
  String get hoursMinutesFallback;

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings'**
  String get errorLoadingSettings;

  /// No description provided for @tempUnitCelsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get tempUnitCelsius;

  /// No description provided for @tempUnitKelvin.
  ///
  /// In en, this message translates to:
  /// **'Kelvin'**
  String get tempUnitKelvin;

  /// No description provided for @tempUnitFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get tempUnitFahrenheit;

  /// No description provided for @temperatureUnitSettings.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get temperatureUnitSettings;

  /// No description provided for @pressureUnitSettings.
  ///
  /// In en, this message translates to:
  /// **'Pressure Unit'**
  String get pressureUnitSettings;

  /// No description provided for @oilTemperature.
  ///
  /// In en, this message translates to:
  /// **'Oil Temperature'**
  String get oilTemperature;

  /// No description provided for @oilTemperatureShort.
  ///
  /// In en, this message translates to:
  /// **'Oil T.'**
  String get oilTemperatureShort;

  /// No description provided for @oilTemperatureSettings.
  ///
  /// In en, this message translates to:
  /// **'Oil Temperature'**
  String get oilTemperatureSettings;

  /// No description provided for @oilTempMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum Oil Temperature Range'**
  String get oilTempMaxRange;

  /// No description provided for @oilPressure.
  ///
  /// In en, this message translates to:
  /// **'Oil Pressure'**
  String get oilPressure;

  /// No description provided for @oilPressureShort.
  ///
  /// In en, this message translates to:
  /// **'Oil P.'**
  String get oilPressureShort;

  /// No description provided for @oilPressureSettings.
  ///
  /// In en, this message translates to:
  /// **'Oil Pressure'**
  String get oilPressureSettings;

  /// No description provided for @oilPressureMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum Oil Pressure Range'**
  String get oilPressureMaxRange;

  /// No description provided for @cylinderHeadTemperatureShort.
  ///
  /// In en, this message translates to:
  /// **'CHT'**
  String get cylinderHeadTemperatureShort;

  /// No description provided for @chtTemperature.
  ///
  /// In en, this message translates to:
  /// **'Cylinder Head Temperature (CHT)'**
  String get chtTemperature;

  /// No description provided for @chtTemperatureSettings.
  ///
  /// In en, this message translates to:
  /// **'Cylinder Head Temperature (CHT)'**
  String get chtTemperatureSettings;

  /// No description provided for @chtMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum Cylinder Head Temperature Range'**
  String get chtMaxRange;

  /// No description provided for @egtTemperature.
  ///
  /// In en, this message translates to:
  /// **'Exhaust Gas Temperature'**
  String get egtTemperature;

  /// No description provided for @egtTemperatureShort.
  ///
  /// In en, this message translates to:
  /// **'EGT'**
  String get egtTemperatureShort;

  /// No description provided for @egtTemperatureSettings.
  ///
  /// In en, this message translates to:
  /// **'Exhaust Gas Temperature'**
  String get egtTemperatureSettings;

  /// No description provided for @egtMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum Exhaust Gas Temperature Range'**
  String get egtMaxRange;

  /// No description provided for @fuelTankStatus.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuelTankStatus;

  /// No description provided for @fuelTankStatusShort.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuelTankStatusShort;

  /// No description provided for @fuelTankStatusSettings.
  ///
  /// In en, this message translates to:
  /// **'Fuel Tank'**
  String get fuelTankStatusSettings;

  /// No description provided for @engineRpm.
  ///
  /// In en, this message translates to:
  /// **'Engine RPM'**
  String get engineRpm;

  /// No description provided for @engineRpmShort.
  ///
  /// In en, this message translates to:
  /// **'RPM'**
  String get engineRpmShort;

  /// No description provided for @rpmThresholds.
  ///
  /// In en, this message translates to:
  /// **'Engine RPM Thresholds'**
  String get rpmThresholds;

  /// No description provided for @rpmMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum RPM slider range'**
  String get rpmMaxRange;

  /// No description provided for @vhfRadioTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio COM{instance}'**
  String vhfRadioTitle(int instance);

  /// No description provided for @vhfRadioActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get vhfRadioActive;

  /// No description provided for @vhfRadioStandby.
  ///
  /// In en, this message translates to:
  /// **'STANDBY'**
  String get vhfRadioStandby;

  /// No description provided for @vhfRadioNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get vhfRadioNoName;

  /// No description provided for @vhfRadioSwapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap frequencies'**
  String get vhfRadioSwapTooltip;

  /// No description provided for @vhfRadioNearbyFrequencies.
  ///
  /// In en, this message translates to:
  /// **'Nearby frequencies'**
  String get vhfRadioNearbyFrequencies;

  /// No description provided for @vhfRadioAdvancedManual.
  ///
  /// In en, this message translates to:
  /// **'Advanced / Manual'**
  String get vhfRadioAdvancedManual;

  /// No description provided for @vhfRadioNearbyAirports.
  ///
  /// In en, this message translates to:
  /// **'Nearby airports'**
  String get vhfRadioNearbyAirports;

  /// No description provided for @vhfRadioNoAirportsNearby.
  ///
  /// In en, this message translates to:
  /// **'No airports nearby'**
  String get vhfRadioNoAirportsNearby;

  /// No description provided for @vhfRadioFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get vhfRadioFavourites;

  /// No description provided for @vhfRadioManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get vhfRadioManage;

  /// No description provided for @vhfRadioNoFavoriteFrequencies.
  ///
  /// In en, this message translates to:
  /// **'No favourite frequencies'**
  String get vhfRadioNoFavoriteFrequencies;

  /// No description provided for @vhfRadioAirspaces.
  ///
  /// In en, this message translates to:
  /// **'Airspaces'**
  String get vhfRadioAirspaces;

  /// No description provided for @vhfRadioNoAirspacesNearby.
  ///
  /// In en, this message translates to:
  /// **'No airspaces nearby'**
  String get vhfRadioNoAirspacesNearby;

  /// No description provided for @vhfRadioInside.
  ///
  /// In en, this message translates to:
  /// **'inside'**
  String get vhfRadioInside;

  /// No description provided for @vhfRadioBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get vhfRadioBackToList;

  /// No description provided for @vhfRadioActiveFreqLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Frequency (MHz)'**
  String get vhfRadioActiveFreqLabel;

  /// No description provided for @vhfRadioActiveNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Active station name'**
  String get vhfRadioActiveNameLabel;

  /// No description provided for @vhfRadioApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get vhfRadioApply;

  /// No description provided for @vhfRadioStandbyFreqLabel.
  ///
  /// In en, this message translates to:
  /// **'Standby Frequency (MHz)'**
  String get vhfRadioStandbyFreqLabel;

  /// No description provided for @vhfRadioStandbyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Standby station name'**
  String get vhfRadioStandbyNameLabel;

  /// No description provided for @vhfRadioDualWatch.
  ///
  /// In en, this message translates to:
  /// **'Dual Watch'**
  String get vhfRadioDualWatch;

  /// No description provided for @vhfRadioHideAudio.
  ///
  /// In en, this message translates to:
  /// **'Hide audio settings'**
  String get vhfRadioHideAudio;

  /// No description provided for @vhfRadioShowAudio.
  ///
  /// In en, this message translates to:
  /// **'Show audio settings'**
  String get vhfRadioShowAudio;

  /// No description provided for @vhfRadioVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get vhfRadioVolume;

  /// No description provided for @vhfRadioSquelch.
  ///
  /// In en, this message translates to:
  /// **'Squelch'**
  String get vhfRadioSquelch;

  /// No description provided for @vhfRadioVox.
  ///
  /// In en, this message translates to:
  /// **'VOX Sensitivity'**
  String get vhfRadioVox;

  /// No description provided for @vhfRadioIntercom.
  ///
  /// In en, this message translates to:
  /// **'Intercom Volume'**
  String get vhfRadioIntercom;

  /// No description provided for @vhfRadioMicrophonesGain.
  ///
  /// In en, this message translates to:
  /// **'Microphones (Gain)'**
  String get vhfRadioMicrophonesGain;

  /// No description provided for @vhfRadioMicrophoneN.
  ///
  /// In en, this message translates to:
  /// **'Microphone {n}'**
  String vhfRadioMicrophoneN(int n);

  /// No description provided for @vhfRadioSaveChange.
  ///
  /// In en, this message translates to:
  /// **'Save change'**
  String get vhfRadioSaveChange;

  /// No description provided for @vhfRadioErrorActiveFreq.
  ///
  /// In en, this message translates to:
  /// **'Active frequency must be a valid aviation frequency (118.000 – 136.995 MHz).'**
  String get vhfRadioErrorActiveFreq;

  /// No description provided for @vhfRadioErrorStandbyFreq.
  ///
  /// In en, this message translates to:
  /// **'Standby frequency must be a valid aviation frequency (118.000 – 136.995 MHz).'**
  String get vhfRadioErrorStandbyFreq;

  /// No description provided for @vhfRadioErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'DroneCAN did not respond to {action} (timeout 1 s).'**
  String vhfRadioErrorTimeout(String action);

  /// No description provided for @vhfRadioErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to {action}: {error}'**
  String vhfRadioErrorGeneric(String action, String error);

  /// No description provided for @vhfRadioErrorFlip.
  ///
  /// In en, this message translates to:
  /// **'Flip failed: {error}'**
  String vhfRadioErrorFlip(String error);

  /// No description provided for @vhfRadioErrorInvalidFreq.
  ///
  /// In en, this message translates to:
  /// **'Frequency {freq} MHz is not valid.'**
  String vhfRadioErrorInvalidFreq(String freq);

  /// No description provided for @vhfRadioDronecanError.
  ///
  /// In en, this message translates to:
  /// **'DroneCAN request error (status: {status})'**
  String vhfRadioDronecanError(int status);

  /// No description provided for @vhfRadioFreqOutOfBand.
  ///
  /// In en, this message translates to:
  /// **'Frequency is outside aviation band (118.000 – 136.995 MHz).'**
  String get vhfRadioFreqOutOfBand;

  /// No description provided for @manageFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Favourites'**
  String get manageFavoritesTitle;

  /// No description provided for @manageFavoritesAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add new frequency'**
  String get manageFavoritesAddNew;

  /// No description provided for @manageFavoritesFreqLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency (MHz)'**
  String get manageFavoritesFreqLabel;

  /// No description provided for @manageFavoritesFreqHint.
  ///
  /// In en, this message translates to:
  /// **'118.000'**
  String get manageFavoritesFreqHint;

  /// No description provided for @manageFavoritesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Station name'**
  String get manageFavoritesNameLabel;

  /// No description provided for @manageFavoritesNameHint.
  ///
  /// In en, this message translates to:
  /// **'FIR Bratislava'**
  String get manageFavoritesNameHint;

  /// No description provided for @manageFavoritesAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get manageFavoritesAddToList;

  /// No description provided for @manageFavoritesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites list (drag to reorder)'**
  String get manageFavoritesListTitle;

  /// No description provided for @manageFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'The list is empty.'**
  String get manageFavoritesEmpty;

  /// No description provided for @manageFavoritesInvalidFreq.
  ///
  /// In en, this message translates to:
  /// **'Invalid aviation frequency (118.000 - 136.975 MHz).'**
  String get manageFavoritesInvalidFreq;

  /// No description provided for @manageFavoritesNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name must not be empty.'**
  String get manageFavoritesNameRequired;

  /// No description provided for @manageFavoritesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading favourites: {error}'**
  String manageFavoritesLoadError(String error);

  /// No description provided for @radioNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Radio is not connected'**
  String get radioNotConnected;

  /// No description provided for @radioSetAsActive.
  ///
  /// In en, this message translates to:
  /// **'Set as ACTIVE'**
  String get radioSetAsActive;

  /// No description provided for @radioSetAsStandby.
  ///
  /// In en, this message translates to:
  /// **'Set as STANDBY'**
  String get radioSetAsStandby;

  /// No description provided for @radioSetFreqError.
  ///
  /// In en, this message translates to:
  /// **'Error setting frequency: {error}'**
  String radioSetFreqError(String error);

  /// No description provided for @varioTitle.
  ///
  /// In en, this message translates to:
  /// **'Vario'**
  String get varioTitle;

  /// No description provided for @varioDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vario Details'**
  String get varioDetailsTitle;

  /// No description provided for @varioUnitMs.
  ///
  /// In en, this message translates to:
  /// **'m/s'**
  String get varioUnitMs;

  /// No description provided for @varioSourceBaro.
  ///
  /// In en, this message translates to:
  /// **'BARO (Pressure)'**
  String get varioSourceBaro;

  /// No description provided for @varioSourceGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get varioSourceGps;

  /// No description provided for @varioSourceNone.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get varioSourceNone;

  /// No description provided for @varioCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Vertical Speed'**
  String get varioCurrentValue;

  /// No description provided for @varioSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get varioSourceLabel;

  /// No description provided for @varioAirPressure.
  ///
  /// In en, this message translates to:
  /// **'Air Pressure'**
  String get varioAirPressure;

  /// No description provided for @varioQnhUsed.
  ///
  /// In en, this message translates to:
  /// **'QNH used'**
  String get varioQnhUsed;

  /// No description provided for @varioLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get varioLastUpdate;

  /// No description provided for @ognSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'OGN Configuration'**
  String get ognSettingsSection;

  /// No description provided for @sendLivePosition.
  ///
  /// In en, this message translates to:
  /// **'Send Live Position'**
  String get sendLivePosition;

  /// No description provided for @sendLivePositionDesc.
  ///
  /// In en, this message translates to:
  /// **'Send live tracking data to OGN servers'**
  String get sendLivePositionDesc;

  /// No description provided for @ognDeviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'OGN Device ID'**
  String get ognDeviceIdLabel;

  /// No description provided for @ognDeviceIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-char OGN ID'**
  String get ognDeviceIdHint;

  /// No description provided for @ognGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to get an OGN ID:'**
  String get ognGuideTitle;

  /// No description provided for @ognGuideStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Visit the free database ddb.glidernet.org.'**
  String get ognGuideStep1;

  /// No description provided for @ognGuideStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Register your aircraft (choose device type: OGN Tracker / Lyntia / School, or link to your FLARM/ICAO code).'**
  String get ognGuideStep2;

  /// No description provided for @ognGuideStep3.
  ///
  /// In en, this message translates to:
  /// **'3. The system will generate a unique 6-character device ID (e.g. ICA74F), which you enter in this app. From then on, other pilots and rescue services will see you.'**
  String get ognGuideStep3;

  /// No description provided for @trafficTitle.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get trafficTitle;

  /// No description provided for @aircraftCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Aircraft count'**
  String get aircraftCountLabel;

  /// No description provided for @callsignRegistrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Callsign / Registration'**
  String get callsignRegistrationLabel;

  /// No description provided for @absoluteAltitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Absolute Altitude (AMSL)'**
  String get absoluteAltitudeLabel;

  /// No description provided for @relativeAltitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Relative Altitude'**
  String get relativeAltitudeLabel;

  /// No description provided for @groundSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Ground Speed'**
  String get groundSpeedLabel;

  /// No description provided for @verticalSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Vertical Speed (Vario)'**
  String get verticalSpeedLabel;

  /// No description provided for @distanceFromUsLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance from our position'**
  String get distanceFromUsLabel;

  /// No description provided for @gliderType.
  ///
  /// In en, this message translates to:
  /// **'Glider'**
  String get gliderType;

  /// No description provided for @towPlaneType.
  ///
  /// In en, this message translates to:
  /// **'Tow Plane'**
  String get towPlaneType;

  /// No description provided for @helicopterType.
  ///
  /// In en, this message translates to:
  /// **'Helicopter'**
  String get helicopterType;

  /// No description provided for @skydiverType.
  ///
  /// In en, this message translates to:
  /// **'Skydiver'**
  String get skydiverType;

  /// No description provided for @dropPlaneType.
  ///
  /// In en, this message translates to:
  /// **'Drop Plane'**
  String get dropPlaneType;

  /// No description provided for @hangGliderType.
  ///
  /// In en, this message translates to:
  /// **'Hang Glider'**
  String get hangGliderType;

  /// No description provided for @paragliderType.
  ///
  /// In en, this message translates to:
  /// **'Paraglider'**
  String get paragliderType;

  /// No description provided for @poweredAircraftType.
  ///
  /// In en, this message translates to:
  /// **'Powered Aircraft'**
  String get poweredAircraftType;

  /// No description provided for @jetType.
  ///
  /// In en, this message translates to:
  /// **'Jet'**
  String get jetType;

  /// No description provided for @balloonType.
  ///
  /// In en, this message translates to:
  /// **'Balloon'**
  String get balloonType;

  /// No description provided for @airshipType.
  ///
  /// In en, this message translates to:
  /// **'Airship'**
  String get airshipType;

  /// No description provided for @uavType.
  ///
  /// In en, this message translates to:
  /// **'UAV / Drone'**
  String get uavType;

  /// No description provided for @ultralightType.
  ///
  /// In en, this message translates to:
  /// **'Ultralight'**
  String get ultralightType;

  /// No description provided for @gaType.
  ///
  /// In en, this message translates to:
  /// **'GA'**
  String get gaType;

  /// No description provided for @otherType.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherType;

  /// No description provided for @aircraftTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Aircraft Type'**
  String get aircraftTypeLabel;

  /// No description provided for @invalidOgnId.
  ///
  /// In en, this message translates to:
  /// **'Invalid OGN ID. Must be 6 characters.'**
  String get invalidOgnId;

  /// No description provided for @anonymousAircraft.
  ///
  /// In en, this message translates to:
  /// **'Anonymous aircraft'**
  String get anonymousAircraft;

  /// No description provided for @anonymousTrafficDesc.
  ///
  /// In en, this message translates to:
  /// **'This aircraft has disabled public tracking. Telemetry is visible for safety reasons, but identification is anonymous.'**
  String get anonymousTrafficDesc;

  /// No description provided for @lastSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get lastSeenLabel;

  /// No description provided for @trafficSettings.
  ///
  /// In en, this message translates to:
  /// **'Traffic Settings'**
  String get trafficSettings;

  /// No description provided for @enableHorizontalDistanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter by horizontal distance'**
  String get enableHorizontalDistanceFilter;

  /// No description provided for @trafficMaxHorizontalDistance.
  ///
  /// In en, this message translates to:
  /// **'Max. horizontal distance'**
  String get trafficMaxHorizontalDistance;

  /// No description provided for @enableVerticalDistanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter by vertical distance'**
  String get enableVerticalDistanceFilter;

  /// No description provided for @trafficMaxVerticalDistance.
  ///
  /// In en, this message translates to:
  /// **'Max. vertical distance'**
  String get trafficMaxVerticalDistance;

  /// No description provided for @trafficNoDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No traffic data available.'**
  String get trafficNoDataAvailable;

  /// No description provided for @trafficMaxHorizontalDistanceSummary.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String trafficMaxHorizontalDistanceSummary(String km);

  /// No description provided for @enableCas.
  ///
  /// In en, this message translates to:
  /// **'Collision Avoidance System (CAS)'**
  String get enableCas;

  /// No description provided for @casEnabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Predict 3D trajectories and warn about potential collisions'**
  String get casEnabledDesc;

  /// No description provided for @casLookaheadTime.
  ///
  /// In en, this message translates to:
  /// **'Lookahead Time'**
  String get casLookaheadTime;

  /// No description provided for @casHorizontalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Warning Distance'**
  String get casHorizontalThreshold;

  /// No description provided for @casVerticalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Vertical Warning Distance'**
  String get casVerticalThreshold;

  /// No description provided for @sameAltLabel.
  ///
  /// In en, this message translates to:
  /// **'SAME ALT'**
  String get sameAltLabel;

  /// No description provided for @aboveAltLabel.
  ///
  /// In en, this message translates to:
  /// **'+{alt} ABOVE'**
  String aboveAltLabel(String alt);

  /// No description provided for @belowAltLabel.
  ///
  /// In en, this message translates to:
  /// **'-{alt} BELOW'**
  String belowAltLabel(String alt);

  /// No description provided for @collisionWarningLabel.
  ///
  /// In en, this message translates to:
  /// **'COLLISION'**
  String get collisionWarningLabel;

  /// No description provided for @pureTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'PureTrack Account'**
  String get pureTrackTitle;

  /// No description provided for @pureTrackDescription.
  ///
  /// In en, this message translates to:
  /// **'Secondary live aircraft tracking data feed'**
  String get pureTrackDescription;

  /// No description provided for @pureTrackUsername.
  ///
  /// In en, this message translates to:
  /// **'Username / Email'**
  String get pureTrackUsername;

  /// No description provided for @pureTrackPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get pureTrackPassword;

  /// No description provided for @pureTrackLogin.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get pureTrackLogin;

  /// No description provided for @pureTrackLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get pureTrackLogout;

  /// No description provided for @pureTrackStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get pureTrackStatusConnected;

  /// No description provided for @pureTrackStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get pureTrackStatusDisconnected;

  /// No description provided for @pureTrackStatusAuthenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get pureTrackStatusAuthenticating;

  /// No description provided for @pureTrackStatusTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Session Expired (Re-authentication required)'**
  String get pureTrackStatusTokenInvalid;

  /// No description provided for @pureTrackStatusError.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get pureTrackStatusError;

  /// No description provided for @pureTrackSessionExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'PureTrack session expired. Tap to re-authenticate.'**
  String get pureTrackSessionExpiredBanner;

  /// No description provided for @trafficSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Data Source'**
  String get trafficSourceLabel;

  /// No description provided for @trafficSourceOgn.
  ///
  /// In en, this message translates to:
  /// **'OGN'**
  String get trafficSourceOgn;

  /// No description provided for @trafficSourcePureTrack.
  ///
  /// In en, this message translates to:
  /// **'PureTrack'**
  String get trafficSourcePureTrack;

  /// No description provided for @trafficSourceGdl90.
  ///
  /// In en, this message translates to:
  /// **'GDL90'**
  String get trafficSourceGdl90;

  /// No description provided for @gdl90SettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'GDL90 / SafeSky Receiver'**
  String get gdl90SettingsTitle;

  /// No description provided for @gdl90EnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable GDL90 Receiver'**
  String get gdl90EnableTitle;

  /// No description provided for @gdl90EnableDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive local GDL90 traffic over UDP (SafeSky, Stratux, SkyEcho 2, etc.)'**
  String get gdl90EnableDesc;

  /// No description provided for @gdl90BindIpTitle.
  ///
  /// In en, this message translates to:
  /// **'Bind IP Address'**
  String get gdl90BindIpTitle;

  /// No description provided for @gdl90PortTitle.
  ///
  /// In en, this message translates to:
  /// **'UDP Port'**
  String get gdl90PortTitle;

  /// No description provided for @gdl90TargetExpiryTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Expiry Timeout'**
  String get gdl90TargetExpiryTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sk':
      return AppLocalizationsSk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
