import '../../map/domain/airport_metadata.dart';
import '../../map/domain/models/reference_datum.dart';
import 'flight_forecast.dart';

/// Airport elevation in meters, used as the terrain/pressure reference for a
/// forecast point. Returns null when the elevation is missing or not MSL.
double? airportElevationMeters(AirportMetadata? airport) {
  final elevation = airport?.elevation;
  final datum = ReferenceDatum.fromInt(elevation?.referenceDatum ?? -1);
  return switch (datum == ReferenceDatum.msl ? elevation?.unit : null) {
    OpenAipUnit.meters => elevation!.value,
    OpenAipUnit.feet => elevation!.value * feetInMeters,
    _ => null,
  };
}
