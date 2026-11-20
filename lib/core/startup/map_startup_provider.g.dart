// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_startup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A bounded, attempt-scoped gate. A late callback can never unlock a retry.

@ProviderFor(MapStartup)
final mapStartupProvider = MapStartupProvider._();

/// A bounded, attempt-scoped gate. A late callback can never unlock a retry.
final class MapStartupProvider
    extends $NotifierProvider<MapStartup, MapStartupState> {
  /// A bounded, attempt-scoped gate. A late callback can never unlock a retry.
  MapStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapStartupHash();

  @$internal
  @override
  MapStartup create() => MapStartup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapStartupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapStartupState>(value),
    );
  }
}

String _$mapStartupHash() => r'cde6f1d485051ef8a315ed91412806651de4238d';

/// A bounded, attempt-scoped gate. A late callback can never unlock a retry.

abstract class _$MapStartup extends $Notifier<MapStartupState> {
  MapStartupState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MapStartupState, MapStartupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapStartupState, MapStartupState>,
              MapStartupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
