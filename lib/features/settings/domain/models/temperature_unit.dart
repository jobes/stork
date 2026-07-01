import '../../../../l10n/app_localizations.dart';

enum TemperatureUnit {
  celsius,
  kelvin,
  fahrenheit;

  double convertFromKelvin(double kelvin) => switch (this) {
    TemperatureUnit.kelvin => kelvin,
    TemperatureUnit.celsius => kelvin - 273.15,
    TemperatureUnit.fahrenheit => (kelvin - 273.15) * 9 / 5 + 32,
  };

  double convertToKelvin(double val) => switch (this) {
    TemperatureUnit.kelvin => val,
    TemperatureUnit.celsius => val + 273.15,
    TemperatureUnit.fahrenheit => (val - 32) * 5 / 9 + 273.15,
  };

  String getLabel(AppLocalizations l10n) => switch (this) {
    TemperatureUnit.celsius => l10n.tempUnitCelsius,
    TemperatureUnit.kelvin => l10n.tempUnitKelvin,
    TemperatureUnit.fahrenheit => l10n.tempUnitFahrenheit,
  };

  String getAbbreviation() => switch (this) {
    TemperatureUnit.celsius => '°C',
    TemperatureUnit.kelvin => 'K',
    TemperatureUnit.fahrenheit => '°F',
  };
}
