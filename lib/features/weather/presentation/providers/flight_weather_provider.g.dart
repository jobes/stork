// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_weather_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlightDepartureNotifier)
final flightDepartureProvider = FlightDepartureNotifierProvider._();

final class FlightDepartureNotifierProvider
    extends $NotifierProvider<FlightDepartureNotifier, DateTime?> {
  FlightDepartureNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$flightDepartureNotifierHash();

  @$internal
  @override
  FlightDepartureNotifier create() => FlightDepartureNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$flightDepartureNotifierHash() =>
    r'77a2697088e83ef45464d342842f8712e67ab02a';

abstract class _$FlightDepartureNotifier extends $Notifier<DateTime?> {
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

@ProviderFor(FlightWeatherPlanNotifier)
final flightWeatherPlanProvider = FlightWeatherPlanNotifierProvider._();

final class FlightWeatherPlanNotifierProvider
    extends
        $NotifierProvider<FlightWeatherPlanNotifier, List<ForecastRoutePoint>> {
  FlightWeatherPlanNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$flightWeatherPlanNotifierHash();

  @$internal
  @override
  FlightWeatherPlanNotifier create() => FlightWeatherPlanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ForecastRoutePoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ForecastRoutePoint>>(value),
    );
  }
}

String _$flightWeatherPlanNotifierHash() =>
    r'5801f226d1a8d447ee9989df4b20e4cf29bbd9e3';

abstract class _$FlightWeatherPlanNotifier
    extends $Notifier<List<ForecastRoutePoint>> {
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

/// Latches the profile location for the moving aircraft. Small movements reuse
/// the previous profile instead of requesting a new one every grid cell.

@ProviderFor(FlightWeatherOrigin)
final flightWeatherOriginProvider = FlightWeatherOriginProvider._();

/// Latches the profile location for the moving aircraft. Small movements reuse
/// the previous profile instead of requesting a new one every grid cell.
final class FlightWeatherOriginProvider
    extends $NotifierProvider<FlightWeatherOrigin, ForecastLocation?> {
  /// Latches the profile location for the moving aircraft. Small movements reuse
  /// the previous profile instead of requesting a new one every grid cell.
  FlightWeatherOriginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightWeatherOriginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightWeatherOriginHash();

  @$internal
  @override
  FlightWeatherOrigin create() => FlightWeatherOrigin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForecastLocation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForecastLocation?>(value),
    );
  }
}

String _$flightWeatherOriginHash() =>
    r'37bf28fec3b06abb464ea24da9f36457a9cb2156';

/// Latches the profile location for the moving aircraft. Small movements reuse
/// the previous profile instead of requesting a new one every grid cell.

abstract class _$FlightWeatherOrigin extends $Notifier<ForecastLocation?> {
  ForecastLocation? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ForecastLocation?, ForecastLocation?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForecastLocation?, ForecastLocation?>,
              ForecastLocation?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Profile lookup location for every plan point. The aircraft uses the latched
/// location so lookups keep working while the previous profile is reused.

@ProviderFor(flightWeatherProfileLocations)
final flightWeatherProfileLocationsProvider =
    FlightWeatherProfileLocationsProvider._();

/// Profile lookup location for every plan point. The aircraft uses the latched
/// location so lookups keep working while the previous profile is reused.

final class FlightWeatherProfileLocationsProvider
    extends
        $FunctionalProvider<
          Map<String, ForecastLocation>,
          Map<String, ForecastLocation>,
          Map<String, ForecastLocation>
        >
    with $Provider<Map<String, ForecastLocation>> {
  /// Profile lookup location for every plan point. The aircraft uses the latched
  /// location so lookups keep working while the previous profile is reused.
  FlightWeatherProfileLocationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightWeatherProfileLocationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightWeatherProfileLocationsHash();

  @$internal
  @override
  $ProviderElement<Map<String, ForecastLocation>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, ForecastLocation> create(Ref ref) {
    return flightWeatherProfileLocations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ForecastLocation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ForecastLocation>>(
        value,
      ),
    );
  }
}

String _$flightWeatherProfileLocationsHash() =>
    r'9f71a35dcdba935ab0d2bc0134c74b77fb570391';

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
    r'd0a7065c9a08c1a956fd761c909d8b2bf4b8f400';

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

