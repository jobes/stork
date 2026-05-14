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

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;
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
