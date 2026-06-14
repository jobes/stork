// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airport_metadata_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AirportMetadataCache)
final airportMetadataCacheProvider = AirportMetadataCacheProvider._();

final class AirportMetadataCacheProvider
    extends $NotifierProvider<AirportMetadataCache, void> {
  AirportMetadataCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'airportMetadataCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$airportMetadataCacheHash();

  @$internal
  @override
  AirportMetadataCache create() => AirportMetadataCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$airportMetadataCacheHash() =>
    r'1e40dec22f72861c05494c0309c9ea9688df5b34';

abstract class _$AirportMetadataCache extends $Notifier<void> {
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

@ProviderFor(airportMetadata)
final airportMetadataProvider = AirportMetadataFamily._();

final class AirportMetadataProvider
    extends
        $FunctionalProvider<
          AsyncValue<AirportMetadata?>,
          AirportMetadata?,
          FutureOr<AirportMetadata?>
        >
    with $FutureModifier<AirportMetadata?>, $FutureProvider<AirportMetadata?> {
  AirportMetadataProvider._({
    required AirportMetadataFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'airportMetadataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$airportMetadataHash();

  @override
  String toString() {
    return r'airportMetadataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<AirportMetadata?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AirportMetadata?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return airportMetadata(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is AirportMetadataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$airportMetadataHash() => r'af7adf5f5472aa9113f11bc6bea6e69978d3633c';

final class AirportMetadataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AirportMetadata?>,
          (String, String)
        > {
  AirportMetadataFamily._()
    : super(
        retry: null,
        name: r'airportMetadataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AirportMetadataProvider call(String airportId, String countryCode) =>
      AirportMetadataProvider._(argument: (airportId, countryCode), from: this);

  @override
  String toString() => r'airportMetadataProvider';
}

@ProviderFor(openAipApiKey)
final openAipApiKeyProvider = OpenAipApiKeyProvider._();

final class OpenAipApiKeyProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  OpenAipApiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openAipApiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openAipApiKeyHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return openAipApiKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$openAipApiKeyHash() => r'51cc996c0ca99c5a773645a0c7655b185de3be2c';
