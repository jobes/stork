import '../../../l10n/app_localizations.dart';

enum SpeedUnit {
  ms,
  kmh,
  mph,
  knots;

  double convertFromMs(double ms) {
    switch (this) {
      case SpeedUnit.ms:
        return ms;
      case SpeedUnit.kmh:
        return ms * 3.6;
      case SpeedUnit.mph:
        return ms * 2.23694;
      case SpeedUnit.knots:
        return ms * 1.94384;
    }
  }

  double convertToMs(double val) {
    switch (this) {
      case SpeedUnit.ms:
        return val;
      case SpeedUnit.kmh:
        return val / 3.6;
      case SpeedUnit.mph:
        return val / 2.23694;
      case SpeedUnit.knots:
        return val / 1.94384;
    }
  }

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case SpeedUnit.ms:
        return l10n.speedUnitMs;
      case SpeedUnit.kmh:
        return l10n.speedUnitKmH;
      case SpeedUnit.mph:
        return l10n.speedUnitMph;
      case SpeedUnit.knots:
        return l10n.speedUnitKnots;
    }
  }

  String getAbbreviation(AppLocalizations l10n) {
    if (this == SpeedUnit.knots) {
      return l10n.speedUnitKnotsAbbreviation;
    }
    return getLabel(l10n);
  }
}
