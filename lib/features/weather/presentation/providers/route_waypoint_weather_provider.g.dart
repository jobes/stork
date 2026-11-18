// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_waypoint_weather_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Forecast at each route waypoint, keyed by the waypoint index in the
/// navigation route. Uses the same timing and profile data as the point
/// details so the route list and the dialogs never disagree.

@ProviderFor(routeWaypointWeather)
final routeWaypointWeatherProvider = RouteWaypointWeatherProvider._();

/// Forecast at each route waypoint, keyed by the waypoint index in the
/// navigation route. Uses the same timing and profile data as the point
/// details so the route list and the dialogs never disagree.

final class RouteWaypointWeatherProvider
    extends
        $FunctionalProvider<
          Map<int, RouteWaypointWeather>,
          Map<int, RouteWaypointWeather>,
          Map<int, RouteWaypointWeather>
        >
    with $Provider<Map<int, RouteWaypointWeather>> {
  /// Forecast at each route waypoint, keyed by the waypoint index in the
  /// navigation route. Uses the same timing and profile data as the point
  /// details so the route list and the dialogs never disagree.
  RouteWaypointWeatherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeWaypointWeatherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeWaypointWeatherHash();

  @$internal
  @override
  $ProviderElement<Map<int, RouteWaypointWeather>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<int, RouteWaypointWeather> create(Ref ref) {
    return routeWaypointWeather(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, RouteWaypointWeather> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, RouteWaypointWeather>>(
        value,
      ),
    );
  }
}

String _$routeWaypointWeatherHash() =>
    r'0ac129adc3174e186cc403821f2085dec6b77333';

/// Wind and surface gusts at every forecast point for its estimated arrival
/// time. Uses the same wind-adjusted timing and forecast reference as the
/// route list and the details dialog.

@ProviderFor(routePointWinds)
final routePointWindsProvider = RoutePointWindsProvider._();

/// Wind and surface gusts at every forecast point for its estimated arrival
/// time. Uses the same wind-adjusted timing and forecast reference as the
/// route list and the details dialog.

final class RoutePointWindsProvider
    extends
        $FunctionalProvider<
          Map<String, RoutePointWind>,
          Map<String, RoutePointWind>,
          Map<String, RoutePointWind>
        >
    with $Provider<Map<String, RoutePointWind>> {
  /// Wind and surface gusts at every forecast point for its estimated arrival
  /// time. Uses the same wind-adjusted timing and forecast reference as the
  /// route list and the details dialog.
  RoutePointWindsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routePointWindsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routePointWindsHash();

  @$internal
  @override
  $ProviderElement<Map<String, RoutePointWind>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, RoutePointWind> create(Ref ref) {
    return routePointWinds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, RoutePointWind> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, RoutePointWind>>(value),
    );
  }
}

String _$routePointWindsHash() => r'cf2605f1a4088676fb7d347a356b7903bef73ae2';
