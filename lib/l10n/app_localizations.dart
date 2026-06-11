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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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
