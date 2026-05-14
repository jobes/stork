// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapStyle)
final mapStyleProvider = MapStyleProvider._();

final class MapStyleProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  MapStyleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapStyleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapStyleHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return mapStyle(ref);
  }
}

String _$mapStyleHash() => r'665353552a739e9f8071a2b2d74aec47b60a51c5';