/// Manual refresh requested from the map alert. Profiles only live in memory,
/// so the action re-requests every location of the current plan.

@ProviderFor(FlightForecastSyncNotifier)
final flightForecastSyncProvider = FlightForecastSyncNotifierProvider._();

/// Manual refresh requested from the map alert. Profiles only live in memory,
/// so the action re-requests every location of the current plan.
final class FlightForecastSyncNotifierProvider
    extends $NotifierProvider<FlightForecastSyncNotifier, void> {
  /// Manual refresh requested from the map alert. Profiles only live in memory,
  /// so the action re-requests every location of the current plan.
  FlightForecastSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightForecastSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightForecastSyncNotifierHash();

  @$internal
  @override
  FlightForecastSyncNotifier create() => FlightForecastSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$flightForecastSyncNotifierHash() =>
    r'05b2ee028924771cb679cd9d5f43f31feaeb6cdc';

/// Manual refresh requested from the map alert. Profiles only live in memory,
/// so the action re-requests every location of the current plan.

abstract class _$FlightForecastSyncNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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
    r'bcf739119331cb61835868d4e18c9caf93ca6b78';

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

/// Terrain and airport reference for one forecast point. Resolving it per
/// point keeps the route list, map markers, navigation details and hazard
/// evaluation on the same terrain and pressure reference.

@ProviderFor(routeForecastReference)
final routeForecastReferenceProvider = RouteForecastReferenceFamily._();

/// Terrain and airport reference for one forecast point. Resolving it per
/// point keeps the route list, map markers, navigation details and hazard
/// evaluation on the same terrain and pressure reference.

final class RouteForecastReferenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForecastReference>,
          ForecastReference,
          FutureOr<ForecastReference>
        >
    with
        $FutureModifier<ForecastReference>,
        $FutureProvider<ForecastReference> {
  /// Terrain and airport reference for one forecast point. Resolving it per
  /// point keeps the route list, map markers, navigation details and hazard
  /// evaluation on the same terrain and pressure reference.
  RouteForecastReferenceProvider._({
    required RouteForecastReferenceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'routeForecastReferenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routeForecastReferenceHash();

  @override
  String toString() {
    return r'routeForecastReferenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ForecastReference> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForecastReference> create(Ref ref) {
    final argument = this.argument as String;
    return routeForecastReference(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RouteForecastReferenceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routeForecastReferenceHash() =>
    r'bcb4956bfb381524a304000c25a590a7b79d3fb2';

/// Terrain and airport reference for one forecast point. Resolving it per
/// point keeps the route list, map markers, navigation details and hazard
/// evaluation on the same terrain and pressure reference.

final class RouteForecastReferenceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ForecastReference>, String> {
  RouteForecastReferenceFamily._()
    : super(
        retry: null,
        name: r'routeForecastReferenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Terrain and airport reference for one forecast point. Resolving it per
  /// point keeps the route list, map markers, navigation details and hazard
  /// evaluation on the same terrain and pressure reference.

  RouteForecastReferenceProvider call(String pointId) =>
      RouteForecastReferenceProvider._(argument: pointId, from: this);

  @override
  String toString() => r'routeForecastReferenceProvider';
}

/// References for every plan point, resolved through
/// [routeForecastReferenceProvider].

@ProviderFor(routeForecastReferences)
final routeForecastReferencesProvider = RouteForecastReferencesProvider._();

/// References for every plan point, resolved through
/// [routeForecastReferenceProvider].

final class RouteForecastReferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ForecastReference>>,
          Map<String, ForecastReference>,
          FutureOr<Map<String, ForecastReference>>
        >
    with
        $FutureModifier<Map<String, ForecastReference>>,
        $FutureProvider<Map<String, ForecastReference>> {
  /// References for every plan point, resolved through
  /// [routeForecastReferenceProvider].
  RouteForecastReferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeForecastReferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeForecastReferencesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, ForecastReference>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, ForecastReference>> create(Ref ref) {
    return routeForecastReferences(ref);
  }
}

String _$routeForecastReferencesHash() =>
    r'5c6e899950ad5eb6485e1895160236990b7b1c87';
