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
          FlightForecastRepository,
          FlightForecastRepository,
          FlightForecastRepository
        >
    with $Provider<FlightForecastRepository> {
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
  $ProviderElement<FlightForecastRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlightForecastRepository create(Ref ref) {
    return flightForecastRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlightForecastRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlightForecastRepository>(value),
    );
  }
}

String _$flightForecastRepositoryHash() =>
    r'92a92bed529a7d80aad674536f72d65fcfdd4734';
