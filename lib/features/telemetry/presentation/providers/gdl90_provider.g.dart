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

String _$gdl90ServiceHash() => r'b709d70f3d4b4aaa4eee803a25b7e3fa9ead1c3c';

@ProviderFor(gdl90HeartbeatActive)
final gdl90HeartbeatActiveProvider = Gdl90HeartbeatActiveProvider._();

final class Gdl90HeartbeatActiveProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  Gdl90HeartbeatActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gdl90HeartbeatActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gdl90HeartbeatActiveHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return gdl90HeartbeatActive(ref);
  }
}

String _$gdl90HeartbeatActiveHash() =>
    r'd39e4ec2dcc2a1f2358c6c5955a05c16d73565cb';
