// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get settingsDisplayPreferences => 'Vzhľad a jazyk';

  @override
  String get settingsTheme => 'Téma';

  @override
  String get settingsLanguage => 'Jazyk';

  @override
  String get settingsFollowSystem => 'Podľa systému';

  @override
  String get settingsLightTheme => 'Svetlá';

  @override
  String get settingsDarkTheme => 'Tmavá';

  @override
  String get settingsEnglish => 'Angličtina';

  @override
  String get settingsSlovak => 'Slovenčina';

  @override
  String get settingsPreferenceSaveFailed => 'Predvoľbu sa nepodarilo uložiť.';

  @override
  String get appTitle => 'Stork nav';

  @override
  String get mapLoadingError => 'Chyba pri načítavaní štýlu mapy';

  @override
  String get menu => 'Menu';

  @override
  String get offlineMaps => 'Offline mapy';

  @override
  String get aircraft => 'Lietadlo';

  @override
  String get pilot => 'Pilot';

  @override
  String get unknownAircraft => 'Neznáme lietadlo';

  @override
  String get anonymousPilot => 'Anonymný pilot';

  @override
  String unknownPilotWithId(String id) {
    return 'Neznámy pilot ($id)';
  }

  @override
  String unknownAircraftWithId(String id) {
    return 'Neznáme lietadlo ($id)';
  }

  @override
  String get filterAllPilots => 'Všetci piloti';

  @override
  String get filterAllAircraft => 'Všetky lietadlá';

  @override
  String get editSettings => 'Nastavenia';

  @override
  String get pilotTotalHours => 'Nálet (pilot)';

  @override
  String get aircraftTotalHours => 'Nálet (lietadlo)';

  @override
  String get airportDetails => 'Detaili letiska';

  @override
  String get downloadMaps => 'Stiahnuť mapy';

  @override
  String get updateMaps => 'Aktualizovať mapy';

  @override
  String lastUpdate(String date) {
    return 'Posledná aktualizácia: $date';
  }

  @override
  String get addArea => 'Pridať oblasť';

  @override
  String get deleteArea => 'Vymazať oblasť';

  @override
  String get deleteAll => 'Vymazať všetko';

  @override
  String areaCount(int count) {
    return 'Počet oblastí na stiahnutie: $count';
  }

  @override
  String get noAreasSelected => 'Žiadne oblasti na stiahnutie';

  @override
  String get selectOfflineArea => 'Vybrať oblasť';

  @override
  String get drawOfflineAreaHint =>
      'Ťahom po mape vyznačte oblasť na stiahnutie.';

  @override
  String get offlineMapsReady => 'Pripravené na použitie offline';

  @override
  String get offlineMapsDownloadRequired => 'Vybrané oblasti treba stiahnuť';

  @override
  String get deleteConfirmationTitle => 'Vymazať všetko';

  @override
  String get deleteConfirmationContent =>
      'Naozaj chcete vymazať všetky oblasti a stiahnuté mapy? Táto akcia je nevratná a odstráni aj všetky dáta z pamäte.';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get delete => 'Vymazať';

  @override
  String tileProgress(int downloaded, int total, String size) {
    return '$downloaded / $total dlaždíc ($size)';
  }

  @override
  String get downloadingMetadata => 'Sťahovanie metadát štátov...';

  @override
  String metadataProgress(int current, int total) {
    return '$current / $total súborov';
  }

  @override
  String lastUpdateDetail(
    String size,
    String world,
    String openaip,
    String terrain,
    String metadata,
  ) {
    return '($size - Svet: $world, openAIP: $openaip, Terén: $terrain, Metadáta: $metadata)';
  }

  @override
  String get cancelDownload => 'Zrušiť sťahovanie';

  @override
  String get downloadError =>
      'Chyba pri sťahovaní máp. Skontrolujte prosím internetové pripojenie.';

  @override
  String get settings => 'Nastavenia';

  @override
  String get mapFontSize => 'Veľkosť písma na mape';

  @override
  String get mapDefaultZoom => 'Predvolený zoom mapy';

  @override
  String get mapOverviewZoom => 'Zoom prehľadu mapy';

  @override
  String get mapFollowZoom => 'Zoom sledovania mapy';

  @override
  String get mapFollowPitch => 'Náklon mapy pri sledovaní (°)';

  @override
  String get mapFollowPitchHint =>
      'Väčší náklon zlepší výhľad dopredu, ale vyžaduje vyšší výkon a mapa môže sekať.';

  @override
  String get resetSettings => 'Resetovať nastavenia';

  @override
  String get gpsEnable => 'Zapnúť GPS';

  @override
  String get gpsWaiting => 'Čakám na GPS...';

  @override
  String get gpsFollow => 'Sledovať polohu';

  @override
  String get gpsStopFollow => 'Prestať sledovať polohu';

  @override
  String get cannelloniGateway => 'Cannelloni brána';

  @override
  String get autoSelectDevice => 'Automaticky vybrať zariadenie';

  @override
  String get selectedDevice => 'Vybrané zariadenie';

  @override
  String get noneSelected => 'Žiadne';

  @override
  String get flightSettings => 'Nastavenia letu';

  @override
  String get inactiveThreshold => 'Neaktívne (Pod minimom)';

  @override
  String get minErrorThreshold => 'Kriticky nízka hodnota';

  @override
  String get minWarningThreshold => 'Nebezpečne nízka hodnota';

  @override
  String get maxWarningThreshold => 'Nebezpečne vysoká hodnota';

  @override
  String get maxErrorThreshold => 'Kriticky vysoká hodnota';

  @override
  String get editThresholdValues => 'Presné nastavenie';

  @override
  String get thresholdValueInvalid => 'Zadajte platné číslo.';

  @override
  String get thresholdValueOutOfRange => 'Hodnota je mimo rozsahu posuvníka.';

  @override
  String get thresholdValuesOrder =>
      'Zadajte hodnotu aspoň takú vysokú ako predchádzajúci prah.';

  @override
  String get mapSettings => 'Nastavenia mapy';

  @override
  String get operationalThreshold => 'Prevádzková hodnota (V norme)';

  @override
  String get flightSpeed => 'Rýchlosť letu';

  @override
  String get flightSpeedMaxRange => 'Maximálny rozsah slidera';

  @override
  String get moveWidgets => 'Presúvať widgety';

  @override
  String get resetWidgetLayout => 'Obnoviť polohu widgetov';

  @override
  String get speedUnitKmH => 'km/h';

  @override
  String gsSpeedLabel(String value, String unit) {
    return 'GS $value $unit';
  }

  @override
  String get gpsOnly => 'IBA GPS';

  @override
  String get noGps => 'BEZ GPS';

  @override
  String get speedUnitSettings => 'Jednotka rýchlosti';

  @override
  String get speedUnitMs => 'm/s';

  @override
  String get speedUnitMph => 'mph';

  @override
  String get speedUnitKnots => 'uzly';

  @override
  String get speedUnitKnotsAbbreviation => 'kt';

  @override
  String get courseLineSettings => 'Smerová čiara letu';

  @override
  String get courseLineSegmentsCount => 'Počet segmentov';

  @override
  String get courseLineSegmentDuration => 'Dĺžka segmentu (sekundy)';

  @override
  String get durationSuffix => ' s';

  @override
  String get speedDetailsTitle => 'Detaily rýchlosti';

  @override
  String get iasAvailable => 'IAS dostupná';

  @override
  String get gpsSpeedAvailable => 'GPS rýchlosť dostupná';

  @override
  String get gpsAccuracy => 'Presnosť GPS';

  @override
  String get horizontalAccuracy => 'Horizontálna presnosť';

  @override
  String get verticalAccuracy => 'Vertikálna presnosť';

  @override
  String get satelliteCount => 'Počet satelitov';

  @override
  String get gpsAltitude => 'GPS nadmorská výška';

  @override
  String get valueYes => 'Áno';

  @override
  String get valueNo => 'Nie';

  @override
  String get valueNotAvailable => 'Nedostupné';

  @override
  String get iasShortTitle => 'IAS';

  @override
  String get gsShortTitle => 'GS';

  @override
  String get indicatedAirSpeedShort => 'Indikovaná vzdušná rýchlosť (IAS)';

  @override
  String get groundSpeedShort => 'Rýchlosť voči zemi (GS)';

  @override
  String get speedSource => 'Zdroj rýchlosti';

  @override
  String get activeThreshold => 'Aktívny limit rýchlosti';

  @override
  String get gpsSourceInternal => 'Interné GPS (Telefón)';

  @override
  String get gpsSourceDroneCan => 'DroneCAN (Prijímač)';

  @override
  String get gpsNotificationTitle => 'GPS Služba Stork';

  @override
  String get gpsNotificationText => 'Sledovanie polohy na pozadí';

  @override
  String get altitude => 'Výška';

  @override
  String get altitudeSourceBaro => 'BARO (DroneCAN)';

  @override
  String get altitudeSourceGpsReceiver => 'GPS (DroneCAN)';

  @override
  String get altitudeSourceGpsPhone => 'GPS (Mobil)';

  @override
  String get altitudeSourceNone => 'Nedostupné';

  @override
  String get altitudeUnitMeters => 'm';

  @override
  String get altitudeUnitSettings => 'Jednotka výšky';

  @override
  String get altitudeUnitMetersMsl => 'm n.m.';

  @override
  String get altitudeUnitFeetMsl => 'ft n.m.';

  @override
  String get altitudeUnitMetersGnd => 'm GND';

  @override
  String get altitudeUnitFeetGnd => 'ft GND';

  @override
  String get heightUnitSettings => 'Jednotka výšky nad zemou (GND)';

  @override
  String get altitudeDetailsTitle => 'Detaily výšky';

  @override
  String get altitudeSource => 'Zdroj výšky';

  @override
  String get autoQnhLabel => 'Automatický výpočet QNH';

  @override
  String get currentQnhLabel => 'Aktuálne QNH';

  @override
  String get autoQnhHelpTooltip =>
      'QNH sa automaticky nastaví pri štarte na zemi a počas letu sa bude upravovať z GPS, nakoľko atmosférický tlak sa mení vplyvom počasia.';

  @override
  String get qnhSetting => 'Nastavenie QNH';

  @override
  String get invalidQnhNumber => 'Neplatné číslo';

  @override
  String qnhOutOfRange(String min, String max) {
    return 'Mimo rozsah ($min - $max)';
  }

  @override
  String get terrainElevation => 'Nadmorská výška terénu';

  @override
  String get terrainUnderPosition => 'Terén pod polohou';

  @override
  String get airport => 'Letisko';

  @override
  String get tune => 'NALADIŤ';

  @override
  String get mainRunway => 'Hlavná dráha';

  @override
  String get airportLoadingDetails => 'Načítavam detaily...';

  @override
  String get airportFailedToLoad => 'Nepodarilo sa načítať detaily letiska.';

  @override
  String airportNameLabel(String name) {
    return 'Názov: $name';
  }

  @override
  String airportIcao(String icao) {
    return 'ICAO: $icao';
  }

  @override
  String get airportElevation => 'Nadmorská výška';

  @override
  String get airportFrequencies => 'Frekvencie';

  @override
  String get airportRunways => 'Dráhy';

  @override
  String get airportPpr => 'PPR';

  @override
  String get airportPrivate => 'Súkromné';

  @override
  String get airportSkydiveActivity => 'Parašutizmus';

  @override
  String get airportWinchOnly => 'Navijak';

  @override
  String airportRunwayDimension(String length, String width, String unit) {
    return '${length}x$width $unit';
  }

  @override
  String get airportSurface => 'Povrch';

  @override
  String get airportTypeLabel => 'Typ';

  @override
  String get airportViewOnOpenAip => 'Zobraziť na openAIP';

  @override
  String get airportTypeAirport => 'Letisko';

  @override
  String get airportTypeGliderSite => 'Bezmotorové letisko';

  @override
  String get airportTypeAirfieldCivil => 'Civilné letisko';

  @override
  String get airportTypeInternationalAirport => 'Medzinárodné letisko';

  @override
  String get airportTypeHeliportMilitary => 'Vojenský heliport';

  @override
  String get airportTypeMilitaryAerodrome => 'Vojenské letisko';

  @override
  String get airportTypeUltralightFlyingSite => 'Plocha pre ultralighty';

  @override
  String get airportTypeHeliportCivil => 'Civilný heliport';

  @override
  String get airportTypeAerodromeClosed => 'Zatvorené letisko';

  @override
  String get airportTypeIfr => 'IFR letisko';

  @override
  String get airportTypeAirfieldWater => 'Vodné letisko';

  @override
  String get airportTypeLandingStrip => 'Pristávacia dráha';

  @override
  String get airportTypeAgriculturalLandingStrip => 'Poľnohospodárska plocha';

  @override
  String get airportTypeAltiport => 'Altiport';

  @override
  String airportTypeUnknown(String type) {
    return 'Neznámy typ ($type)';
  }

  @override
  String get frequencyTypeApproach => 'Priblíženie';

  @override
  String get frequencyTypeApron => 'Apron';

  @override
  String get frequencyTypeArrival => 'Prílet';

  @override
  String get frequencyTypeCenter => 'Center';

  @override
  String get frequencyTypeCtaf => 'CTAF';

  @override
  String get frequencyTypeDelivery => 'Delivery';

  @override
  String get frequencyTypeDeparture => 'Odlet';

  @override
  String get frequencyTypeFis => 'FIS';

  @override
  String get frequencyTypeGliding => 'Plachtenie';

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
  String get frequencyTypeTower => 'Veža';

  @override
  String get frequencyTypeAtis => 'ATIS';

  @override
  String get frequencyTypeRadio => 'Rádio';

  @override
  String get frequencyTypeOther => 'Iné';

  @override
  String get frequencyTypeAirmet => 'AIRMET';

  @override
  String get frequencyTypeAwos => 'AWOS';

  @override
  String get frequencyTypeLights => 'Svetlá';

  @override
  String get frequencyTypeVolmet => 'VOLMET';

  @override
  String frequencyTypeUnknown(String type) {
    return 'Neznáma ($type)';
  }

  @override
  String get surfaceAsphalt => 'Asfalt';

  @override
  String get surfaceConcrete => 'Betón';

  @override
  String get surfaceGrass => 'Tráva';

  @override
  String get surfaceSand => 'Piesok';

  @override
  String get surfaceWater => 'Voda';

  @override
  String get surfaceBituminousTar => 'Bitúmen';

  @override
  String get surfaceBrick => 'Tehla';

  @override
  String get surfaceMacadam => 'Makadam';

  @override
  String get surfaceStone => 'Kameň';

  @override
  String get surfaceCoral => 'Korál';

  @override
  String get surfaceClay => 'Hlina';

  @override
  String get surfaceLaterite => 'Laterit';

  @override
  String get surfaceGravel => 'Štrk';

  @override
  String get surfaceEarth => 'Hlina/Zem';

  @override
  String get surfaceIce => 'Ľad';

  @override
  String get surfaceSnow => 'Sneh';

  @override
  String get surfaceProtectiveLaminate => 'Ochranný laminát';

  @override
  String get surfaceMetal => 'Kov';

  @override
  String get surfaceLandingMat => 'Pristávacia rohož';

  @override
  String get surfaceUnknown => 'Neznámy';

  @override
  String get surfaceWood => 'Drevo';

  @override
  String surfaceUnknownType(String type) {
    return 'Neznámy ($type)';
  }

  @override
  String get airspace => 'Letecký priestor';

  @override
  String get airspacesTitle => 'Letecké priestory';

  @override
  String get airspaceClass => 'Trieda';

  @override
  String get airspaceType => 'Typ';

  @override
  String get airspaceLimits => 'Limity';

  @override
  String get airspaceLimitLower => 'Dolná hranica';

  @override
  String get airspaceLimitUpper => 'Horná hranica';

  @override
  String get airspaceActivity => 'Aktivita';

  @override
  String get airspaceFrequencies => 'Frekvencie';

  @override
  String get airspaceViewOnOpenAip => 'Zobraziť na openAIP';

  @override
  String get airspacesLoadingDetails =>
      'Načítavam detaily leteckých priestorov...';

  @override
  String get airspacesFailedToLoad =>
      'Nepodarilo sa načítať detaily leteckých priestorov.';

  @override
  String get airspacesAtLocation => 'Letecké priestory na tomto mieste';

  @override
  String get airspaceFlagByNotam => 'CEZ NOTAM';

  @override
  String get airspaceFlagOnRequest => 'NA VYŽIADANIE';

  @override
  String get airspaceFlagOnDemand => 'NA POŽIADANIE';

  @override
  String get airspaceClassA => 'Trieda A';

  @override
  String get airspaceClassB => 'Trieda B';

  @override
  String get airspaceClassC => 'Trieda C';

  @override
  String get airspaceClassD => 'Trieda D';

  @override
  String get airspaceClassE => 'Trieda E';

  @override
  String get airspaceClassF => 'Trieda F';

  @override
  String get airspaceClassG => 'Trieda G';

  @override
  String get airspaceClassUnclassified => 'Nezaradené / SUA';

  @override
  String get airspaceClassUnknown => 'Neznáma trieda';

  @override
  String get airspaceTypeOther => 'Iný';

  @override
  String get airspaceTypeRestricted => 'Obmedzený priestor (Restricted)';

  @override
  String get airspaceTypeDanger => 'Nebezpečný priestor (Danger)';

  @override
  String get airspaceTypeProhibited => 'Zakázaný priestor (Prohibited)';

  @override
  String get airspaceTypeCtr => 'Riadený okrsok (CTR)';

  @override
  String get airspaceTypeTmz => 'Zóna s povinným odpovedačom (TMZ)';

  @override
  String get airspaceTypeRmz => 'Zóna s povinným rádiovým spojením (RMZ)';

  @override
  String get airspaceTypeTma => 'Koncová riadená oblasť (TMA)';

  @override
  String get airspaceTypeTra => 'Dočasne vyhradený priestor (TRA)';

  @override
  String get airspaceTypeTsa => 'Dočasne vyčlenený priestor (TSA)';

  @override
  String get airspaceTypeFir => 'Letová informačná oblasť (FIR)';

  @override
  String get airspaceTypeUir => 'Horná informačná oblasť (UIR)';

  @override
  String get airspaceTypeAdiz => 'Identifikačná zóna PVO (ADIZ)';

  @override
  String get airspaceTypeAtz => 'Letisková prevádzková zóna (ATZ)';

  @override
  String get airspaceTypeMatz => 'Vojenská letisková prevádzková zóna (MATZ)';

  @override
  String get airspaceTypeAirway => 'Letová cesta';

  @override
  String get airspaceTypeMtr => 'Vojenská výcviková trať (MTR)';

  @override
  String get airspaceTypeAlert => 'Výstražný priestor (Alert)';

  @override
  String get airspaceTypeWarning => 'Upozorňujúci priestor (Warning)';

  @override
  String get airspaceTypeProtected => 'Chránený priestor';

  @override
  String get airspaceTypeHtz => 'Vrtuľníková prevádzková zóna (HTZ)';

  @override
  String get airspaceTypeGliding => 'Plachtársky sektor';

  @override
  String get airspaceTypeTrp => 'Transpondérový sektor (TRP)';

  @override
  String get airspaceTypeTiz => 'Zóna s informáciami o letovej prevádzke (TIZ)';

  @override
  String get airspaceTypeTia =>
      'Oblasť s informáciami o letovej prevádzke (TIA)';

  @override
  String get airspaceTypeMta => 'Vojenský výcvikový priestor (MTA)';

  @override
  String get airspaceTypeCta => 'Riadená oblasť (CTA)';

  @override
  String get airspaceTypeAcc => 'Sektor ACC';

  @override
  String get airspaceTypeSport => 'Letecká športová/rekreačná aktivita';

  @override
  String get airspaceTypeLowOverflight => 'Obmedzenie letu v nízkych výškach';

  @override
  String get airspaceTypeMrt => 'Vojenská trať (MRT)';

  @override
  String get airspaceTypeTfr => 'Napájacia trať TSA/TRA (TFR)';

  @override
  String get airspaceTypeVfr => 'Sektor VFR';

  @override
  String get airspaceTypeFis => 'Sektor FIS';

  @override
  String get airspaceTypeLta => 'Dolná riadená oblasť (LTA)';

  @override
  String get airspaceTypeUta => 'Horná riadená oblasť (UTA)';

  @override
  String get airspaceTypeMctr => 'Vojenský riadený okrsok (MCTR)';

  @override
  String get airspaceTypeUnknown => 'Neznámy';

  @override
  String get airspaceActivityNone => 'Žiadna';

  @override
  String get airspaceActivityParachuting => 'Parašutizmus';

  @override
  String get airspaceActivityAerobatics => 'Akrobacia';

  @override
  String get airspaceActivityAeroclub => 'Aeroklub / Letecké práce';

  @override
  String get airspaceActivityUlm => 'Plocha pre ULM';

  @override
  String get airspaceActivityGliding => 'Bezmotorové lietanie';

  @override
  String get airspaceActivityUnknown => 'Neznáma';

  @override
  String get airspaceActivityStatusActive => 'Aktívny';

  @override
  String get airspaceActivityStatusInactive => 'Neaktívny';

  @override
  String get airspaceActivityStatusUnknown => 'Aktivita neznáma';

  @override
  String get airspaceActivityTimeWindow => 'Platnosť';

  @override
  String get flightTime => 'Čas letu';

  @override
  String get flightDetailsTitle => 'Detaily letu';

  @override
  String get flightDuration => 'Trvanie letu';

  @override
  String get flightDistance => 'Dĺžka letu';

  @override
  String get flightStartTime => 'Čas začiatku letu';

  @override
  String get navigation => 'Navigácia';

  @override
  String get navigateToPoint => 'Naviguj na bod';

  @override
  String get addPointToNavigation => 'Pridať bod do navigácie';

  @override
  String get averageSpeed => 'Predpokladaná rýchlosť letu';

  @override
  String get groundSpeed => 'Rýchlosť voči zemi';

  @override
  String get navigationRequiresLocation => 'Najprv potrebujem aktuálnu polohu.';

  @override
  String get noNavigationPoints =>
      'Žiadne body navigácie. Pridajte body kliknutím na mapu.';

  @override
  String get leg => 'Úsek';

  @override
  String get total => 'Celkovo';

  @override
  String get navigationActive => 'Aktívna';

  @override
  String get navigationStopped => 'Zastavená';

  @override
  String get startNavigation => 'Spustiť';

  @override
  String get stopNavigation => 'Zastaviť';

  @override
  String get clearNavigation => 'Zrušiť navigáciu';

  @override
  String get clearNavigationConfirm =>
      'Naozaj chcete zrušiť navigáciu a vymazať celú trasu?';

  @override
  String get navigationDetailsTitle => 'Detaily navigácie';

  @override
  String get weatherInWindy => 'Počasie vo Windy';

  @override
  String get nearestPoint => 'Najbližší bod';

  @override
  String get destinationPoint => 'Cieľ';

  @override
  String activeSpeedLabel(String value, String unit) {
    return 'Rýchlosť pre ETA: $value $unit';
  }

  @override
  String get waypointsList => 'Zoznam bodov';

  @override
  String get placeholderDash => '---';

  @override
  String get minutesAbbrev => 'min';

  @override
  String get etaLabel => 'ETA';

  @override
  String get flightRecords => 'Záznamy letov';

  @override
  String get flightRecordsTitle => 'Záznamy letov';

  @override
  String get flightName => 'Názov letu';

  @override
  String get pilotId => 'ID pilota';

  @override
  String get airplaneId => 'ID lietadla';

  @override
  String get editFlight => 'Upraviť let';

  @override
  String get shareGpx => 'Zdieľať GPX';

  @override
  String get downloadGpx => 'Stiahnuť GPX';

  @override
  String get flightRecordsEmpty => 'Nenašli sa žiadne záznamy letov';

  @override
  String get flightDate => 'Dátum';

  @override
  String get startTime => 'Čas štartu';

  @override
  String get endTime => 'Čas pristátia';

  @override
  String get save => 'Uložiť';

  @override
  String get shareError => 'Nepodarilo sa zdieľať GPX súbor';

  @override
  String get shareSuccess => 'GPX súbor bol úspešne zdieľaný';

  @override
  String get maxAltitudeLabel => 'Maximálna dosiahnutá výška';

  @override
  String get totalAscentLabel => 'Nastúpaná výška';

  @override
  String get totalDescentLabel => 'Naklesaná výška';

  @override
  String get avgAltitudeLabel => 'Priemerná výška';

  @override
  String get maxSpeedLabel => 'Maximálna rýchlosť';

  @override
  String get avgSpeedLabel => 'Priemerná rýchlosť';

  @override
  String get flownDistanceLabel => 'Nalietaná vzdialenosť';

  @override
  String get maxDistanceTakeoffLabel => 'Najvzdialenejší bod od vzletu';

  @override
  String get avgRpmLabel => 'Priemerné RPM motora';

  @override
  String get failedToAddNavigationPoint => 'Nepodarilo sa pridať navigačný bod';

  @override
  String get pleaseEnterName => 'Prosím, zadajte názov';

  @override
  String get addToFavorites => 'Pridať do obľúbených';

  @override
  String get favoritesTitle => 'Obľúbené';

  @override
  String get favoritePointTitle => 'Nový obľúbený bod';

  @override
  String get favoriteIconLabel => 'Ikona';

  @override
  String get favoriteNameLabel => 'Názov';

  @override
  String get favoriteNameHint => 'napr. Domáce letisko';

  @override
  String get favoriteDescriptionLabel => 'Popis';

  @override
  String get favoriteDescriptionHint => 'Pridajte popis…';

  @override
  String get favoriteFormattingHelp =>
      'Označte text a použite panel na **tučné** a *kurzívu*, alebo zadajte značky ručne.';

  @override
  String get favoriteFormatBold => 'Tučné';

  @override
  String get favoriteFormatItalic => 'Kurzíva';

  @override
  String get favoriteSaved => 'Obľúbený bod bol uložený';

  @override
  String get favoriteFailedToSave => 'Nepodarilo sa uložiť obľúbený bod';

  @override
  String get favoriteDetailsTitle => 'Obľúbený bod';

  @override
  String get favoriteDescriptionEmpty => 'Bez popisu';

  @override
  String get favoriteEditTitle => 'Upraviť obľúbený bod';

  @override
  String get favoriteFailedToLoad => 'Nepodarilo sa načítať obľúbené body';

  @override
  String get favoritesEmptyTitle => 'Zatiaľ žiadne obľúbené body';

  @override
  String get favoritesEmptyHint => 'Tu môžete spravovať body uložené z mapy.';

  @override
  String get showOnMap => 'Zobraziť na mape';

  @override
  String get favoriteAddedToNavigation => 'Pridané do navigácie';

  @override
  String favoriteDeleteConfirm(String name) {
    return 'Odstrániť obľúbený bod \"$name\"?';
  }

  @override
  String get edit => 'Upraviť';

  @override
  String deleteFlightConfirmation(String name) {
    return 'Naozaj chcete vymazať \"$name\"?';
  }

  @override
  String get noTelemetryRecords =>
      'Pre tento let sa nenašli žiadne záznamy telemetrie.';

  @override
  String get durationHoursSuffix => 'h';

  @override
  String get durationMinutesSuffix => 'm';

  @override
  String get durationSecondsSuffix => 's';

  @override
  String get flightRecordsLoadError => 'Nepodarilo sa načítať záznamy letov';

  @override
  String get dronecanInstruments => 'DroneCAN prístroje';

  @override
  String get dronecanRefresh => 'Obnoviť informácie o uzloch';

  @override
  String get dronecanRefreshNoNodes =>
      'Nie je čo obnoviť, na zbernici nie je žiadny DroneCAN uzol';

  @override
  String dronecanRefreshSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uzlov',
      few: '$count uzly',
      one: '1 uzol',
    );
    return 'Informácie o uzloch obnovené pre $_temp0';
  }

  @override
  String dronecanRefreshPartial(int answered, int requested) {
    return 'Odpovedalo len $answered z $requested uzlov';
  }

  @override
  String get dronecanRefreshFailed =>
      'Nepodarilo sa obnoviť informácie o uzloch';

  @override
  String get dronecanInstrumentsEmpty =>
      'Nenašli sa žiadne DroneCAN zariadenia';

  @override
  String get dronecanInstrumentsDisconnected =>
      'Nie ste pripojení k DroneCAN bráne';

  @override
  String get dronecanInstrumentsLoadError =>
      'Nepodarilo sa načítať DroneCAN zariadenia';

  @override
  String get dronecanNodeId => 'ID uzla';

  @override
  String get dronecanNodeName => 'Názov';

  @override
  String get dronecanUniqueId => 'Jedinečné ID';

  @override
  String get dronecanHealth => 'Stav';

  @override
  String get dronecanMode => 'Režim';

  @override
  String get dronecanUptime => 'Doba behu';

  @override
  String get dronecanLastSeen => 'Naposledy videný';

  @override
  String get dronecanHealthOk => 'OK';

  @override
  String get dronecanHealthWarning => 'Varovanie';

  @override
  String get dronecanHealthError => 'Chyba';

  @override
  String get dronecanHealthCritical => 'Kritický';

  @override
  String get dronecanModeOperational => 'Prevádzkový';

  @override
  String get dronecanModeInitialization => 'Inicializácia';

  @override
  String get dronecanModeMaintenance => 'Údržba';

  @override
  String get dronecanModeSoftwareUpdate => 'Aktualizácia softvéru';

  @override
  String get dronecanModeOffline => 'Offline';

  @override
  String get dronecanNodeDetailsTitle => 'DroneCAN uzol';

  @override
  String get dronecanSoftwareVersion => 'Verzia softvéru';

  @override
  String get dronecanVcsCommit => 'VCS commit';

  @override
  String get dronecanImageCrc => 'CRC obrazu';

  @override
  String get dronecanHardwareVersion => 'Verzia hardvéru';

  @override
  String get dronecanCertificateOfAuthenticity => 'Certifikát autenticity';

  @override
  String get dronecanDetailsUnavailable =>
      'Podrobnosti zatiaľ nie sú dostupné.';

  @override
  String get dronecanVendorStatusCode => 'Kód stavu výrobcu';

  @override
  String get dronecanActionRestart => 'Reštart';

  @override
  String get dronecanActionTransportStats => 'Štatistiky prenosu';

  @override
  String get dronecanActionUpdateFirmware => 'Aktualizovať firmware';

  @override
  String get dronecanActionConfiguration => 'Konfigurácia';

  @override
  String get dronecanRestartConfirmTitle => 'Reštart uzla';

  @override
  String dronecanRestartConfirmMessage(String name, int id) {
    return 'Uzol \"$name\" (ID $id) sa okamžite reštartuje.';
  }

  @override
  String get dronecanRestartConfirmAction => 'Napriek tomu reštartovať';

  @override
  String get dronecanRestartRiskUnavailable =>
      'Uzol na niekoľko sekúnd prestane vysielať dáta a všetko, čo poskytuje, bude nedostupné.';

  @override
  String get dronecanRestartRiskUnsavedConfig =>
      'Neuložená konfigurácia uzla sa stratí.';

  @override
  String get dronecanRestartRiskInFlight =>
      'Nikdy nereštartujte uzol počas letu. Môžete prísť o prístroje, na ktoré sa spoliehate.';

  @override
  String get dronecanRestartRiskOffline =>
      'Ak reštart zlyhá, uzol môže zostať offline až do vypnutia a zapnutia CAN zbernice.';

  @override
  String get dronecanRestartSuccess => 'Príkaz na reštart bol prijatý';

  @override
  String get dronecanRestartRejected => 'Uzol reštart odmietol';

  @override
  String get dronecanRequestFailed =>
      'Požiadavka zlyhala. Skontrolujte DroneCAN spojenie.';

  @override
  String dronecanTransportStatsTitle(int nodeId) {
    return 'Štatistiky prenosu · $nodeId';
  }

  @override
  String get dronecanStatsAutoRefreshHint =>
      'Aktualizuje sa každú sekundu; hodnota v zátvorke je zmena od predchádzajúceho merania.';

  @override
  String get dronecanTransfersTx => 'Prenosy TX';

  @override
  String get dronecanTransfersRx => 'Prenosy RX';

  @override
  String get dronecanTransferErrors => 'Chyby prenosu';

  @override
  String get dronecanCanInterfaces => 'CAN rozhrania';

  @override
  String get dronecanFramesTx => 'Rámce TX';

  @override
  String get dronecanFramesRx => 'Rámce RX';

  @override
  String get dronecanErrors => 'Chyby';

  @override
  String get dronecanNoInterfaceStats =>
      'Uzol neposkytol štatistiky CAN rozhraní.';

  @override
  String dronecanCanInterfaceLabel(int index) {
    return 'Rozhranie $index';
  }

  @override
  String get dronecanFirmwareUpdateTitle => 'Aktualizácia firmvéru';

  @override
  String get dronecanFirmwareUpdateHint =>
      'Vyberte obraz firmvéru pre DroneCAN (.bin). Uzol si ho stiahne po CAN zbernici.';

  @override
  String get dronecanFirmwareUpdateChooseFile => 'Vybrať súbor';

  @override
  String get dronecanFirmwareUpdateChangeFile => 'Zmeniť súbor';

  @override
  String get dronecanFirmwareUpdateNoFile =>
      'Nie je vybraný žiadny súbor firmvéru';

  @override
  String get dronecanFirmwareUpdateUpload => 'Nahrať firmvér';

  @override
  String get dronecanFirmwareUpdatePreparing =>
      'Čakám, kým uzol vyžiada obraz…';

  @override
  String get dronecanFirmwareUpdateUploading => 'Nahrávam firmvér…';

  @override
  String dronecanFirmwareUpdateProgress(
    int percent,
    String transferred,
    String total,
  ) {
    return '$percent % ($transferred z $total)';
  }

  @override
  String get dronecanFirmwareUpdateCompleted =>
      'Firmvér bol nahraný. Uzol overí obraz a reštartuje sa s novou verziou.';

  @override
  String get dronecanFirmwareUpdateFailed => 'Aktualizácia firmvéru zlyhala.';

  @override
  String dronecanFirmwareUpdateRejected(int code) {
    return 'Uzol aktualizáciu odmietol (chyba $code).';
  }

  @override
  String dronecanFirmwareUpdateRejectedWithMessage(String message) {
    return 'Uzol aktualizáciu odmietol: $message';
  }

  @override
  String get dronecanFirmwareUpdateTimeout =>
      'Uzol prestal žiadať dáta firmvéru.';

  @override
  String get dronecanFirmwareUpdateEmptyFile => 'Vybraný súbor je prázdny.';

  @override
  String get dronecanFirmwareUpdateReadFailed =>
      'Vybraný súbor sa nepodarilo prečítať.';

  @override
  String get dronecanFirmwareUpdateNotSupported =>
      'Aktualizácia firmvéru nie je na tejto platforme podporovaná.';

  @override
  String get dronecanFirmwareUpdateRiskInFlight =>
      'Nikdy neaktualizujte firmvér počas letu. Uzol je počas aktualizácie nedostupný.';

  @override
  String get dronecanFirmwareUpdateRiskPower =>
      'Neprerušujte napájanie ani CAN spojenie počas nahrávania, uzol by mohol zostať bez funkčného firmvéru.';

  @override
  String get dronecanFirmwareUpdateRiskRestart =>
      'Uzol sa reštartuje do bootloadera a následne sa vráti s novým firmvérom.';

  @override
  String get dronecanFirmwareUpdateKeepOpen =>
      'Nechajte tento dialóg otvorený, kým sa nahrávanie nedokončí.';

  @override
  String dronecanNodeIdBadge(int id) {
    return 'ID $id';
  }

  @override
  String get dronecanConfigurationTitle => 'Konfigurácia';

  @override
  String get dronecanConfigurationRefresh => 'Obnoviť';

  @override
  String get dronecanConfigurationStoreAll => 'Uložiť všetko';

  @override
  String get dronecanConfigurationEraseAll => 'Vymazať všetko';

  @override
  String get dronecanConfigurationLoading => 'Načítavam parametre…';

  @override
  String get dronecanConfigurationModifiedHint =>
      'Hodnoty odlišné od predvolenej sú zvýraznené.';

  @override
  String dronecanConfigurationParameterCount(int count) {
    return 'Parametre: $count';
  }

  @override
  String get dronecanConfigurationEmpty => 'Uzol neohlásil žiadne parametre.';

  @override
  String get dronecanConfigurationLoadFailed => 'Načítanie parametrov zlyhalo.';

  @override
  String get dronecanParameterColumnId => 'ID';

  @override
  String get dronecanParameterColumnName => 'Názov';

  @override
  String get dronecanParameterColumnType => 'Typ';

  @override
  String get dronecanParameterColumnValue => 'Hodnota';

  @override
  String get dronecanParameterEditTooltip => 'Upraviť hodnotu';

  @override
  String get dronecanParameterTypeInteger => 'Celé číslo';

  @override
  String get dronecanParameterTypeReal => 'Reálne číslo';

  @override
  String get dronecanParameterTypeBoolean => 'Boolean';

  @override
  String get dronecanParameterTypeString => 'Reťazec';

  @override
  String get dronecanParameterTypeEmpty => 'Prázdne';

  @override
  String get dronecanParameterValueTrue => 'áno';

  @override
  String get dronecanParameterValueFalse => 'nie';

  @override
  String dronecanParameterDefaultValue(String value) {
    return 'predvolené $value';
  }

  @override
  String get dronecanParameterEditTitle => 'Upraviť parameter';

  @override
  String get dronecanParameterTypeLabel => 'Typ';

  @override
  String get dronecanParameterValueLabel => 'Hodnota';

  @override
  String get dronecanParameterMinLabel => 'Min';

  @override
  String get dronecanParameterMaxLabel => 'Max';

  @override
  String get dronecanParameterDefaultLabel => 'Predvolené';

  @override
  String get dronecanParameterInvalidInteger => 'Zadajte celé číslo.';

  @override
  String get dronecanParameterInvalidNumber => 'Zadajte platné číslo.';

  @override
  String dronecanParameterOutOfRange(String min, String max) {
    return 'Hodnota musí byť medzi $min a $max.';
  }

  @override
  String dronecanParameterBelowMin(String min) {
    return 'Hodnota musí byť aspoň $min.';
  }

  @override
  String dronecanParameterAboveMax(String max) {
    return 'Hodnota musí byť najviac $max.';
  }

  @override
  String dronecanParameterStringTooLong(int max) {
    return 'Text je príliš dlhý (max $max znakov).';
  }

  @override
  String dronecanParameterSetSuccess(String name) {
    return 'Parameter $name bol aktualizovaný';
  }

  @override
  String dronecanParameterSetFailed(String name) {
    return 'Parameter $name sa nepodarilo aktualizovať';
  }

  @override
  String get dronecanConfigurationStoreSuccess =>
      'Konfigurácia bola uložená do uzla';

  @override
  String get dronecanConfigurationStoreFailed =>
      'Uloženie konfigurácie zlyhalo';

  @override
  String get dronecanConfigurationEraseConfirmTitle => 'Vymazať konfiguráciu';

  @override
  String dronecanConfigurationEraseConfirmMessage(String name, int id) {
    return 'Všetky parametre uzla \"$name\" (ID $id) sa vrátia na predvolené hodnoty. Neuložené zmeny sa stratia a uzol môže vyžadovať reštart.';
  }

  @override
  String get dronecanConfigurationEraseConfirmAction => 'Vymazať';

  @override
  String get dronecanConfigurationEraseSuccess => 'Konfigurácia bola vymazaná';

  @override
  String get dronecanConfigurationEraseFailed =>
      'Vymazanie konfigurácie zlyhalo';

  @override
  String takeoffsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vzletov',
      few: '$count vzlety',
      one: '1 vzlet',
    );
    return '$_temp0';
  }

  @override
  String get flightNotes => 'Poznámka';

  @override
  String enterPilotPin(String name) {
    return 'Zadajte PIN kód pre pilota \"$name\":';
  }

  @override
  String get pinCode => 'PIN kód';

  @override
  String get incorrectPin => 'Nesprávny PIN kód!';

  @override
  String get confirm => 'Potvrdiť';

  @override
  String get selectPilotTitle => 'Výber pilota';

  @override
  String get deletePilotTitle => 'Vymazať pilota';

  @override
  String deletePilotConfirm(String name) {
    return 'Naozaj chcete vymazať pilota \"$name\"? Táto akcia je nevratná a vymaže všetky jeho nastavenia.';
  }

  @override
  String get deletePilotPinPrompt => 'Zmazanie pilota';

  @override
  String pilotDeletedSnackbar(String name) {
    return 'Pilot \"$name\" bol vymazaný.';
  }

  @override
  String settingsUpdateFailed(String error) {
    return 'Zlyhala aktualizácia nastavení: $error';
  }

  @override
  String get addAircraftTitle => 'Pridať lietadlo';

  @override
  String get aircraftNameLabel => 'Registračná značka / Názov';

  @override
  String get aircraftNameRequired => 'Zadajte názov lietadla!';

  @override
  String get create => 'Vytvoriť';

  @override
  String get switchAircraftTitle => 'Prepnúť lietadlo';

  @override
  String get addNewAircraft => 'Pridať nové lietadlo';

  @override
  String get savedAircraftsSection => 'Uložené lietadlá';

  @override
  String get noAircraftsCreated => 'Zatiaľ nie sú vytvorené žiadne lietadlá.';

  @override
  String get deselectAircraft => 'Odhlásiť lietadlo (Neznáme)';

  @override
  String get errorPrefix => 'Chyba pri načítaní údajov';

  @override
  String get aircraftSettingsTitle => 'Nastavenia lietadla';

  @override
  String get initialFlightHoursLabel => 'Inicializačné letové hodiny';

  @override
  String get hoursExampleHint => 'Napr. 10.5';

  @override
  String get invalidFlightHours => 'Zadajte platné letové hodiny!';

  @override
  String get initialHoursSaved => 'Inicializačné letové hodiny uložené.';

  @override
  String get initialFlightsLabel => 'Inicializačný počet letov';

  @override
  String get flightsExampleHint => 'Napr. 24';

  @override
  String get invalidFlights => 'Zadajte platný počet letov!';

  @override
  String get initialFlightsSaved => 'Inicializačný počet letov uložený.';

  @override
  String get deleteAircraftButton => 'Vymazať lietadlo';

  @override
  String deleteAircraftConfirm(String name) {
    return 'Naozaj chcete vymazať lietadlo \"$name\"?';
  }

  @override
  String aircraftDeletedSnackbar(String name) {
    return 'Lietadlo \"$name\" bolo vymazané.';
  }

  @override
  String get close => 'Zatvoriť';

  @override
  String get addPilotTitle => 'Pridať pilota';

  @override
  String get pilotNameLabel => 'Meno pilota';

  @override
  String get pilotNameRequired => 'Zadajte meno pilota!';

  @override
  String get optionalPinLabel => 'Voliteľný PIN kód (len čísla)';

  @override
  String get switchPilotTitle => 'Prepnúť pilota';

  @override
  String get addNewPilot => 'Pridať nového pilota';

  @override
  String get savedProfilesSection => 'Uložené profily';

  @override
  String get noPilotsCreated => 'Zatiaľ nie sú vytvorení žiadni piloti.';

  @override
  String get protectedByPin => 'Chránený PIN';

  @override
  String get noPin => 'Bez PIN-u';

  @override
  String get profileAndAircraftPageTitle => 'Profil a lietadlo';

  @override
  String get pilotUppercase => 'PILOT';

  @override
  String get aircraftUppercase => 'LIETADLO';

  @override
  String get accessSettingsTitle => 'Prístup k nastaveniam';

  @override
  String get noPilotSelected => 'Žiadny pilot';

  @override
  String get unknown => 'Neznáme';

  @override
  String get notLoggedIn => 'Neprihlásený';

  @override
  String get localProfile => 'Lokálny';

  @override
  String hoursFlown(String hours) {
    return 'Nalietané: $hours';
  }

  @override
  String get noActivePilot => 'Žiadny aktívny pilot';

  @override
  String get noActivePilotInstructions =>
      'Pre zobrazenie letových štatistík a konfiguráciu nastavení si zvoľte aktívneho pilota zo zoznamu vyššie.';

  @override
  String get pilotFlightStats => 'Letové štatistiky pilota';

  @override
  String get aircraftFlightStats => 'Letové štatistiky lietadla';

  @override
  String get today => 'Dnes';

  @override
  String get thisWeek => 'Tento týždeň';

  @override
  String get thisMonth => 'Tento mesiac';

  @override
  String get thisYear => 'Tento rok';

  @override
  String get overall => 'Celkovo';

  @override
  String get statsCalcError => 'Chyba pri výpočte štatistík';

  @override
  String get aircraftStatsCalcError => 'Chyba pri výpočte štatistík lietadla';

  @override
  String get pilotSettingsTitle => 'Nastavenia pilota';

  @override
  String get pinSecurityLabel => 'Zabezpečenie PIN kódom';

  @override
  String get newPinHint => 'Nový PIN (prázdny pre vypnutie)';

  @override
  String get pilotPinUpdatedSnackbar => 'PIN kód pilota bol aktualizovaný.';

  @override
  String get deselectPilot => 'Odhlásiť pilota (Neznáme)';

  @override
  String hoursMinutesFormat(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get hoursMinutesFallback => '---h --m';

  @override
  String get errorLoadingSettings => 'Chyba pri načítaní nastavení';

  @override
  String get tempUnitCelsius => 'Celsius';

  @override
  String get tempUnitKelvin => 'Kelvin';

  @override
  String get tempUnitFahrenheit => 'Fahrenheit';

  @override
  String get temperatureUnitSettings => 'Jednotka teploty';

  @override
  String get pressureUnitSettings => 'Jednotka tlaku';

  @override
  String get oilTemperature => 'Teplota oleja';

  @override
  String get oilTemperatureShort => 'Tep. ol.';

  @override
  String get oilTemperatureSettings => 'Teplota oleja';

  @override
  String get oilTempMaxRange => 'Maximálny rozsah teploty oleja';

  @override
  String get oilPressure => 'Tlak oleja';

  @override
  String get oilPressureShort => 'Tlak ol.';

  @override
  String get oilPressureSettings => 'Tlak oleja';

  @override
  String get oilPressureMaxRange => 'Maximálny rozsah tlaku oleja';

  @override
  String get cylinderHeadTemperatureShort => 'CHT';

  @override
  String get chtTemperature => 'Teplota hlavy valcov (CHT)';

  @override
  String get chtTemperatureSettings => 'Teplota hlavy valcov (CHT)';

  @override
  String get chtMaxRange => 'Maximálny rozsah teploty CHT';

  @override
  String get egtTemperature => 'Teplota výfukových plynov';

  @override
  String get egtTemperatureShort => 'EGT';

  @override
  String get egtTemperatureSettings => 'Teplota výfukových plynov';

  @override
  String get egtMaxRange => 'Maximálny rozsah teploty výfukových plynov';

  @override
  String get fuelTankStatus => 'Palivo';

  @override
  String get fuelTankStatusShort => 'Palivo';

  @override
  String get fuelTankStatusSettings => 'Palivová nádrž';

  @override
  String get engineRpm => 'Otáčky motora (RPM)';

  @override
  String get engineRpmShort => 'RPM';

  @override
  String get rpmThresholds => 'Prahové hodnoty otáčok motora';

  @override
  String get rpmMaxRange => 'Maximálny rozsah posuvníka otáčok';

  @override
  String vhfRadioTitle(int instance) {
    return 'Rádio COM$instance';
  }

  @override
  String get vhfRadioActive => 'AKTÍVNA';

  @override
  String get vhfRadioStandby => 'STANDBY';

  @override
  String get vhfRadioNoName => 'Bez názvu';

  @override
  String get vhfRadioSwapTooltip => 'Prehodiť frekvencie';

  @override
  String get vhfRadioNearbyFrequencies => 'Blízke frekvencie';

  @override
  String get vhfRadioAdvancedManual => 'Rozšírené / Manuálne';

  @override
  String get vhfRadioNearbyAirports => 'Blízke letiská';

  @override
  String get vhfRadioNoAirportsNearby => 'V okolí nie sú žiadne letiská';

  @override
  String get vhfRadioFavourites => 'Obľúbené';

  @override
  String get vhfRadioManage => 'Spravovať';

  @override
  String get vhfRadioNoFavoriteFrequencies => 'Žiadne obľúbené frekvencie';

  @override
  String get vhfRadioAirspaces => 'Letecké priestory';

  @override
  String get vhfRadioNoAirspacesNearby =>
      'V okolí nie sú žiadne letecké priestory';

  @override
  String get vhfRadioInside => 'vo vnútri';

  @override
  String get vhfRadioBackToList => 'Späť na zoznam';

  @override
  String get vhfRadioActiveFreqLabel => 'Aktívna frekvencia (MHz)';

  @override
  String get vhfRadioActiveNameLabel => 'Názov aktívnej stanice';

  @override
  String get vhfRadioApply => 'Použiť';

  @override
  String get vhfRadioStandbyFreqLabel => 'Standby frekvencia (MHz)';

  @override
  String get vhfRadioStandbyNameLabel => 'Názov standby stanice';

  @override
  String get vhfRadioDualWatch => 'Dual Watch';

  @override
  String get vhfRadioHideAudio => 'Skryť audio nastavenia';

  @override
  String get vhfRadioShowAudio => 'Zobraziť audio nastavenia';

  @override
  String get vhfRadioVolume => 'Hlasitosť';

  @override
  String get vhfRadioSquelch => 'Squelch';

  @override
  String get vhfRadioVox => 'VOX citlivosť';

  @override
  String get vhfRadioIntercom => 'Hlasitosť interkomu';

  @override
  String get vhfRadioMicrophonesGain => 'Mikrofóny (zisk)';

  @override
  String vhfRadioMicrophoneN(int n) {
    return 'Mikrofón $n';
  }

  @override
  String get vhfRadioSaveChange => 'Uložiť zmenu';

  @override
  String get vhfRadioErrorActiveFreq =>
      'Aktívna frekvencia musí byť platná letecká frekvencia (118.000 – 136.995 MHz).';

  @override
  String get vhfRadioErrorStandbyFreq =>
      'Standby frekvencia musí byť platná letecká frekvencia (118.000 – 136.995 MHz).';

  @override
  String vhfRadioErrorTimeout(String action) {
    return 'DroneCAN neodpovedal na požiadavku $action (timeout 1 s).';
  }

  @override
  String vhfRadioErrorGeneric(String action, String error) {
    return 'Zlyhalo $action: $error';
  }

  @override
  String vhfRadioErrorFlip(String error) {
    return 'Prehodenie zlyhalo: $error';
  }

  @override
  String vhfRadioErrorInvalidFreq(String freq) {
    return 'Frekvencia $freq MHz nie je platná.';
  }

  @override
  String vhfRadioDronecanError(int status) {
    return 'Chyba DroneCAN požiadavky (status: $status)';
  }

  @override
  String get vhfRadioFreqOutOfBand =>
      'Frekvencia je mimo leteckého pásma (118.000 – 136.995 MHz).';

  @override
  String get manageFavoritesTitle => 'Spravovať obľúbené';

  @override
  String get manageFavoritesAddNew => 'Pridať novú frekvenciu';

  @override
  String get manageFavoritesFreqLabel => 'Frekvencia (MHz)';

  @override
  String get manageFavoritesFreqHint => '118.000';

  @override
  String get manageFavoritesNameLabel => 'Názov stanice';

  @override
  String get manageFavoritesNameHint => 'FIR Bratislava';

  @override
  String get manageFavoritesAddToList => 'Pridať do zoznamu';

  @override
  String get manageFavoritesListTitle =>
      'Zoznam obľúbených (potiahnutím zmeňte poradie)';

  @override
  String get manageFavoritesEmpty => 'Zoznam je prázdny.';

  @override
  String get manageFavoritesInvalidFreq =>
      'Neplatná letecká frekvencia (118.000 - 136.975 MHz).';

  @override
  String get manageFavoritesNameRequired => 'Názov nesmie byť prázdny.';

  @override
  String manageFavoritesLoadError(String error) {
    return 'Chyba pri načítaní obľúbených: $error';
  }

  @override
  String get radioNotConnected => 'Rádio nie je pripojené';

  @override
  String get radioSetAsActive => 'Nastaviť ako AKTÍVNU';

  @override
  String get radioSetAsStandby => 'Nastaviť ako STANDBY';

  @override
  String radioSetFreqError(String error) {
    return 'Chyba nastavenia frekvencie: $error';
  }

  @override
  String get varioTitle => 'Vario';

  @override
  String get varioDetailsTitle => 'Detaily varia';

  @override
  String get varioUnitMs => 'm/s';

  @override
  String get varioSourceBaro => 'BARO (Tlak)';

  @override
  String get varioSourceGps => 'GPS';

  @override
  String get varioSourceNone => 'N/A';

  @override
  String get varioCurrentValue => 'Vertikálna rýchlosť';

  @override
  String get varioSourceLabel => 'Zdroj';

  @override
  String get varioAirPressure => 'Tlak vzduchu';

  @override
  String get varioQnhUsed => 'Použité QNH';

  @override
  String get varioLastUpdate => 'Posledná aktualizácia';

  @override
  String get ognSettingsSection => 'Nastavenia OGN';

  @override
  String get sendLivePosition => 'Odosielať polohu live';

  @override
  String get sendLivePositionDesc =>
      'Odosielanie live sledovania polohy na OGN servery';

  @override
  String get ognDeviceIdLabel => 'Zadajte svoje OGN ID';

  @override
  String get ognDeviceIdHint => 'Napr. ICA74F';

  @override
  String get ognGuideTitle => 'Ako získať OGN ID:';

  @override
  String get ognGuideStep1 =>
      '1. Navštívte bezplatnú databázu ddb.glidernet.org.';

  @override
  String get ognGuideStep2 =>
      '2. Zaregistrujte svoje lietadlo (zvoľte typ zariadenia: OGN Tracker / Lyntia / Škola, alebo priraďte k vášmu FLARM/ICAO kódu).';

  @override
  String get ognGuideStep3 =>
      '3. Systém vám vygeneruje unikátne 6-miestne ID prístroja (napr. ICA74F), ktoré zadáte do tejto aplikácie. Od tejto chvíle vás uvidia ostatní piloti aj záchranné zložky.';

  @override
  String get trafficTitle => 'Letecká doprava';

  @override
  String get aircraftCountLabel => 'Počet lietadiel';

  @override
  String get callsignRegistrationLabel => 'Identifikácia / Imatrikulácia';

  @override
  String get absoluteAltitudeLabel => 'Absolútna výška (AMSL)';

  @override
  String get relativeAltitudeLabel => 'Relatívna výška';

  @override
  String get groundSpeedLabel => 'Rýchlosť voči zemi';

  @override
  String get verticalSpeedLabel => 'Vario / Stúpanie / Klesanie';

  @override
  String get distanceFromUsLabel => 'Vzdialenosť od našej polohy';

  @override
  String get gliderType => 'Vetroň';

  @override
  String get towPlaneType => 'Vlečné lietadlo';

  @override
  String get helicopterType => 'Vrtuľník';

  @override
  String get skydiverType => 'Parašutista';

  @override
  String get dropPlaneType => 'Výsadkové lietadlo';

  @override
  String get hangGliderType => 'Závesný klzák';

  @override
  String get paragliderType => 'Paraglajder';

  @override
  String get poweredAircraftType => 'Motorové lietadlo';

  @override
  String get jetType => 'Prúdové lietadlo';

  @override
  String get balloonType => 'Balón';

  @override
  String get airshipType => 'Vzducholoď';

  @override
  String get uavType => 'Dron';

  @override
  String get ultralightType => 'Ultralight';

  @override
  String get gaType => 'GA';

  @override
  String get otherType => 'Iné';

  @override
  String get aircraftTypeLabel => 'Typ lietadla';

  @override
  String get invalidOgnId => 'Neplatné OGN ID. Musí mať presne 6 znakov.';

  @override
  String get anonymousAircraft => 'Anonymné lietadlo';

  @override
  String get anonymousTrafficDesc =>
      'Toto lietadlo má vypnuté verejné sledovanie. Telemetrické údaje sú viditeľné z bezpečnostných dôvodov, no identifikácia je anonymná.';

  @override
  String get lastSeenLabel => 'Posledná aktivita';

  @override
  String get trafficSettings => 'Nastavenia premávky';

  @override
  String get enableHorizontalDistanceFilter =>
      'Filtrovať podľa horizontálnej vzdialenosti';

  @override
  String get trafficMaxHorizontalDistance => 'Max. horizontálna vzdialenosť';

  @override
  String get enableVerticalDistanceFilter =>
      'Filtrovať podľa vertikálnej vzdialenosti';

  @override
  String get trafficMaxVerticalDistance => 'Max. vertikálna vzdialenosť';

  @override
  String get trafficNoDataAvailable =>
      'Žiadne dáta o letovej prevádzke nie sú k dispozícii.';

  @override
  String trafficMaxHorizontalDistanceSummary(String km) {
    return '$km km';
  }

  @override
  String get enableCas => 'Anti-kolízny systém (CAS)';

  @override
  String get casEnabledDesc =>
      'Predikuje 3D trajektórie a varuje pred hroziacimi kolíziami';

  @override
  String get casLookaheadTime => 'Čas predikcie (Lookahead)';

  @override
  String get casHorizontalThreshold => 'Horizontálna výstražná vzdialenosť';

  @override
  String get casVerticalThreshold => 'Vertikálna výstražná vzdialenosť';

  @override
  String get sameAltLabel => 'ROVNAKÁ VÝŠKA';

  @override
  String aboveAltLabel(String alt) {
    return '+$alt NAD';
  }

  @override
  String belowAltLabel(String alt) {
    return '-$alt POD';
  }

  @override
  String get collisionWarningLabel => 'KOLÍZIA';

  @override
  String get collisionMinSeparation => 'Najmenší odstup';

  @override
  String get collisionTimeToClosest => 'Čas do priblíženia';

  @override
  String get collisionAltitudeDifference => 'Rozdiel výšky teraz';

  @override
  String get pureTrackTitle => 'PureTrack Účet';

  @override
  String get pureTrackDescription =>
      'Sekundárny zdroj letových telemetrických dát';

  @override
  String get pureTrackUsername => 'Meno / Email';

  @override
  String get pureTrackPassword => 'Heslo';

  @override
  String get pureTrackLogin => 'Prihlásiť sa';

  @override
  String get pureTrackLogout => 'Odhlásiť sa';

  @override
  String get pureTrackStatusConnected => 'Pripojené';

  @override
  String get pureTrackStatusDisconnected => 'Odpojené';

  @override
  String get pureTrackStatusAuthenticating => 'Prihlasujem...';

  @override
  String get pureTrackStatusTokenInvalid =>
      'Relácia vypršala (Vyžaduje sa prihlásenie)';

  @override
  String get pureTrackStatusError => 'Chyba prihlásenia';

  @override
  String get pureTrackSessionExpiredBanner =>
      'PureTrack relácia vypršala. Kliknite pre opätovné prihlásenie.';

  @override
  String get trafficSourceLabel => 'Zdroj dát';

  @override
  String get trafficSourceOgn => 'OGN';

  @override
  String get trafficSourcePureTrack => 'PureTrack';

  @override
  String get trafficSourceGdl90 => 'GDL90';

  @override
  String get gdl90SettingsTitle => 'GDL90 / SafeSky Prijímač';

  @override
  String get gdl90EnableTitle => 'Povoliť GDL90 prijímač';

  @override
  String get gdl90EnableDesc =>
      'Prijímať lokálnu letovú prevádzku cez UDP (SafeSky, Stratux, SkyEcho 2, atď.)';

  @override
  String get gdl90BindIpTitle => 'IP Adresa prijímača';

  @override
  String get gdl90PortTitle => 'UDP Port';

  @override
  String get gdl90TargetExpiryTitle => 'Čas vypršania platnosti cieľa';

  @override
  String get gdl90StatusTitle => 'Stav prijímača';

  @override
  String get gdl90StatusActive => 'Aktívny';

  @override
  String get gdl90StatusInactive => 'Neaktívny (Bez signálu)';

  @override
  String get ognEnableTitle => 'Povoliť OGN';

  @override
  String get ognEnableDesc =>
      'Prijímať a odosielať letovú prevádzku cez Open Glider Network';

  @override
  String get pureTrackEnableTitle => 'Povoliť PureTrack';

  @override
  String get pureTrackEnableDesc => 'Prijímať letovú prevádzku cez PureTrack';

  @override
  String get hideAircraft => 'Skryť';

  @override
  String get hiddenAircraftSection => 'Skryté lietadlá';

  @override
  String get noHiddenAircraft => 'Žiadne skryté lietadlá.';

  @override
  String hiddenAircraftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skrytých lietadiel',
      few: '$count skryté lietadlá',
      one: '1 skryté lietadlo',
    );
    return '$_temp0';
  }

  @override
  String get unhideAircraft => 'Zobraziť znova';

  @override
  String get clearAllHiddenAircraft => 'Vymazať všetky skryté';

  @override
  String get settingsMapAppearance => 'Vzhľad mapy';

  @override
  String get settingsMapZoom => 'Priblíženie a náklon mapy';

  @override
  String get settingsWidgetLayout => 'Rozloženie widgetov';

  @override
  String get settingsResetLayoutConfirm =>
      'Obnoviť uložené pozície widgetov v aktuálnom rozložení? Táto zmena sa nedá vrátiť.';

  @override
  String get settingsConnection => 'Pripojenie brány';

  @override
  String get settingsFlightMeasurements => 'Jednotky a merania';

  @override
  String get settingsFlightLimits => 'Letové a motorové limity';

  @override
  String get settingsTrafficFilters => 'Filtre premávky';

  @override
  String get settingsCollisionAvoidance => 'Prevencia kolízií';

  @override
  String get settingsTrafficSources => 'Zdroje údajov o premávke';

  @override
  String get menuFlightAndMap => 'Let a mapa';

  @override
  String get menuRoute => 'Trasa';

  @override
  String get menuNoActiveRoute => 'Bez aktívnej trasy';

  @override
  String menuActiveRoute(String destination) {
    return 'Aktívna · $destination';
  }

  @override
  String get menuFavoritePlaces => 'Obľúbené miesta';

  @override
  String get menuDone => 'Hotovo';

  @override
  String get menuOfflineDownloading => 'Sťahujú sa mapy';

  @override
  String menuOfflineDownloaded(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Stiahnuté $dateString';
  }

  @override
  String get menuMap => 'Mapa';

  @override
  String get menuMapSummary => 'Vzhľad, priblíženie a rozloženie widgetov';

  @override
  String get menuUnitsAndLimits => 'Jednotky a limity';

  @override
  String menuUnitsSummary(String speed, String altitude) {
    return '$speed · $altitude · limity lietadla';
  }

  @override
  String get menuTrafficAndAlerts => 'Doprava a výstrahy';

  @override
  String get menuCollisionAlertsOn => 'Kolízne výstrahy zapnuté';

  @override
  String get menuCollisionAlertsOff => 'Kolízne výstrahy vypnuté';

  @override
  String get menuInstrumentsAndConnection => 'Prístroje a pripojenie';

  @override
  String get menuGatewayConnected => 'Brána pripojená';

  @override
  String get menuGatewayDisconnected => 'Brána odpojená';

  @override
  String get menuSearchingGateways => 'Vyhľadávajú sa brány…';

  @override
  String get menuFindGateways => 'Vyhľadať znova';

  @override
  String get mapAlertStatusTooltip => 'Stav systémov';

  @override
  String mapAlertSince(String time) {
    return 'Aktívne od $time';
  }

  @override
  String get mapAlertAllGoodTitle => 'Stav systémov';

  @override
  String get mapAlertAllGoodBody => 'Všetky sledované systémy fungujú správne.';

  @override
  String get mapAlertMapStyleTitle => 'Mapu sa nepodarilo načítať';

  @override
  String get mapAlertMapStyleBody =>
      'Mapu sa nepodarilo zobraziť. Skús mapu zavrieť a znova otvoriť.';

  @override
  String get mapAlertGpsPermissionTitle => 'Chýba povolenie na polohu';

  @override
  String get mapAlertGpsPermissionBody =>
      'Stork nemá povolenie používať polohu zariadenia. Povoľ prístup k polohe v nastaveniach telefónu.';

  @override
  String get mapAlertLocationServicesTitle => 'Polohové služby sú vypnuté';

  @override
  String get mapAlertLocationServicesBody =>
      'Zapni polohové služby v zariadení, aby Stork mohol zobraziť tvoju polohu.';

  @override
  String get mapAlertGpsStreamTitle => 'GPS prestalo odpovedať';

  @override
  String get mapAlertGpsStreamBody =>
      'Zariadenie prestalo posielať aktualizácie polohy. Stork sa ich pokúsi automaticky obnoviť.';

  @override
  String get mapAlertGpsLostTitle => 'GPS signál sa stratil';

  @override
  String get mapAlertGpsLostBody =>
      'Poloha lietadla na mape už nemusí byť aktuálna. Pokračuj v navigácii vizuálne a skús obnoviť GPS signál.';

  @override
  String get mapAlertGpsNoFixTitle => 'Čakám na GPS';

  @override
  String get mapAlertGpsNoFixBody =>
      'Stork zatiaľ nemá polohu z GPS. Uisti sa, že máš voľný výhľad na oblohu a že je GPS zapnutá.';

  @override
  String get mapAlertDroneCanGpsTitle => 'Používa sa záložná GPS';

  @override
  String get mapAlertDroneCanGpsBody =>
      'GPS lietadla prestala posielať údaje. Stork prešiel na GPS telefónu, ktorá môže byť menej presná.';

  @override
  String get mapAlertTelemetryLinkTitle => 'Spojenie s lietadlom sa stratilo';

  @override
  String get mapAlertTelemetryLinkBody =>
      'Stork nemá spojenie s telemetriou lietadla. Rýchlosť, výška a údaje o motore môžu byť zastarané.';

  @override
  String get mapAlertTelemetryStaleTitle => 'Telemetria sa neaktualizuje';

  @override
  String get mapAlertTelemetryStaleBody =>
      'Spojenie je nadviazané, ale neprichádzajú nové údaje. Hodnoty na obrazovke môžu byť zamrznuté.';

  @override
  String get mapAlertAltitudeUnavailableTitle => 'Výška nie je dostupná';

  @override
  String get mapAlertAltitudeUnavailableBody =>
      'Stork nemá údaj o výške. Výstrahy terénu a zrážok môžu byť obmedzené.';

  @override
  String get mapAlertTrafficOfflineTitle => 'Dopravné dáta nie sú dostupné';

  @override
  String get mapAlertTrafficOfflineBody =>
      'Stork neprijíma údaje o okolitej doprave, preto nie sú aktívne výstrahy zrážok. Skontroluj internet alebo prijímač.';

  @override
  String get mapAlertInternetTitle => 'Bez internetového pripojenia';

  @override
  String get mapAlertInternetBody =>
      'Mapové detaily a aktuálne priestory sa nemusia aktualizovať.';

  @override
  String get mapAlertAirspaceTitle => 'Dáta o priestoroch nie sú dostupné';

  @override
  String get mapAlertAirspaceBody =>
      'Aktuálnu aktivitu vzdušných priestorov sa nepodarilo stiahnuť. Zvýraznenie aktívnych priestorov môže chýbať.';

  @override
  String get mapAlertTerrainTitle => 'Terénne dáta nie sú dostupné';

  @override
  String get mapAlertTerrainBody =>
      'Stork nemá výšku terénu. Výška nad terénom a terénne výstrahy nemusia fungovať.';

  @override
  String get mapAlertOfflineMapsTitle => 'Offline mapa nie je pripravená';

  @override
  String get mapAlertOfflineMapsBody =>
      'Offline mapu sa nepodarilo stiahnuť. Bez internetu nemusí byť mapa dostupná.';

  @override
  String get mapAlertAltitudeSourceTitle => 'Zmenil sa zdroj výšky';

  @override
  String get mapAlertAltitudeSourceBody =>
      'Zdroj výšky sa zmenil. Hodnota sa môže mierne líšiť od predošlej.';

  @override
  String get mapAlertCollisionTitle => 'Výstraha pred zrážkou';

  @override
  String get mapAlertCollisionBody =>
      'Stork zistil možné nebezpečenstvo zrážky s okolitou premávkou. Podrobnosti o hrozbe sú v upozornení na mape.';

  @override
  String mapAlertEngineOverheat(String instrument) {
    return 'Prehrievanie motora · $instrument';
  }

  @override
  String mapAlertInstrumentLow(String instrument) {
    return '$instrument · Nízka hodnota';
  }

  @override
  String mapAlertInstrumentHigh(String instrument) {
    return '$instrument · Vysoká hodnota';
  }

  @override
  String mapAlertInstrumentUnavailable(String instrument) {
    return '$instrument · Bez údajov';
  }

  @override
  String get mapAlertInstrumentUnavailableBody =>
      'Prístroj momentálne nedostáva údaj.';

  @override
  String get mapAlertInstrumentLowWarningBody =>
      'Hodnota dosiahla nastavenú dolnú hranicu varovania.';

  @override
  String get mapAlertInstrumentHighWarningBody =>
      'Hodnota dosiahla nastavenú hornú hranicu varovania.';

  @override
  String get mapAlertInstrumentLowErrorBody =>
      'Hodnota je na nastavenej dolnej kritickej hranici alebo pod ňou.';

  @override
  String get mapAlertInstrumentHighErrorBody =>
      'Hodnota je na nastavenej hornej kritickej hranici alebo nad ňou.';

  @override
  String mapAlertInstrumentCylinder(int number) {
    return 'Valec $number';
  }

  @override
  String get mapAlertRadioLabel => 'Rádio';

  @override
  String get mapAlertRadioFault => 'Porucha rádia';

  @override
  String get mapAlertRadioFaultBody => 'Rádio hlási poruchu.';

  @override
  String mapAlertActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktívnych výstrah',
      few: '$count aktívne výstrahy',
      one: '1 aktívna výstraha',
    );
    return '$_temp0';
  }

  @override
  String mapAlertMeasured(String value) {
    return 'Namerané $value';
  }

  @override
  String mapAlertCriticalLimit(String value) {
    return 'Kritický limit $value';
  }

  @override
  String mapAlertWarningLimit(String value) {
    return 'Hranica varovania $value';
  }

  @override
  String get mapAlertHistoryTitle => 'História výstrah';

  @override
  String mapAlertHistoryPeak(String value) {
    return 'Extrémna hodnota $value';
  }

  @override
  String mapAlertHistoryTiming(String start, String end, String duration) {
    return '$start – $end · Trvanie $duration';
  }

  @override
  String get mapAlertTemperatureSteady => 'Teplota stabilná za 30 s';

  @override
  String mapAlertTemperatureRising(String amount) {
    return 'Teplota stúpa · +$amount za 30 s';
  }

  @override
  String mapAlertTemperatureFalling(String amount) {
    return 'Teplota klesá · −$amount za 30 s';
  }

  @override
  String get flightNoRecordedAlerts =>
      'V tomto lete nie sú zaznamenané výstrahy.';

  @override
  String flightAlertNoRecordedEnd(String start) {
    return '$start · Koniec nezaznamenaný';
  }
}
