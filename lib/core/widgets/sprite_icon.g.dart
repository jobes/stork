// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sprite_icon.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the shared [SpriteCache] used by [SpriteIcon]. The cache is created
/// once and lives for the lifetime of the app, so cropped frames are reused.

@ProviderFor(spriteCache)
final spriteCacheProvider = SpriteCacheProvider._();

/// Provides the shared [SpriteCache] used by [SpriteIcon]. The cache is created
/// once and lives for the lifetime of the app, so cropped frames are reused.

final class SpriteCacheProvider
    extends $FunctionalProvider<SpriteCache, SpriteCache, SpriteCache>
    with $Provider<SpriteCache> {
  /// Provides the shared [SpriteCache] used by [SpriteIcon]. The cache is created
  /// once and lives for the lifetime of the app, so cropped frames are reused.
  SpriteCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spriteCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spriteCacheHash();

  @$internal
  @override
  $ProviderElement<SpriteCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpriteCache create(Ref ref) {
    return spriteCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpriteCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpriteCache>(value),
    );
  }
}

String _$spriteCacheHash() => r'6ef03d88773e86aaeb7f288eaa004f994c3b75f0';
