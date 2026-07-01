import '../../../../l10n/app_localizations.dart';

enum PressureUnit {
  bar,
  psi,
  kPa;

  double convertFromKpa(double kpa) => switch (this) {
    PressureUnit.kPa => kpa,
    PressureUnit.bar => kpa / 100.0,
    PressureUnit.psi => kpa * 0.1450377377,
  };

  double convertToKpa(double val) => switch (this) {
    PressureUnit.kPa => val,
    PressureUnit.bar => val * 100.0,
    PressureUnit.psi => val / 0.1450377377,
  };

  String getLabel(AppLocalizations l10n) => switch (this) {
    PressureUnit.kPa => 'kPa',
    PressureUnit.bar => 'bar',
    PressureUnit.psi => 'psi',
  };

  String getAbbreviation() => switch (this) {
    PressureUnit.kPa => 'kPa',
    PressureUnit.bar => 'bar',
    PressureUnit.psi => 'psi',
  };
}
