import '../../../../l10n/app_localizations.dart';
import '../../domain/weather_hazard.dart';

/// Localized short labels for weather hazards, used by the route list and the
/// route weather strip so both describe the same condition the same way.
String hazardLabels(
  AppLocalizations l10n,
  Set<WeatherHazard> hazards, {
  String separator = ' · ',
}) => [
  for (final hazard in hazards)
    switch (hazard) {
      WeatherHazard.wind => l10n.weatherDangerousWind,
      WeatherHazard.gust => l10n.weatherDangerousGust,
      WeatherHazard.precipitation => l10n.weatherAlertPrecipitationTitle,
      WeatherHazard.fog => l10n.weatherAlertFogTitle,
      WeatherHazard.freezingPrecipitation => l10n.weatherAlertFreezingTitle,
      WeatherHazard.snow => l10n.weatherAlertSnowTitle,
      WeatherHazard.thunderstorm => l10n.weatherAlertThunderstormTitle,
    },
].join(separator);
