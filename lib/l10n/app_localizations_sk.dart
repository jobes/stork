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
  String get notamsTitle => 'NOTAMy';

  @override
  String get notamDetails => 'Detaily NOTAMu';

  @override
  String get notamStart => 'Začiatok platnosti';

  @override
  String get notamEnd => 'Koniec platnosti';

  @override
  String get notamFir => 'FIR';

  @override
  String get notamLimits => 'Vertikálne limity';

  @override
  String get hideNotam => 'Skryť';

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
}
