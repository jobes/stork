// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_weather_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlightDeparture)
final flightDepartureProvider = FlightDepartureProvider._();

final class FlightDepartureProvider
    extends $NotifierProvider<FlightDeparture, DateTime?> {
  FlightDepartureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightDepartureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightDepartureHash();

  @$internal
  @override
  FlightDeparture create() => FlightDeparture();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$flightDepartureHash() => r'9f507dcaf78ea8e742fee1b9b9ddf5d38a583302';

abstract class _$FlightDeparture extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(flightWeatherClock)
final flightWeatherClockProvider = FlightWeatherClockProvider._();

final class FlightWeatherClockProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  FlightWeatherClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightWeatherClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightWeatherClockHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return flightWeatherClock(ref);
  }
}

String _$flightWeatherClockHash() =>
    r'b9a4a783b71d2f7e90421354ea08d9a4704dbba8';

@ProviderFor(FlightWeatherPlan)
final flightWeatherPlanProvider = FlightWeatherPlanProvider._();

final class FlightWeatherPlanProvider
    extends $NotifierProvider<FlightWeatherPlan, List<ForecastRoutePoint>> {
  FlightWeatherPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightWeatherPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightWeatherPlanHash();

  @$internal
  @override
  FlightWeatherPlan create() => FlightWeatherPlan();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ForecastRoutePoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ForecastRoutePoint>>(value),
    );
  }
}

String _$flightWeatherPlanHash() => r'9bf0ca385817710fd06c762c078213792e574543';

abstract class _$FlightWeatherPlan extends $Notifier<List<ForecastRoutePoint>> {
  List<ForecastRoutePoint> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<ForecastRoutePoint>, List<ForecastRoutePoint>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ForecastRoutePoint>, List<ForecastRoutePoint>>,
              List<ForecastRoutePoint>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FlightWeatherQuery)
final flightWeatherQueryProvider = FlightWeatherQueryProvider._();

final class FlightWeatherQueryProvider
    extends $NotifierProvider<FlightWeatherQuery, ForecastQuery?> {
  FlightWeatherQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightWeatherQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightWeatherQueryHash();

  @$internal
  @override
  FlightWeatherQuery create() => FlightWeatherQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForecastQuery? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForecastQuery?>(value),
    );
  }
}

String _$flightWeatherQueryHash() =>
    r'bc0af947d93bd9bc9d1b662ea1bdb7f89521e24e';

abstract class _$FlightWeatherQuery extends $Notifier<ForecastQuery?> {
  ForecastQuery? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ForecastQuery?, ForecastQuery?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForecastQuery?, ForecastQuery?>,
              ForecastQuery?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(flightForecastRefresh)
final flightForecastRefreshProvider = FlightForecastRefreshProvider._();

final class FlightForecastRefreshProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  FlightForecastRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightForecastRefreshProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightForecastRefreshHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return flightForecastRefresh(ref);
  }
}

String _$flightForecastRefreshHash() =>
    r'2b2ded5a808f2ff3c0ccf52f71b55deb8df4e160';

@ProviderFor(flightForecastProfiles)
final flightForecastProfilesProvider = FlightForecastProfilesProvider._();

final class FlightForecastProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForecastProfiles?>,
          ForecastProfiles?,
          FutureOr<ForecastProfiles?>
        >
    with
        $FutureModifier<ForecastProfiles?>,
        $FutureProvider<ForecastProfiles?> {
  FlightForecastProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightForecastProfilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightForecastProfilesHash();

  @$internal
  @override
  $FutureProviderElement<ForecastProfiles?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForecastProfiles?> create(Ref ref) {
    return flightForecastProfiles(ref);
  }
}

String _$flightForecastProfilesHash() =>
    r'd6755a910546b8201bd023e811d651357787a4c5';

@ProviderFor(forecastPointTerrain)
final forecastPointTerrainProvider = ForecastPointTerrainFamily._();

final class ForecastPointTerrainProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  ForecastPointTerrainProvider._({
    required ForecastPointTerrainFamily super.from,
    required ForecastLocation super.argument,
  }) : super(
         retry: null,
         name: r'forecastPointTerrainProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forecastPointTerrainHash();

  @override
  String toString() {
    return r'forecastPointTerrainProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    final argument = this.argument as ForecastLocation;
    return forecastPointTerrain(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ForecastPointTerrainProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forecastPointTerrainHash() =>
    r'7b0558478ea5bc076da97e6f43f91bd9a4936658';

final class ForecastPointTerrainFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double?>, ForecastLocation> {
  ForecastPointTerrainFamily._()
    : super(
        retry: null,
        name: r'forecastPointTerrainProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ForecastPointTerrainProvider call(ForecastLocation location) =>
      ForecastPointTerrainProvider._(argument: location, from: this);

  @override
  String toString() => r'forecastPointTerrainProvider';
}

@ProviderFor(nearbyFlightForecast)
final nearbyFlightForecastProvider = NearbyFlightForecastProvider._();

final class NearbyFlightForecastProvider
    extends
        $FunctionalProvider<FlightForecast?, FlightForecast?, FlightForecast?>
    with $Provider<FlightForecast?> {
  NearbyFlightForecastProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyFlightForecastProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyFlightForecastHash();

  @$internal
  @override
  $ProviderElement<FlightForecast?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FlightForecast? create(Ref ref) {
    return nearbyFlightForecast(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlightForecast? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlightForecast?>(value),
    );
  }
}

String _$nearbyFlightForecastHash() =>
    r'dc14dc3fd7b8e570521ffd097744e9e32962eaed';
