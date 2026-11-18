import 'flight_forecast.dart';

/// Domain view of a forecast profile. Data implementations provide the
/// parsing and storage, while presentation and calculations depend only on
/// this interface.
abstract interface class ForecastProfile {
  bool covers(DateTime time);

  ForecastWind? windAt(
    DateTime time,
    double altitudeMeters, {
    double? terrainMeters,
  });

  FlightForecast? at(
    DateTime time, {
    double? altitudeMeters,
    double? terrainMeters,
    double? pressureReferenceMeters,
  });
}

/// Terrain and airport reference used to evaluate a forecast point.
typedef ForecastReference = ({double? terrainMeters, double? airportMeters});

extension ForecastProfileReference on ForecastProfile {
  /// Shared forecast lookup so every screen resolves the reference the same
  /// way: terrain wins for the usable profile, while a published airport
  /// elevation wins for pressure reduction.
  FlightForecast? atReference(
    DateTime time, {
    double? altitudeFeet,
    ForecastReference? reference,
  }) => at(
    time,
    altitudeMeters: altitudeFeet == null ? null : altitudeFeet * feetInMeters,
    terrainMeters: reference?.terrainMeters ?? reference?.airportMeters,
    pressureReferenceMeters:
        reference?.airportMeters ?? reference?.terrainMeters,
  );
}

typedef ForecastProfiles = ({
  Map<String, ForecastProfile> series,
  bool refreshFailed,
});
