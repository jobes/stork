import '../../../../l10n/app_localizations.dart';

enum AltitudeUnit {
  meters,
  feet,
  flightLevel,
}

extension AltitudeUnitExtension on AltitudeUnit {
  double convertFromMeters(double meters) {
    switch (this) {
      case AltitudeUnit.meters:
        return meters;
      case AltitudeUnit.feet:
      case AltitudeUnit.flightLevel:
        return meters * 3.28084;
    }
  }

  double convertToMeters(double val) {
    switch (this) {
      case AltitudeUnit.meters:
        return val;
      case AltitudeUnit.feet:
      case AltitudeUnit.flightLevel:
        return val / 3.28084;
    }
  }

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case AltitudeUnit.meters:
        return 'm';
      case AltitudeUnit.feet:
        return 'ft';
      case AltitudeUnit.flightLevel:
        return 'FL';
    }
  }

  String getMslLabel(AppLocalizations l10n) {
    switch (this) {
      case AltitudeUnit.meters:
        return l10n.altitudeUnitMetersMsl;
      case AltitudeUnit.feet:
        return l10n.altitudeUnitFeetMsl;
      case AltitudeUnit.flightLevel:
        return 'FL';
    }
  }

  String getGndLabel(AppLocalizations l10n) {
    switch (this) {
      case AltitudeUnit.meters:
        return l10n.altitudeUnitMetersGnd;
      case AltitudeUnit.feet:
      case AltitudeUnit.flightLevel:
        return l10n.altitudeUnitFeetGnd;
    }
  }
}
