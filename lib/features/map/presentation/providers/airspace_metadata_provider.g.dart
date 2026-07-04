// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airspace_metadata_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AirspaceMetadataCache)
final airspaceMetadataCacheProvider = AirspaceMetadataCacheProvider._();

final class AirspaceMetadataCacheProvider
    extends $NotifierProvider<AirspaceMetadataCache, void> {
  AirspaceMetadataCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'airspaceMetadataCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$airspaceMetadataCacheHash();

  @$internal
  @override
  AirspaceMetadataCache create() => AirspaceMetadataCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$airspaceMetadataCacheHash() =>
    r'56df30ef1e46a0fbaa24e3451c64bd2409d137be';

abstract class _$AirspaceMetadataCache extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(airspaceMetadata)
final airspaceMetadataProvider = AirspaceMetadataFamily._();

final class AirspaceMetadataProvider
    extends
        $FunctionalProvider<
          AsyncValue<AirspaceMetadata?>,
          AirspaceMetadata?,
          FutureOr<AirspaceMetadata?>
        >
    with
        $FutureModifier<AirspaceMetadata?>,
        $FutureProvider<AirspaceMetadata?> {
  AirspaceMetadataProvider._({
    required AirspaceMetadataFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'airspaceMetadataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$airspaceMetadataHash();

  @override
  String toString() {
    return r'airspaceMetadataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<AirspaceMetadata?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AirspaceMetadata?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return airspaceMetadata(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is AirspaceMetadataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$airspaceMetadataHash() => r'54e57e979491334120398c87bd95981c975796f7';

final class AirspaceMetadataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AirspaceMetadata?>,
          (String, String)
        > {
  AirspaceMetadataFamily._()
    : super(
        retry: null,
        name: r'airspaceMetadataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AirspaceMetadataProvider call(String airspaceId, String countryCode) =>
      AirspaceMetadataProvider._(
        argument: (airspaceId, countryCode),
        from: this,
      );

  @override
  String toString() => r'airspaceMetadataProvider';
}
