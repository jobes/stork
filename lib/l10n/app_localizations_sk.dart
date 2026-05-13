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
}
