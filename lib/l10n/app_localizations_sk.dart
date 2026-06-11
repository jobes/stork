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
}
