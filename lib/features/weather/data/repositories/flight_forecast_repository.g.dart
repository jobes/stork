// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_forecast_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flightForecastRepository)
final flightForecastRepositoryProvider = FlightForecastRepositoryProvider._();

final class FlightForecastRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FlightForecastRepository>,
          FlightForecastRepository,
          FutureOr<FlightForecastRepository>
        >
    with
        $FutureModifier<FlightForecastRepository>,
        $FutureProvider<FlightForecastRepository> {
  FlightForecastRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightForecastRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightForecastRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<FlightForecastRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FlightForecastRepository> create(Ref ref) {
    return flightForecastRepository(ref);
  }
}

String _$flightForecastRepositoryHash() =>
    r'177d37f2087a1331a76b500701bc2954fdec5f5a';
