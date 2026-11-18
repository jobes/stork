// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_hazard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(weatherHazardDetails)
final weatherHazardDetailsProvider = WeatherHazardDetailsProvider._();

final class WeatherHazardDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeatherHazardDetail>>,
          List<WeatherHazardDetail>,
          FutureOr<List<WeatherHazardDetail>>
        >
    with
        $FutureModifier<List<WeatherHazardDetail>>,
        $FutureProvider<List<WeatherHazardDetail>> {
  WeatherHazardDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weatherHazardDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weatherHazardDetailsHash();

  @$internal
  @override
  $FutureProviderElement<List<WeatherHazardDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WeatherHazardDetail>> create(Ref ref) {
    return weatherHazardDetails(ref);
  }
}

String _$weatherHazardDetailsHash() =>
    r'625c6d7503b1f67edf6fc64cd1cbe96d0d8defb4';

@ProviderFor(activeWeatherHazardDetails)
final activeWeatherHazardDetailsProvider =
    ActiveWeatherHazardDetailsProvider._();

final class ActiveWeatherHazardDetailsProvider
    extends
        $FunctionalProvider<
          List<WeatherHazardDetail>,
          List<WeatherHazardDetail>,
          List<WeatherHazardDetail>
        >
    with $Provider<List<WeatherHazardDetail>> {
  ActiveWeatherHazardDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWeatherHazardDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWeatherHazardDetailsHash();

  @$internal
  @override
  $ProviderElement<List<WeatherHazardDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<WeatherHazardDetail> create(Ref ref) {
    return activeWeatherHazardDetails(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WeatherHazardDetail> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WeatherHazardDetail>>(value),
    );
  }
}

String _$activeWeatherHazardDetailsHash() =>
    r'901f484179bc6e386e77d1bf8dec3ceb84cbdc87';

/// Hazards currently reported by the active plan, already filtered by the
/// flight forecast setting.

@ProviderFor(activeWeatherHazards)
final activeWeatherHazardsProvider = ActiveWeatherHazardsProvider._();

/// Hazards currently reported by the active plan, already filtered by the
/// flight forecast setting.

final class ActiveWeatherHazardsProvider
    extends
        $FunctionalProvider<
          Set<WeatherHazard>,
          Set<WeatherHazard>,
          Set<WeatherHazard>
        >
    with $Provider<Set<WeatherHazard>> {
  /// Hazards currently reported by the active plan, already filtered by the
  /// flight forecast setting.
  ActiveWeatherHazardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWeatherHazardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWeatherHazardsHash();

  @$internal
  @override
  $ProviderElement<Set<WeatherHazard>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Set<WeatherHazard> create(Ref ref) {
    return activeWeatherHazards(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<WeatherHazard> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<WeatherHazard>>(value),
    );
  }
}

String _$activeWeatherHazardsHash() =>
    r'9efd16486baf367bc67d63a87ddf59bd60be852e';
