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
    extends
        $FunctionalProvider<
          AsyncValue<PreparedMapStyle>,
          PreparedMapStyle,
          FutureOr<PreparedMapStyle>
        >
    with $FutureModifier<PreparedMapStyle>, $FutureProvider<PreparedMapStyle> {
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
  $FutureProviderElement<PreparedMapStyle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PreparedMapStyle> create(Ref ref) {
    return mapStyle(ref);
  }
}

String _$mapStyleHash() => r'5f310ddd955ade2da0cfc3d960eca17bde47bceb';
