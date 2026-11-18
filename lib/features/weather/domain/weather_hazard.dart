import 'flight_forecast.dart';

enum WeatherHazard {
  wind,
  gust,
  precipitation,
  fog,
  freezingPrecipitation,
  snow,
  thunderstorm,
}

Set<WeatherHazard> forecastHazards(
  FlightForecast forecast, {
  double? windLimitMs,
  double? gustLimitMs,
}) {
  final code = forecast.weatherCode;
  return {
    if (windLimitMs != null &&
        forecast.wind != null &&
        forecast.wind!.speedMs > windLimitMs)
      WeatherHazard.wind,
    if (gustLimitMs != null &&
        forecast.gustMs != null &&
        forecast.gustMs! > gustLimitMs)
      WeatherHazard.gust,
    if ((forecast.precipitationMm ?? 0) > 0 ||
        (code != null &&
            (code >= 51 && code <= 67 || code >= 80 && code <= 82)))
      WeatherHazard.precipitation,
    if (code == 45 || code == 48) WeatherHazard.fog,
    if (code == 56 || code == 57 || code == 66 || code == 67)
      WeatherHazard.freezingPrecipitation,
    if (code != null && (code >= 71 && code <= 77 || code == 85 || code == 86))
      WeatherHazard.snow,
    if (code != null && code >= 95 && code <= 99) WeatherHazard.thunderstorm,
  };
}
