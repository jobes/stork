// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_eta_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NavigationGroundTrack)
final navigationGroundTrackProvider = NavigationGroundTrackProvider._();

final class NavigationGroundTrackProvider
    extends $NotifierProvider<NavigationGroundTrack, GroundTrack?> {
  NavigationGroundTrackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationGroundTrackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationGroundTrackHash();

  @$internal
  @override
  NavigationGroundTrack create() => NavigationGroundTrack();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroundTrack? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroundTrack?>(value),
    );
  }
}

String _$navigationGroundTrackHash() =>
    r'544a57a2bad4138966d6b608f4471d3c30ed3066';

abstract class _$NavigationGroundTrack extends $Notifier<GroundTrack?> {
  GroundTrack? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GroundTrack?, GroundTrack?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GroundTrack?, GroundTrack?>,
              GroundTrack?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(_windTimingKey)
final _windTimingKeyProvider = _WindTimingKeyProvider._();

final class _WindTimingKeyProvider
    extends $FunctionalProvider<WindTimingKey, WindTimingKey, WindTimingKey>
    with $Provider<WindTimingKey> {
  _WindTimingKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_windTimingKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_windTimingKeyHash();

  @$internal
  @override
  $ProviderElement<WindTimingKey> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WindTimingKey create(Ref ref) {
    return _windTimingKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindTimingKey value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindTimingKey>(value),
    );
  }
}

String _$_windTimingKeyHash() => r'ad19b8bbaf4a0a5510ba6a308fd29b4f9ed33191';

@ProviderFor(RouteWindTiming)
final routeWindTimingProvider = RouteWindTimingProvider._();

final class RouteWindTimingProvider
    extends $AsyncNotifierProvider<RouteWindTiming, WindTimingResult?> {
  RouteWindTimingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeWindTimingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeWindTimingHash();

  @$internal
  @override
  RouteWindTiming create() => RouteWindTiming();
}

String _$routeWindTimingHash() => r'38f2f20683a1da8e456eec5cd1693dfa67b523db';

abstract class _$RouteWindTiming extends $AsyncNotifier<WindTimingResult?> {
  FutureOr<WindTimingResult?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WindTimingResult?>, WindTimingResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WindTimingResult?>, WindTimingResult?>,
              AsyncValue<WindTimingResult?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(routePointTiming)
final routePointTimingProvider = RoutePointTimingProvider._();

final class RoutePointTimingProvider
    extends
        $FunctionalProvider<
          Map<String, TimedRoutePoint>,
          Map<String, TimedRoutePoint>,
          Map<String, TimedRoutePoint>
        >
    with $Provider<Map<String, TimedRoutePoint>> {
  RoutePointTimingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routePointTimingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routePointTimingHash();

  @$internal
  @override
  $ProviderElement<Map<String, TimedRoutePoint>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, TimedRoutePoint> create(Ref ref) {
    return routePointTiming(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, TimedRoutePoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, TimedRoutePoint>>(value),
    );
  }
}

String _$routePointTimingHash() => r'a7edf0c0464b4c1d235baf2854d1de9cb186466f';

@ProviderFor(navigationEta)
final navigationEtaProvider = NavigationEtaProvider._();

final class NavigationEtaProvider
    extends
        $FunctionalProvider<
          NavigationCalculations,
          NavigationCalculations,
          NavigationCalculations
        >
    with $Provider<NavigationCalculations> {
  NavigationEtaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationEtaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationEtaHash();

  @$internal
  @override
  $ProviderElement<NavigationCalculations> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NavigationCalculations create(Ref ref) {
    return navigationEta(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationCalculations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationCalculations>(value),
    );
  }
}

String _$navigationEtaHash() => r'6250fb55df8b1c7969e07f3e0edda2f7f11e140e';
