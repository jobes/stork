// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_eta_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Navigation-facing arrival estimates. The wind-adjusted timing comes from
/// the weather feature, so this aggregate stays in the navigation UI and adds
/// nothing when the forecast is disabled or unavailable.

@ProviderFor(navigationEta)
final navigationEtaProvider = NavigationEtaProvider._();

/// Navigation-facing arrival estimates. The wind-adjusted timing comes from
/// the weather feature, so this aggregate stays in the navigation UI and adds
/// nothing when the forecast is disabled or unavailable.

final class NavigationEtaProvider
    extends
        $FunctionalProvider<
          NavigationCalculations,
          NavigationCalculations,
          NavigationCalculations
        >
    with $Provider<NavigationCalculations> {
  /// Navigation-facing arrival estimates. The wind-adjusted timing comes from
  /// the weather feature, so this aggregate stays in the navigation UI and adds
  /// nothing when the forecast is disabled or unavailable.
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
