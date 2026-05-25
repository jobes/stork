import '../../../l10n/app_localizations.dart';

enum SpeedUnit {
  ms,
  kmh,
  mph,
  knots;

  double convertFromMs(double ms) => switch (this) {
        SpeedUnit.ms => ms,
        SpeedUnit.kmh => ms * 3.6,
        SpeedUnit.mph => ms * 2.23694,
        SpeedUnit.knots => ms * 1.94384,
      };

  double convertToMs(double val) => switch (this) {
        SpeedUnit.ms => val,
        SpeedUnit.kmh => val / 3.6,
        SpeedUnit.mph => val / 2.23694,
        SpeedUnit.knots => val / 1.94384,
      };

  String getLabel(AppLocalizations l10n) => switch (this) {
        SpeedUnit.ms => l10n.speedUnitMs,
        SpeedUnit.kmh => l10n.speedUnitKmH,
        SpeedUnit.mph => l10n.speedUnitMph,
        SpeedUnit.knots => l10n.speedUnitKnots,
      };

  String getAbbreviation(AppLocalizations l10n) => switch (this) {
        SpeedUnit.knots => l10n.speedUnitKnotsAbbreviation,
        _ => getLabel(l10n),
      };
}
