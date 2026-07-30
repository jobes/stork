// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gdl90_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gdl90Service)
final gdl90ServiceProvider = Gdl90ServiceProvider._();

final class Gdl90ServiceProvider
    extends $FunctionalProvider<Gdl90Service, Gdl90Service, Gdl90Service>
    with $Provider<Gdl90Service> {
  Gdl90ServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gdl90ServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gdl90ServiceHash();

  @$internal
  @override
  $ProviderElement<Gdl90Service> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Gdl90Service create(Ref ref) {
    return gdl90Service(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Gdl90Service value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Gdl90Service>(value),
    );
  }
}

String _$gdl90ServiceHash() => r'6ab222a2a6bc66f87423b22dbbbe16563b58535e';
