import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/weather_hazard.dart';

FlightForecast forecast({
  int? code,
  double? rain,
  double? wind,
  double? gust,
}) => FlightForecast(
  wind: wind == null ? null : ForecastWind(0, wind),
  temperatureC: null,
  gustMs: gust,
  precipitationMm: rain,
  lowCloudPercent: null,
  qnhHpa: null,
  qfeHpa: null,
  intervalEnd: null,
  downloadedAt: DateTime.utc(2026),
  weatherCode: code,
);

void main() {
  test('wind and gust limits are independent and must be exceeded', () {
    final value = forecast(wind: 10, gust: 15);
    expect(forecastHazards(value), isEmpty);
    expect(forecastHazards(value, windLimitMs: 10, gustLimitMs: 15), isEmpty);
    expect(forecastHazards(value, windLimitMs: 9), {WeatherHazard.wind});
    expect(forecastHazards(value, gustLimitMs: 14), {WeatherHazard.gust});
    expect(forecastHazards(value, windLimitMs: 9, gustLimitMs: 14), {
      WeatherHazard.wind,
      WeatherHazard.gust,
    });
  });
  test('warns about precipitation even when the weather code is missing', () {
    expect(forecastHazards(forecast(rain: 0.1)), {WeatherHazard.precipitation});
    expect(forecastHazards(forecast(code: 61)), {WeatherHazard.precipitation});
    expect(forecastHazards(forecast(code: 3, rain: 0)), isEmpty);
  });
  test('identifies fog, freezing rain, snow and thunderstorms', () {
    expect(forecastHazards(forecast(code: 45)), {WeatherHazard.fog});
    expect(forecastHazards(forecast(code: 48)), {WeatherHazard.fog});
    expect(forecastHazards(forecast(code: 66)), {
      WeatherHazard.precipitation,
      WeatherHazard.freezingPrecipitation,
    });
    expect(forecastHazards(forecast(code: 75)), {WeatherHazard.snow});
    expect(forecastHazards(forecast(code: 99)), {WeatherHazard.thunderstorm});
  });
}
