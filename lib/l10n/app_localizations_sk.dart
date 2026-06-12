// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

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
  String get close => 'Zavrieť';

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
  String get airspaceActivityUlm => 'Plocha pre ULL';

  @override
  String get airspaceActivityGliding => 'Bezmotorové lietanie';

  @override
  String get airspaceActivityUnknown => 'Neznáma';
}
